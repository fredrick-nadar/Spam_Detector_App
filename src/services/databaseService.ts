import * as SQLite from 'expo-sqlite';
import { SMSMessage, MessageStats } from '../types';

const DB_NAME = 'sms_spam_detector.db';

class DatabaseService {
  private db: SQLite.SQLiteDatabase | null = null;
  private initializing: Promise<void> | null = null;

  async initialize(): Promise<void> {
    // Prevent multiple initializations
    if (this.initializing) {
      return this.initializing;
    }

    if (this.db) {
      console.log('Database already initialized');
      return;
    }

    this.initializing = (async () => {
      try {
        console.log('Initializing database...');
        this.db = await SQLite.openDatabaseAsync(DB_NAME);
        await this.createTables();
        console.log('Database initialized successfully');
      } catch (error) {
        console.error('Failed to initialize database:', error);
        this.db = null;
        throw error;
      } finally {
        this.initializing = null;
      }
    })();

    return this.initializing;
  }

  isInitialized(): boolean {
    return this.db !== null;
  }

  private async ensureInitialized(): Promise<void> {
    if (!this.db && !this.initializing) {
      await this.initialize();
    } else if (this.initializing) {
      await this.initializing;
    }

    if (!this.db) {
      throw new Error('Database failed to initialize');
    }
  }

  private async createTables(): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    // Create sms_messages table
    await this.db.execAsync(`
      CREATE TABLE IF NOT EXISTS sms_messages (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_spam INTEGER,
        confidence REAL,
        reason TEXT,
        classified_at INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000)
      );
    `);

    // Create index on timestamp for faster queries
    await this.db.execAsync(`
      CREATE INDEX IF NOT EXISTS idx_timestamp ON sms_messages(timestamp DESC);
    `);

    // Create index on is_spam for stats queries
    await this.db.execAsync(`
      CREATE INDEX IF NOT EXISTS idx_is_spam ON sms_messages(is_spam);
    `);

    // Create notification queue table
    await this.db.execAsync(`
      CREATE TABLE IF NOT EXISTS notification_queue (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        attempts INTEGER DEFAULT 0,
        last_attempt INTEGER,
        created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
        FOREIGN KEY (message_id) REFERENCES sms_messages(id)
      );
    `);

