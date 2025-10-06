// Core data models for SMS Spam Detector

export interface SMSMessage {
  id: string;
  sender: string;
  body: string;
  timestamp: number;
  isSpam: boolean | null; // null = not yet classified
  confidence?: number;
  reason?: string;
  classifiedAt?: number;
}

export interface ClassificationResult {
  isSpam: boolean;
  confidence: number; // 0-1
  reason: string;
}

export interface AppConfig {
  geminiApiKey: string;
  telegramBotToken: string;
  telegramChatId: string;
  notificationsEnabled: boolean;
  monitoringEnabled: boolean;
  batchSize: number; // Max messages to classify at once
  rateLimitMs: number; // Delay between API calls
}

export interface MessageStats {
  totalMessages: number;
  spamCount: number;
  hamCount: number;
  unclassifiedCount: number;
  lastUpdated: number;
}

export interface NotificationQueue {
  id: string;
  messageId: string;
  sender: string;
  body: string;
  timestamp: number;
  attempts: number;
  lastAttempt?: number;
}

// Permission status types
export type PermissionStatus = 'granted' | 'denied' | 'never_ask_again' | 'not_requested';

export interface PermissionState {
  readSms: PermissionStatus;
  receiveSms: PermissionStatus;
  sendSms: PermissionStatus;
}

// Spam keywords for fallback detection
export const SPAM_KEYWORDS = [
  'lottery',
  'winner',
  'congratulations',
  'claim',
  'prize',
  'urgent',
  'limited time',
  'act now',
  'click here',
  'free',
  'cash',
  'discount',
  'offer',
  'deal',
  'credit',
  'loan',
  'debt',
  'investment',
  'earn money',
  'work from home',
  'bitcoin',
  'crypto',
  'viagra',
  'pharmacy',
  'pills',
  'weight loss',
  'enlarge',
  'singles',
  'dating',
  'verify account',
  'suspended',
  'confirm',
  'reset password',
  'bank account',
  'social security',
  'irs',
  'refund',
  'tax',
  'gift card',
];
