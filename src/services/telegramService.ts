import axios, { AxiosInstance } from 'axios';
import { SMSMessage } from '../types';
import { formatTimestamp, truncateText } from '../utils/helpers';

interface TelegramConfig {
  botToken: string;
  chatId: string;
  enabled: boolean;
}

class TelegramService {
  private config: TelegramConfig | null = null;
  private client: AxiosInstance | null = null;
  private queue: Array<{ message: SMSMessage; retries: number }> = [];
  private isProcessing: boolean = false;

  initialize(botToken: string, chatId: string, enabled: boolean = true): void {
    if (!botToken || !chatId) {
      throw new Error('Telegram bot token and chat ID are required');
    }

    this.config = { botToken, chatId, enabled };
    this.client = axios.create({
      baseURL: `https://api.telegram.org/bot${botToken}`,
      timeout: 10000,
    });

    console.log('Telegram service initialized');
  }

  isInitialized(): boolean {
    return this.config !== null && this.client !== null;
  }

  isEnabled(): boolean {
    return this.config?.enabled ?? false;
  }

  setEnabled(enabled: boolean): void {
    if (this.config) {
      this.config.enabled = enabled;
    }
  }

  /**
   * Send spam notification to Telegram
   */
  async sendSpamNotification(message: SMSMessage): Promise<boolean> {
    if (!this.isInitialized() || !this.isEnabled()) {
      console.log('Telegram service not initialized or disabled');
      return false;
    }

    try {
      const text = this.formatSpamMessage(message);
      await this.sendMessage(text);
      return true;
    } catch (error) {
      console.error('Failed to send Telegram notification:', error);
      // Add to queue for retry
      this.addToQueue(message);
      return false;
    }
  }

  /**
   * Send message to Telegram
   */
  private async sendMessage(text: string, parseMode: string = 'Markdown'): Promise<void> {
    if (!this.client || !this.config) {
      throw new Error('Telegram service not initialized');
    }

    const response = await this.client.post('/sendMessage', {
      chat_id: this.config.chatId,
      text,
      parse_mode: parseMode,
      disable_web_page_preview: true,
    });

    if (!response.data.ok) {
      throw new Error(`Telegram API error: ${response.data.description}`);
    }
  }

  /**
   * Format spam message for Telegram
   */
  private formatSpamMessage(message: SMSMessage): string {
    const sender = message.sender || 'Unknown';
    const timestamp = formatTimestamp(message.timestamp);
    const confidence = message.confidence
      ? `${Math.round(message.confidence * 100)}%`
      : 'N/A';
    const body = truncateText(message.body, 200);
    const reason = message.reason ? truncateText(message.reason, 100) : 'N/A';

    return `🚨 *Spam Detected*

*From:* ${sender}
*Time:* ${timestamp}
*Confidence:* ${confidence}

*Message:*
${body}

*Reason:*
${reason}

---
SMS Spam Detector RN`;
  }

  /**
   * Add message to offline queue
   */
  private addToQueue(message: SMSMessage): void {
    // Limit queue size to 50
    if (this.queue.length >= 50) {
      this.queue.shift(); // Remove oldest
    }

    this.queue.push({ message, retries: 0 });
    console.log(`Added message to Telegram queue. Queue size: ${this.queue.length}`);
  }

  /**
   * Process queued notifications
   */
  async processQueue(): Promise<{ sent: number; failed: number }> {
    if (!this.isInitialized() || !this.isEnabled() || this.isProcessing) {
      return { sent: 0, failed: 0 };
    }

    this.isProcessing = true;
    let sent = 0;
    let failed = 0;

    const itemsToProcess = [...this.queue];
    this.queue = [];

    for (const item of itemsToProcess) {
      try {
        await this.sendSpamNotification(item.message);
        sent++;
        // Small delay between messages
        await new Promise((resolve) => setTimeout(resolve, 500));
      } catch (error) {
        item.retries++;
        if (item.retries < 3) {
          this.queue.push(item); // Re-queue for retry
        } else {
          failed++;
        }
      }
    }

    this.isProcessing = false;
    console.log(`Processed Telegram queue: ${sent} sent, ${failed} failed`);

    return { sent, failed };
  }

  /**
   * Get queue size
   */
  getQueueSize(): number {
    return this.queue.length;
  }

  /**
   * Clear queue
   */
  clearQueue(): void {
    this.queue = [];
  }

  /**
   * Test notification
   */
  async testNotification(): Promise<{ success: boolean; error?: string }> {
    if (!this.isInitialized()) {
      return { success: false, error: 'Service not initialized' };
    }

    try {
      await this.sendMessage('✅ Test notification from SMS Spam Detector RN');
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Send batch summary
   */
  async sendBatchSummary(
    totalProcessed: number,
    spamCount: number,
    hamCount: number
  ): Promise<boolean> {
    if (!this.isInitialized() || !this.isEnabled()) {
      return false;
    }

    try {
      const text = `📊 *Batch Processing Summary*

*Total Messages:* ${totalProcessed}
*Spam Detected:* ${spamCount} (${Math.round((spamCount / totalProcessed) * 100)}%)
*Ham Messages:* ${hamCount} (${Math.round((hamCount / totalProcessed) * 100)}%)

---
SMS Spam Detector RN`;

      await this.sendMessage(text);
      return true;
    } catch (error) {
      console.error('Failed to send batch summary:', error);
      return false;
    }
  }

  /**
   * Reset service
   */
  reset(): void {
    this.config = null;
    this.client = null;
    this.queue = [];
    this.isProcessing = false;
  }
}

// Export singleton instance
export const telegramService = new TelegramService();