    console.log('Database tables created successfully');
  }

  async insertMessage(message: SMSMessage): Promise<void> {
    await this.ensureInitialized();

    const query = `
      INSERT OR REPLACE INTO sms_messages (
        id, sender, body, timestamp, is_spam, confidence, reason, classified_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    await this.db!.runAsync(
      query,
      message.id,
      message.sender,
      message.body,
      message.timestamp,
      message.isSpam === null ? null : message.isSpam ? 1 : 0,
      message.confidence ?? null,
      message.reason ?? null,
      message.classifiedAt ?? null
    );
  }

  async updateClassification(
    messageId: string,
    isSpam: boolean,
    confidence: number,
    reason: string
  ): Promise<void> {
    await this.ensureInitialized();

    const query = `
      UPDATE sms_messages 
      SET is_spam = ?, confidence = ?, reason = ?, classified_at = ?
      WHERE id = ?
    `;

    await this.db!.runAsync(
      query,
      isSpam ? 1 : 0,
      confidence,
      reason,
      Date.now(),
      messageId
    );
  }

  async getMessage(messageId: string): Promise<SMSMessage | null> {
    await this.ensureInitialized();

    const query = 'SELECT * FROM sms_messages WHERE id = ? LIMIT 1';
    const result = await this.db!.getFirstAsync<any>(query, messageId);

    if (!result) return null;

    return this.mapRowToMessage(result);
  }

  async getAllMessages(limit: number = 50, offset: number = 0): Promise<SMSMessage[]> {
    await this.ensureInitialized();

    const query = `
      SELECT * FROM sms_messages 
      ORDER BY timestamp DESC 
      LIMIT ? OFFSET ?
    `;

    const results = await this.db!.getAllAsync<any>(query, limit, offset);
    return results.map((row) => this.mapRowToMessage(row));
  }

  async getUnclassifiedMessages(limit: number = 10): Promise<SMSMessage[]> {
    await this.ensureInitialized();

    const query = `
      SELECT * FROM sms_messages 
      WHERE is_spam IS NULL 
      ORDER BY timestamp DESC 
      LIMIT ?
    `;

    const results = await this.db!.getAllAsync<any>(query, limit);
    return results.map((row) => this.mapRowToMessage(row));
  }

  async getMessagesSince(timestamp: number): Promise<SMSMessage[]> {
    await this.ensureInitialized();

    const query = `
      SELECT * FROM sms_messages 
      WHERE timestamp >= ? 
      ORDER BY timestamp DESC
    `;

    const results = await this.db!.getAllAsync<any>(query, timestamp);
    return results.map((row) => this.mapRowToMessage(row));
  }

  async getStats(): Promise<MessageStats> {
    await this.ensureInitialized();

    const query = `
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_spam = 1 THEN 1 ELSE 0 END) as spam,
        SUM(CASE WHEN is_spam = 0 THEN 1 ELSE 0 END) as ham,
        SUM(CASE WHEN is_spam IS NULL THEN 1 ELSE 0 END) as unclassified
      FROM sms_messages
    `;

    const result = await this.db!.getFirstAsync<any>(query);

    return {
      totalMessages: result?.total || 0,
      spamCount: result?.spam || 0,
      hamCount: result?.ham || 0,
      unclassifiedCount: result?.unclassified || 0,
      lastUpdated: Date.now(),
    };
  }

  async deleteMessage(messageId: string): Promise<void> {
    await this.ensureInitialized();

    await this.db!.runAsync('DELETE FROM sms_messages WHERE id = ?', messageId);
  }

  async clearAllMessages(): Promise<void> {
    await this.ensureInitialized();

    await this.db!.runAsync('DELETE FROM sms_messages');
  }

  // Notification queue operations
  async addToNotificationQueue(
    messageId: string,
    sender: string,
    body: string,
    timestamp: number
  ): Promise<string> {
    await this.ensureInitialized();

    const id = `nq_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    const query = `
      INSERT INTO notification_queue (id, message_id, sender, body, timestamp)
      VALUES (?, ?, ?, ?, ?)
    `;

    await this.db!.runAsync(query, id, messageId, sender, body, timestamp);
    return id;
  }

  async getNotificationQueue(): Promise<any[]> {
    await this.ensureInitialized();

    const query = `
      SELECT * FROM notification_queue 
      WHERE attempts < 3
      ORDER BY timestamp ASC
      LIMIT 10
    `;

    return await this.db!.getAllAsync(query);
  }

  async updateNotificationAttempt(queueId: string): Promise<void> {
    await this.ensureInitialized();

    const query = `
      UPDATE notification_queue 
      SET attempts = attempts + 1, last_attempt = ?
      WHERE id = ?
    `;

    await this.db!.runAsync(query, Date.now(), queueId);
  }

  async removeFromNotificationQueue(queueId: string): Promise<void> {
    await this.ensureInitialized();

    await this.db!.runAsync('DELETE FROM notification_queue WHERE id = ?', queueId);
  }

  private mapRowToMessage(row: any): SMSMessage {
    return {
      id: row.id,
      sender: row.sender,
      body: row.body,
      timestamp: row.timestamp,
      isSpam: row.is_spam === null ? null : row.is_spam === 1,
      confidence: row.confidence ?? undefined,
      reason: row.reason ?? undefined,
      classifiedAt: row.classified_at ?? undefined,
    };
  }

  async close(): Promise<void> {
    if (this.db) {
      await this.db.closeAsync();
      this.db = null;
      console.log('Database closed');
    }
  }
}

// Export singleton instance
export const databaseService = new DatabaseService();
