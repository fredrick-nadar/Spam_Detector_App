import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { SMSMessage, MessageStats, AppConfig, PermissionState } from '../types';

interface AppState {
  // Messages
  messages: SMSMessage[];
  stats: MessageStats;
  isLoadingMessages: boolean;

  // Config
  config: AppConfig;
  isConfigured: boolean;

  // Monitoring
  isMonitoring: boolean;
  isProcessing: boolean;

  // Permissions
  permissions: PermissionState;

  // Actions
  setMessages: (messages: SMSMessage[]) => void;
  addMessage: (message: SMSMessage) => void;
  updateMessage: (messageId: string, updates: Partial<SMSMessage>) => void;
  setStats: (stats: MessageStats) => void;
  setConfig: (config: Partial<AppConfig>) => Promise<void>;
  loadConfig: () => Promise<void>;
  setMonitoring: (isMonitoring: boolean) => void;
  setProcessing: (isProcessing: boolean) => void;
  setPermissions: (permissions: PermissionState) => void;
  setLoadingMessages: (isLoading: boolean) => void;
  reset: () => Promise<void>;
}

const DEFAULT_CONFIG: AppConfig = {
  geminiApiKey: 'AIzaSyA9nvMSSpKsdZGjO36y1g-K-cWpeBqtZa4',
  telegramBotToken: '8052643706:AAFz8o4AsnxMfB3LYhw7ehPszOf2pPqhvp0',
  telegramChatId: '6185770061',
  notificationsEnabled: true,
  monitoringEnabled: false,
  batchSize: 10,
  rateLimitMs: 2000,
};

const DEFAULT_STATS: MessageStats = {
  totalMessages: 0,
  spamCount: 0,
  hamCount: 0,
  unclassifiedCount: 0,
  lastUpdated: Date.now(),
};

const DEFAULT_PERMISSIONS: PermissionState = {
  readSms: 'not_requested',
  receiveSms: 'not_requested',
  sendSms: 'not_requested',
};

const CONFIG_STORAGE_KEY = '@sms_spam_detector:config';

export const useAppStore = create<AppState>((set, get) => ({
  // Initial state
  messages: [],
  stats: DEFAULT_STATS,
  isLoadingMessages: false,
  config: DEFAULT_CONFIG,
  isConfigured: false,
  isMonitoring: false,
  isProcessing: false,
  permissions: DEFAULT_PERMISSIONS,

  // Actions
  setMessages: (messages) => set({ messages }),

  addMessage: (message) => {
    const { messages } = get();
    const existingIndex = messages.findIndex((m) => m.id === message.id);

    if (existingIndex >= 0) {
      // Update existing message
      const updated = [...messages];
      updated[existingIndex] = message;
      set({ messages: updated });
    } else {
      // Add new message at beginning
      set({ messages: [message, ...messages] });
    }
  },

  updateMessage: (messageId, updates) => {
    const { messages } = get();
    const index = messages.findIndex((m) => m.id === messageId);

    if (index >= 0) {
      const updated = [...messages];
      updated[index] = { ...updated[index], ...updates };
      set({ messages: updated });
    }
  },

  setStats: (stats) => set({ stats }),

  setConfig: async (configUpdates) => {
    const { config } = get();
    const newConfig = { ...config, ...configUpdates };

    // Check if configured
    const isConfigured =
      !!newConfig.geminiApiKey &&
      !!newConfig.telegramBotToken &&
      !!newConfig.telegramChatId;

    // Save to storage
    try {
      await AsyncStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(newConfig));
      set({ config: newConfig, isConfigured });
      console.log('Config saved successfully');
    } catch (error) {
      console.error('Failed to save config:', error);
      throw error;
    }
  },

  loadConfig: async () => {
    try {
      const stored = await AsyncStorage.getItem(CONFIG_STORAGE_KEY);

      if (stored) {
        const config = JSON.parse(stored) as AppConfig;

        // Check if configured
        const isConfigured =
          !!config.geminiApiKey &&
          !!config.telegramBotToken &&
          !!config.telegramChatId;

        set({ config, isConfigured });
        console.log('Config loaded successfully');
      }
    } catch (error) {
      console.error('Failed to load config:', error);
    }
  },

  setMonitoring: (isMonitoring) => set({ isMonitoring }),

  setProcessing: (isProcessing) => set({ isProcessing }),

  setPermissions: (permissions) => set({ permissions }),

  setLoadingMessages: (isLoading) => set({ isLoadingMessages: isLoading }),

  reset: async () => {
    try {
      await AsyncStorage.removeItem(CONFIG_STORAGE_KEY);
      set({
        messages: [],
        stats: DEFAULT_STATS,
        config: DEFAULT_CONFIG,
        isConfigured: false,
        isMonitoring: false,
        isProcessing: false,
        permissions: DEFAULT_PERMISSIONS,
        isLoadingMessages: false,
      });
      console.log('Store reset successfully');
    } catch (error) {
      console.error('Failed to reset store:', error);
      throw error;
    }
  },
}));
