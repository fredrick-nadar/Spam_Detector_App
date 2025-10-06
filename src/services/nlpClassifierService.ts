import nlp from 'compromise';

/**
 * Advanced NLP-based spam classification service
 * Uses multiple linguistic features to accurately detect spam vs legitimate messages
 * React Native compatible - no Node.js dependencies
 */
class NLPClassifierService {
  
  // Trained patterns for spam detection
  private spamPatterns = {
    // Promotional/Marketing spam
    promotional: [
      /\b(free|offer|discount|sale|deal|limited time|hurry|act now)\b/gi,
      /\b(click here|visit|shop now|buy now)\b/gi,
      /\b(congratulations|winner|prize|reward)\b/gi,
    ],
    
    // Financial scams
    financialScam: [
      /\b(lottery|jackpot|million|billion|won|claim)\b/gi,
      /\b(urgent|immediate action|verify account|suspended)\b/gi,
      /\b(refund|tax return|inheritance|beneficiary)\b/gi,
    ],
    
    // Phishing attempts
    phishing: [
      /\b(verify|confirm|update|validate) (your )?(account|password|card|details)\b/gi,
      /\b(click|tap) (this |the )?(link|url)\b/gi,
      /\b(expire|expired|suspended|locked) (account|card)\b/gi,
    ],
    
    // Generic spam indicators
    genericSpam: [
      /\b(unsubscribe|opt[- ]out|reply stop)\b/gi,
      /\b(earn money|work from home|make \$)\b/gi,
      /\b(no credit check|guaranteed approval)\b/gi,
    ],
  };

  // Patterns for legitimate messages
  private legitimatePatterns = {
    // Banking & Financial transactions
    banking: [
      /\b(credited|debited|transaction|balance|account)\b/gi,
      /\b(INR|Rs\.?|₹)\s*[\d,]+/gi, // Indian currency
      /\b(UPI|NEFT|RTGS|IMPS)\b/gi,
      /\b(available balance|current balance|minimum balance)\b/gi,
      /\b(thank you for (using|banking|shopping))\b/gi,
    ],
    
    // OTP & Verification codes
    otp: [
      /\b(OTP|one[- ]time password|verification code|security code)\b/gi,
      /\b\d{4,6}\b.*\b(code|OTP|password|pin)\b/gi,
      /\bdo not share (this |your )?(code|OTP|password)\b/gi,
      /\b(valid for|expires in) \d+\s?(min|minutes|hour|hours)\b/gi,
    ],
    
    // Delivery & Order updates
    delivery: [
      /\b(order|parcel|package|delivery|shipped|dispatched)\b/gi,
      /\b(tracking (id|number|code)|AWB)\b/gi,
      /\b(out for delivery|delivered|in transit)\b/gi,
      /\b(expected delivery|estimated delivery)\b/gi,
    ],
    
    // Booking confirmations
    booking: [
      /\b(booking|reservation|confirmed|ticket|PNR)\b/gi,
      /\b(flight|train|bus|hotel|movie)\b.*\b(confirmed|booked)\b/gi,
      /\b(seat (number|no)|berth)\b/gi,
    ],
    
    // Service notifications
    service: [
      /\b(appointment|reminder|scheduled|meeting)\b/gi,
      /\b(bill|invoice|payment|due|statement)\b/gi,
      /\b(subscription|renewal|plan)\b/gi,
    ],
  };

  constructor() {
    // No initialization needed - pure pattern matching
  }

  /**
   * Simple tokenizer - split text into words
   */
  private tokenize(text: string): string[] {
    return text.toLowerCase().match(/\b\w+\b/g) || [];
  }

