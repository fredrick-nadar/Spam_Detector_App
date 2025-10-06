// Text preprocessing utilities for NLP

/**
 * Preprocesses SMS text for classification
 * - Converts to lowercase
 * - Removes punctuation
 * - Removes extra whitespace
 * - Tokenizes into words
 */
export function preprocessText(text: string): string {
  if (!text) return '';

  // Convert to lowercase
  let processed = text.toLowerCase();

  // Remove URLs
  processed = processed.replace(/https?:\/\/[^\s]+/g, ' ');

  // Remove email addresses
  processed = processed.replace(/[\w.-]+@[\w.-]+\.\w+/g, ' ');

  // Remove phone numbers (various formats)
  processed = processed.replace(/(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}/g, ' ');

  // Remove punctuation (keep apostrophes in contractions)
  processed = processed.replace(/[^\w\s']/g, ' ');

  // Remove extra whitespace
  processed = processed.replace(/\s+/g, ' ').trim();

  return processed;
}

/**
 * Tokenizes text into words
 */
export function tokenize(text: string): string[] {
  return preprocessText(text).split(' ').filter((word) => word.length > 0);
}

/**
 * Checks if text contains spam keywords (fallback method)
 */
export function containsSpamKeywords(text: string, keywords: string[]): boolean {
  const processed = preprocessText(text);
  return keywords.some((keyword) => processed.includes(keyword.toLowerCase()));
}

/**
 * Calculates simple spam score based on keyword matching
 * Returns 0-1 score
 */
export function calculateKeywordSpamScore(text: string, keywords: string[]): number {
  const tokens = tokenize(text);
  if (tokens.length === 0) return 0;

  let matchCount = 0;
  const processedKeywords = keywords.map((k) => k.toLowerCase());

  tokens.forEach((token) => {
    if (processedKeywords.some((keyword) => keyword.includes(token) || token.includes(keyword))) {
      matchCount++;
    }
  });

  return Math.min(matchCount / tokens.length, 1);
}

/**
 * Truncates text to max length for API calls
 */
export function truncateText(text: string, maxLength: number = 500): string {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}
