import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import HomeScreen from '../screens/HomeScreen';
import StatsScreen from '../screens/StatsScreen';
import ConfigScreen from '../screens/ConfigScreen';
import { useAppStore } from '../store/appStore';
import { classificationService } from '../services/classificationService';
import { telegramService } from '../services/telegramService';
import { databaseService } from '../services/databaseService';

export type RootStackParamList = {
  Home: undefined;
  Stats: undefined;
  Config: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function AppNavigator() {
  const { config, loadConfig, isConfigured } = useAppStore();

  useEffect(() => {
    // Load config from storage on mount
    loadConfig();
  }, []);

  useEffect(() => {
    // Auto-initialize services with hardcoded config
    const initializeServices = async () => {
      try {
        // Initialize database
        await databaseService.initialize();

        // Initialize classification service if API key is present
        if (config.geminiApiKey) {
          classificationService.initialize(config.geminiApiKey, config.rateLimitMs);
          console.log('Classification service auto-initialized');
        }

        // Initialize telegram service if credentials are present
        if (config.telegramBotToken && config.telegramChatId) {
          telegramService.initialize(
            config.telegramBotToken,
            config.telegramChatId,
            config.notificationsEnabled
          );
          console.log('Telegram service auto-initialized');
        }
      } catch (error) {
        console.error('Failed to auto-initialize services:', error);
      }
    };

    if (config.geminiApiKey || config.telegramBotToken) {
      initializeServices();
    }
  }, [config]);

  return (
    <NavigationContainer>
      <Stack.Navigator
        initialRouteName="Home"
        screenOptions={{
          headerStyle: {
            backgroundColor: '#6200ee',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          options={{ title: 'SMS Spam Detector' }}
        />
        <Stack.Screen
          name="Stats"
          component={StatsScreen}
          options={{ title: 'Statistics' }}
        />
        <Stack.Screen
          name="Config"
          component={ConfigScreen}
          options={{ title: 'Configuration' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