  /**
   * Main classification method - analyzes message using multiple NLP features
   */
  public classifyMessage(message: string): {
    isSpam: boolean;
    confidence: number;
    reason: string;
    features: Record<string, any>;
  } {
    const text = message.toLowerCase();
    
    // Extract linguistic features
    const features = {
      hasURL: this.detectURLs(text),
      hasPhoneNumber: this.detectPhoneNumbers(text),
      hasMoneyAmount: this.detectMoneyAmounts(text),
      urgencyScore: this.calculateUrgencyScore(text),
      sentimentScore: this.analyzeSentiment(text),
      spamKeywordCount: this.countSpamKeywords(text),
      legitPatternCount: this.countLegitimatePatterns(text),
      hasOTP: this.detectOTP(text),
      hasBankingTerms: this.detectBankingTerms(text),
      capitalRatio: this.calculateCapitalRatio(message),
      exclamationCount: (message.match(/!/g) || []).length,
      questionCount: (message.match(/\?/g) || []).length,
      wordCount: this.tokenize(text).length,
    };

    // Calculate spam probability using weighted scoring
    const score = this.calculateSpamScore(features);
    
    // Determine classification
    const isSpam = score > 0.5; // Threshold: 50%
    const confidence = Math.abs(score - 0.5) * 2; // 0-1 confidence scale
    
    // Generate explanation
    const reason = this.generateReason(features, isSpam, score);

    return {
      isSpam,
      confidence: Math.round(confidence * 100) / 100,
      reason,
      features,
    };
  }

  /**
   * Detect URLs in message
   */
  private detectURLs(text: string): boolean {
    const urlPatterns = [
      /https?:\/\//gi,
      /www\./gi,
      /\b\w+\.(com|in|org|net|co\.in|me|io)\b/gi,
      /bit\.ly|goo\.gl|tinyurl/gi,
    ];
    return urlPatterns.some(pattern => pattern.test(text));
  }

  /**
   * Detect phone numbers (10 digits or formatted)
   */
  private detectPhoneNumbers(text: string): boolean {
    const phonePatterns = [
      /\b\d{10}\b/g,
      /\+91[\s-]?\d{10}/g,
      /\d{3}[\s-]\d{3}[\s-]\d{4}/g,
    ];
    return phonePatterns.some(pattern => pattern.test(text));
  }

  /**
   * Detect money amounts (INR, Rs, $, etc.)
   */
  private detectMoneyAmounts(text: string): boolean {
    const moneyPatterns = [
      /\b(INR|Rs\.?|₹)\s*[\d,]+/gi,
      /\$\s*[\d,]+/g,
      /\b\d+\s*(crore|lakh|thousand|million|billion)\b/gi,
    ];
    return moneyPatterns.some(pattern => pattern.test(text));
  }

  /**
   * Calculate urgency score (0-1) based on urgent language
   */
  private calculateUrgencyScore(text: string): number {
    const urgentWords = [
      'urgent', 'immediately', 'now', 'hurry', 'quick', 'fast',
      'expire', 'expires', 'limited', 'today', 'act now', 'deadline',
    ];
    
    let score = 0;
    urgentWords.forEach(word => {
      if (text.includes(word)) score += 0.1;
    });
    
    // Multiple exclamation marks increase urgency
    const exclamations = (text.match(/!+/g) || []).length;
    score += Math.min(exclamations * 0.05, 0.3);
    
    return Math.min(score, 1);
  }

  /**
   * Analyze sentiment using compromise NLP
   */
  private analyzeSentiment(text: string): number {
    const doc = nlp(text);
    
    // Positive words indicate promotional content
    const positiveWords = ['free', 'win', 'winner', 'congratulations', 'amazing', 'best'];
    const negativeWords = ['expire', 'suspend', 'block', 'urgent', 'warning', 'alert'];
    
    let sentiment = 0;
    positiveWords.forEach(word => {
      if (doc.has(word)) sentiment += 0.1;
    });
    negativeWords.forEach(word => {
      if (doc.has(word)) sentiment -= 0.1;
    });
    
    return sentiment;
  }

  /**
   * Count spam keywords from patterns
   */
  private countSpamKeywords(text: string): number {
    let count = 0;
    Object.values(this.spamPatterns).forEach(patterns => {
      patterns.forEach(pattern => {
        const matches = text.match(pattern);
        if (matches) count += matches.length;
      });
    });
    return count;
  }

