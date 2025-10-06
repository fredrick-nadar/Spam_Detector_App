import { GoogleGenerativeAI } from '@google/generative-ai';
import { ClassificationResult, SPAM_KEYWORDS } from '../types';
import { preprocessText, calculateKeywordSpamScore, truncateText } from '../utils/textPreprocessing';
import { sleep } from '../utils/helpers';

class ClassificationService {
  private genAI: GoogleGenerativeAI | null = null;
  private model: any = null;
  private apiKey: string | null = null;
  private rateLimitMs: number = 2000; // 2 seconds between calls
  private lastCallTime: number = 0;

  initialize(apiKey: string, rateLimitMs: number = 2000): void {
    if (!apiKey) {
      throw new Error('Gemini API key is required');
    }

    this.apiKey = apiKey;
    this.rateLimitMs = rateLimitMs;
    this.genAI = new GoogleGenerativeAI(apiKey);
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    console.log('Classification service initialized');
  }

  isInitialized(): boolean {
    return this.genAI !== null && this.model !== null;
  }

  /**
   * Classifies SMS message using Gemini AI
   * Falls back to keyword-based detection on error
   */
  async classifyMessage(text: string): Promise<ClassificationResult> {
    // Try AI classification first
    if (this.isInitialized()) {
      try {
        return await this.classifyWithAI(text);
      } catch (error) {
        console.warn('AI classification failed, falling back to keyword detection:', error);
      }
    }

    // Fallback to keyword-based detection
    return this.classifyWithKeywords(text);
  }

  /**
   * Classifies message using Gemini AI
   */
  private async classifyWithAI(text: string): Promise<ClassificationResult> {
    if (!this.model) {
      throw new Error('Classification service not initialized');
    }

    // Rate limiting
    await this.waitForRateLimit();

    // Preprocess and truncate text
    const processed = preprocessText(text);
    const truncated = truncateText(processed, 500);

    // Create prompt
    const prompt = `You are an SMS spam detector. Analyze the following SMS message and classify it as spam or ham (not spam).

SMS Message: "${truncated}"

Classify this message and respond with ONLY valid JSON in this exact format:
{
  "isSpam": true or false,
  "confidence": 0.0 to 1.0,
  "reason": "brief one-sentence explanation"
}

Consider these spam indicators:
- Unsolicited offers, prizes, or giveaways
- Urgent calls to action (limited time, act now)
- Requests for personal/financial information
- Suspicious links or phone numbers
- Poor grammar or excessive capital letters
- Financial schemes (loans, investments, crypto)
- Phishing attempts

Respond ONLY with the JSON object, no other text.`;

    // Call Gemini API
    const result = await this.model.generateContent(prompt);
    const response = await result.response;
    const responseText = response.text();

    // Parse JSON response
    try {
      // Extract JSON from response (in case there's extra text)
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No JSON found in response');
      }

      const parsed = JSON.parse(jsonMatch[0]);

      // Validate response structure
      if (
        typeof parsed.isSpam !== 'boolean' ||
        typeof parsed.confidence !== 'number' ||
        typeof parsed.reason !== 'string'
      ) {
        throw new Error('Invalid response structure');
      }

      // Clamp confidence to 0-1
      parsed.confidence = Math.max(0, Math.min(1, parsed.confidence));

      return parsed as ClassificationResult;
    } catch (parseError) {
      console.error('Failed to parse AI response:', responseText, parseError);
      throw new Error('Invalid AI response format');
    }
  }

  /**
   * Fallback classification using keyword matching
   */
  private classifyWithKeywords(text: string): ClassificationResult {
    const score = calculateKeywordSpamScore(text, SPAM_KEYWORDS);
    const isSpam = score > 0.15; // Threshold: 15% of words are spam keywords

    return {
      isSpam,
      confidence: Math.min(score * 2, 0.85), // Max confidence 85% for keyword detection
      reason: isSpam
        ? `Detected spam keywords (${Math.round(score * 100)}% match). Using fallback detection.`
        : 'No significant spam keywords detected. Using fallback detection.',
    };
  }

  /**
   * Rate limiting helper
   */
  private async waitForRateLimit(): Promise<void> {
    const now = Date.now();
    const timeSinceLastCall = now - this.lastCallTime;

    if (timeSinceLastCall < this.rateLimitMs) {
      const waitTime = this.rateLimitMs - timeSinceLastCall;
      await sleep(waitTime);
    }

    this.lastCallTime = Date.now();
  }

  /**
   * Batch classify multiple messages
   */
  async classifyBatch(messages: Array<{ id: string; text: string }>): Promise<
    Array<{ id: string; result: ClassificationResult }>
  > {
    const results: Array<{ id: string; result: ClassificationResult }> = [];

    for (const message of messages) {
      try {
        const result = await this.classifyMessage(message.text);
        results.push({ id: message.id, result });
      } catch (error) {
        console.error(`Failed to classify message ${message.id}:`, error);
        // Add fallback result
        results.push({
          id: message.id,
          result: this.classifyWithKeywords(message.text),
        });
      }
    }

    return results;
  }

  /**
   * Test classification with sample message
   */
  async testClassification(): Promise<{
    success: boolean;
    error?: string;
    result?: ClassificationResult;
  }> {
    const testMessage = 'URGENT! You have won $1,000,000! Click here to claim your prize now!';

    try {
      const result = await this.classifyMessage(testMessage);
      return { success: true, result };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Update rate limit
   */
  setRateLimit(ms: number): void {
    this.rateLimitMs = Math.max(1000, ms); // Minimum 1 second
  }

  /**
   * Reset service
   */
  reset(): void {
    this.genAI = null;
    this.model = null;
    this.apiKey = null;
    this.lastCallTime = 0;
  }
}

// Export singleton instance
export const classificationService = new ClassificationService();
