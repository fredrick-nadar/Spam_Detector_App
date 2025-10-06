import { EmitterSubscription } from 'react-native';
import {
  SmsModule,
  addSmsReceivedListener,
  removeAllSmsListeners,
  SmsReceivedEvent,
  NativeSmsMessage,
} from '../native/SmsModule';
import { databaseService } from './databaseService';
import { classificationService } from './classificationService';
import { telegramService } from './telegramService';
import { SMSMessage } from '../types';
import { generateId } from '../utils/helpers';

class SmsMonitoringService {
  private subscription: EmitterSubscription | null = null;
  private isMonitoring: boolean = false;
  private onMessageCallback: ((message: SMSMessage) => void) | null = null;
  private onStatsUpdateCallback: (() => void) | null = null;

  /**
   * Start monitoring for incoming SMS
   */
  async startMonitoring(
    onMessage?: (message: SMSMessage) => void,
    onStatsUpdate?: () => void
  ): Promise<void> {
    if (this.isMonitoring) {
      console.log('Already monitoring SMS');
      return;
    }

    this.onMessageCallback = onMessage || null;
    this.onStatsUpdateCallback = onStatsUpdate || null;

    // Set up listener for incoming SMS
    this.subscription = addSmsReceivedListener(this.handleIncomingSms.bind(this));

    this.isMonitoring = true;
    console.log('SMS monitoring started');
  }

  /**
   * Stop monitoring
   */
  stopMonitoring(): void {
    if (this.subscription) {
      this.subscription.remove();
      this.subscription = null;
    }

    removeAllSmsListeners();
    this.isMonitoring = false;
    this.onMessageCallback = null;
    this.onStatsUpdateCallback = null;

    console.log('SMS monitoring stopped');
  }

  /**
   * Check if monitoring is active
   */
  isActive(): boolean {
    return this.isMonitoring;
  }

  /**
   * Handle incoming SMS from broadcast receiver
   */
  private async handleIncomingSms(event: SmsReceivedEvent): Promise<void> {
    console.log('New SMS received:', event.sender);

    try {
      // Create SMS message object
      const message: SMSMessage = {
        id: generateId(),
        sender: event.sender,
        body: event.body,
        timestamp: event.timestamp,
        isSpam: null,
      };

      // Store in database
      await databaseService.insertMessage(message);

      // Notify callback
      if (this.onMessageCallback) {
        this.onMessageCallback(message);
      }

      // Classify message
      await this.classifyAndNotify(message);

      // Update stats
      if (this.onStatsUpdateCallback) {
        this.onStatsUpdateCallback();
      }
    } catch (error) {
      console.error('Error handling incoming SMS:', error);
    }
  }

  /**
   * Classify message and send notification if spam
   */
  private async classifyAndNotify(message: SMSMessage): Promise<void> {
    try {
      // Classify message
      const result = await classificationService.classifyMessage(message.body);

      // Update database
      await databaseService.updateClassification(
        message.id,
        result.isSpam,
        result.confidence,
        result.reason
      );

      // Update message object
      message.isSpam = result.isSpam;
      message.confidence = result.confidence;
      message.reason = result.reason;
      message.classifiedAt = Date.now();

      // Send Telegram notification if spam
      if (result.isSpam) {
        console.log(`Spam detected from ${message.sender}`);
        await telegramService.sendSpamNotification(message);
      }

      // Notify callback with updated message
      if (this.onMessageCallback) {
        this.onMessageCallback(message);
      }
    } catch (error) {
      console.error('Error classifying message:', error);
    }
  }

  /**
   * Load and classify existing messages from inbox
   */
  async loadAndClassifyInbox(limit: number = 50): Promise<number> {
    try {
      console.log(`Loading inbox messages (limit: ${limit})`);

      // Get messages from device
      const nativeMessages = await SmsModule.getAllMessages(limit);

      let processedCount = 0;

      for (const nativeMsg of nativeMessages) {
        try {
          // Check if message already exists
          const existing = await databaseService.getMessage(nativeMsg.id);

          if (!existing) {
            // Create new message
            const message: SMSMessage = {
              id: nativeMsg.id,
              sender: nativeMsg.sender,
              body: nativeMsg.body,
              timestamp: nativeMsg.timestamp,
              isSpam: null,
            };

            // Store in database
            await databaseService.insertMessage(message);

            // Classify message
            const result = await classificationService.classifyMessage(message.body);

            // Update database with classification
            await databaseService.updateClassification(
              message.id,
              result.isSpam,
              result.confidence,
              result.reason
            );

            // Send Telegram notification if spam
            if (result.isSpam) {
              console.log(`Spam detected in inbox: ${message.sender}`);
              message.isSpam = result.isSpam;
              message.confidence = result.confidence;
              message.reason = result.reason;
              await telegramService.sendSpamNotification(message);
            }

            processedCount++;

            // Notify callback
            if (this.onMessageCallback) {
              message.isSpam = result.isSpam;
              message.confidence = result.confidence;
              message.reason = result.reason;
              message.classifiedAt = Date.now();
              this.onMessageCallback(message);
            }
          }
        } catch (error) {
          console.error(`Error processing message ${nativeMsg.id}:`, error);
        }
      }

      console.log(`Processed ${processedCount} new messages from inbox`);

      // Update stats
      if (this.onStatsUpdateCallback) {
        this.onStatsUpdateCallback();
      }

      return processedCount;
    } catch (error) {
      console.error('Error loading inbox:', error);
      throw error;
    }
  }

  /**
   * Classify unclassified messages in database
   */
  async classifyPendingMessages(limit: number = 10): Promise<number> {
    try {
      const messages = await databaseService.getUnclassifiedMessages(limit);

      console.log(`Classifying ${messages.length} pending messages`);

      for (const message of messages) {
        try {
          const result = await classificationService.classifyMessage(message.body);

          await databaseService.updateClassification(
            message.id,
            result.isSpam,
            result.confidence,
            result.reason
          );

          // Send notification if spam
          if (result.isSpam) {
            message.isSpam = result.isSpam;
            message.confidence = result.confidence;
            message.reason = result.reason;
            await telegramService.sendSpamNotification(message);
          }
        } catch (error) {
          console.error(`Error classifying message ${message.id}:`, error);
        }
      }

      // Update stats
      if (this.onStatsUpdateCallback) {
        this.onStatsUpdateCallback();
      }

      return messages.length;
    } catch (error) {
      console.error('Error classifying pending messages:', error);
      throw error;
    }
  }

  /**
   * Process Telegram notification queue
   */
  async processNotificationQueue(): Promise<{ sent: number; failed: number }> {
    return await telegramService.processQueue();
  }
}

// Export singleton instance
export const smsMonitoringService = new SmsMonitoringService();
