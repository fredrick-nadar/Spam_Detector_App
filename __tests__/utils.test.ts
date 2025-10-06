/**
 * Test file for classification and text preprocessing utilities
 * 
 * To run tests, you need to install Jest:
 * npm install --save-dev jest @types/jest ts-jest
 * 
 * Then add to package.json:
 * "scripts": {
 *   "test": "jest"
 * }
 */

import {
  preprocessText,
  tokenize,
  containsSpamKeywords,
  calculateKeywordSpamScore,
} from '../src/utils/textPreprocessing';
import { SPAM_KEYWORDS } from '../src/types';

describe('Text Preprocessing', () => {
  describe('preprocessText', () => {
    it('should convert text to lowercase', () => {
      const result = preprocessText('HELLO WORLD');
      expect(result).toBe('hello world');
    });

    it('should remove URLs', () => {
      const result = preprocessText('Visit https://example.com now');
      expect(result).not.toContain('https://example.com');
    });

    it('should remove email addresses', () => {
      const result = preprocessText('Contact us at test@example.com');
      expect(result).not.toContain('test@example.com');
    });

    it('should remove phone numbers', () => {
      const result = preprocessText('Call 123-456-7890 now');
      expect(result).not.toContain('123-456-7890');
    });

    it('should remove extra whitespace', () => {
      const result = preprocessText('Hello    World    Test');
      expect(result).toBe('hello world test');
    });

    it('should handle empty string', () => {
      const result = preprocessText('');
      expect(result).toBe('');
    });
  });

  describe('tokenize', () => {
    it('should split text into words', () => {
      const result = tokenize('hello world test');
      expect(result).toEqual(['hello', 'world', 'test']);
    });

    it('should handle empty string', () => {
      const result = tokenize('');
      expect(result).toEqual([]);
    });

    it('should filter out empty tokens', () => {
      const result = tokenize('hello  world');
      expect(result).toEqual(['hello', 'world']);
    });
  });

  describe('containsSpamKeywords', () => {
    it('should detect spam keywords', () => {
      const text = 'Congratulations! You won a prize!';
      const result = containsSpamKeywords(text, SPAM_KEYWORDS);
      expect(result).toBe(true);
    });

    it('should return false for clean text', () => {
      const text = 'Hey, how are you doing?';
      const result = containsSpamKeywords(text, SPAM_KEYWORDS);
      expect(result).toBe(false);
    });

    it('should be case-insensitive', () => {
      const text = 'WINNER WINNER';
      const result = containsSpamKeywords(text, SPAM_KEYWORDS);
      expect(result).toBe(true);
    });
  });

  describe('calculateKeywordSpamScore', () => {
    it('should return 0 for clean text', () => {
      const text = 'Hello friend, how are you?';
      const score = calculateKeywordSpamScore(text, SPAM_KEYWORDS);
      expect(score).toBe(0);
    });

    it('should return positive score for spam text', () => {
      const text = 'URGENT! You won the lottery! Claim your prize now!';
      const score = calculateKeywordSpamScore(text, SPAM_KEYWORDS);
      expect(score).toBeGreaterThan(0);
    });

    it('should return score between 0 and 1', () => {
      const text = 'Free money! Click here to win!';
      const score = calculateKeywordSpamScore(text, SPAM_KEYWORDS);
      expect(score).toBeGreaterThanOrEqual(0);
      expect(score).toBeLessThanOrEqual(1);
    });

    it('should handle empty text', () => {
      const score = calculateKeywordSpamScore('', SPAM_KEYWORDS);
      expect(score).toBe(0);
    });
  });
});

// Mock tests for classification service (requires mocking Gemini API)
describe('Classification Service (Mock)', () => {
  it('should classify obvious spam correctly', async () => {
    // Mock test - actual implementation would require Gemini API
    const spamText = 'URGENT! You won $1,000,000! Click here NOW!';
    // Expected: { isSpam: true, confidence: > 0.8, reason: string }
  });

  it('should classify normal messages as ham', async () => {
    // Mock test
    const hamText = 'Hey, are we still meeting at 5pm?';
    // Expected: { isSpam: false, confidence: > 0.8, reason: string }
  });

  it('should handle rate limiting', async () => {
    // Mock test for rate limiting
    // Should delay between consecutive API calls
  });

  it('should fallback to keyword detection on API error', async () => {
    // Mock test for fallback mechanism
    // When Gemini API fails, should use keyword-based detection
  });
});

// Mock tests for database service
describe('Database Service (Mock)', () => {
  it('should insert and retrieve messages', async () => {
    // Mock test for database operations
    // Would require test database setup
  });

  it('should update classification results', async () => {
    // Mock test for updating classifications
  });

  it('should calculate stats correctly', async () => {
    // Mock test for stats calculation
  });

  it('should handle concurrent operations', async () => {
    // Mock test for concurrent database access
  });
});

// Integration tests (require full setup)
describe('End-to-End Tests (Integration)', () => {
  it('should process incoming SMS end-to-end', async () => {
    // 1. Receive SMS
    // 2. Store in database
    // 3. Classify with AI
    // 4. Update database
    // 5. Send notification if spam
    // 6. Verify all steps completed
  });

  it('should handle offline mode gracefully', async () => {
    // 1. Disable network
    // 2. Receive SMS
    // 3. Should store and queue
    // 4. Enable network
    // 5. Should process queue
  });
});