  /**
   * Count legitimate message patterns
   */
  private countLegitimatePatterns(text: string): number {
    let count = 0;
    Object.values(this.legitimatePatterns).forEach(patterns => {
      patterns.forEach(pattern => {
        const matches = text.match(pattern);
        if (matches) count += matches.length;
      });
    });
    return count;
  }

  /**
   * Detect OTP codes
   */
  private detectOTP(text: string): boolean {
    return this.legitimatePatterns.otp.some(pattern => pattern.test(text));
  }

  /**
   * Detect banking/financial transaction terms
   */
  private detectBankingTerms(text: string): boolean {
    return this.legitimatePatterns.banking.some(pattern => pattern.test(text));
  }

  /**
   * Calculate ratio of capital letters (ALL CAPS = spam indicator)
   */
  private calculateCapitalRatio(text: string): number {
    const letters = text.replace(/[^a-zA-Z]/g, '');
    if (letters.length === 0) return 0;
    const capitals = text.replace(/[^A-Z]/g, '');
    return capitals.length / letters.length;
  }

  /**
   * Calculate final spam score using weighted features
   */
  private calculateSpamScore(features: Record<string, any>): number {
    let score = 0.5; // Start neutral

    // SPAM INDICATORS (increase score towards 1.0)
    if (features.spamKeywordCount > 0) {
      score += features.spamKeywordCount * 0.15; // +15% per spam keyword
    }
    if (features.urgencyScore > 0.5) {
      score += 0.2; // High urgency = +20%
    }
    if (features.capitalRatio > 0.5) {
      score += 0.15; // ALL CAPS = +15%
    }
    if (features.exclamationCount > 2) {
      score += 0.1; // Multiple !!! = +10%
    }
    if (features.hasURL && !features.hasBankingTerms) {
      score += 0.2; // URL without banking context = +20%
    }

    // LEGITIMATE INDICATORS (decrease score towards 0.0)
    if (features.legitPatternCount > 0) {
      score -= features.legitPatternCount * 0.2; // -20% per legit pattern
    }
    if (features.hasOTP) {
      score -= 0.4; // OTP = -40% (strong legitimate indicator)
    }
    if (features.hasBankingTerms) {
      score -= 0.3; // Banking terms = -30%
    }
    if (features.hasMoneyAmount && features.hasBankingTerms) {
      score -= 0.2; // Transaction notification = -20%
    }

    // Ensure score stays in 0-1 range
    return Math.max(0, Math.min(1, score));
  }

  /**
   * Generate human-readable explanation
   */
  private generateReason(
    features: Record<string, any>,
    isSpam: boolean,
    score: number
  ): string {
    if (isSpam) {
      const reasons = [];
      if (features.spamKeywordCount > 0) {
        reasons.push(`${features.spamKeywordCount} spam keyword(s)`);
      }
      if (features.urgencyScore > 0.5) {
        reasons.push('urgent language');
      }
      if (features.capitalRatio > 0.5) {
        reasons.push('excessive capitalization');
      }
      if (features.hasURL) {
        reasons.push('contains suspicious link');
      }
      if (features.exclamationCount > 2) {
        reasons.push('multiple exclamation marks');
      }
      
      return reasons.length > 0
        ? `Spam detected: ${reasons.join(', ')}`
        : 'Spam pattern detected';
    } else {
      const reasons = [];
      if (features.hasOTP) {
        reasons.push('OTP/verification code');
      }
      if (features.hasBankingTerms) {
        reasons.push('banking transaction');
      }
      if (features.legitPatternCount > 0) {
        reasons.push(`${features.legitPatternCount} legitimate pattern(s)`);
      }
      
      return reasons.length > 0
        ? `Legitimate: ${reasons.join(', ')}`
        : 'No spam indicators found';
    }
  }
}

// Export singleton instance
export const nlpClassifierService = new NLPClassifierService();
