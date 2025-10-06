import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import {
  TextInput,
  Button,
  Card,
  Title,
  Paragraph,
  Switch,
  Text,
  Divider,
  ActivityIndicator,
} from 'react-native-paper';
import { useAppStore } from '../store/appStore';
import { classificationService } from '../services/classificationService';
import { telegramService } from '../services/telegramService';

export default function ConfigScreen() {
  const { config, isConfigured, setConfig } = useAppStore();

  const [geminiApiKey, setGeminiApiKey] = useState(config.geminiApiKey);
  const [telegramBotToken, setTelegramBotToken] = useState(
    config.telegramBotToken
  );
  const [telegramChatId, setTelegramChatId] = useState(config.telegramChatId);
  const [notificationsEnabled, setNotificationsEnabled] = useState(
    config.notificationsEnabled
  );
  const [rateLimitMs, setRateLimitMs] = useState(
    config.rateLimitMs.toString()
  );
  const [isSaving, setIsSaving] = useState(false);
  const [isTesting, setIsTesting] = useState(false);

  useEffect(() => {
    // Update local state when config changes
    setGeminiApiKey(config.geminiApiKey);
    setTelegramBotToken(config.telegramBotToken);
    setTelegramChatId(config.telegramChatId);
    setNotificationsEnabled(config.notificationsEnabled);
    setRateLimitMs(config.rateLimitMs.toString());
  }, [config]);

  const handleSave = async () => {
    // Validate inputs
    if (!geminiApiKey.trim()) {
      Alert.alert('Error', 'Gemini API Key is required');
      return;
    }

    if (!telegramBotToken.trim() || !telegramChatId.trim()) {
      Alert.alert('Error', 'Telegram Bot Token and Chat ID are required');
      return;
    }

    const rateLimitValue = parseInt(rateLimitMs, 10);
    if (isNaN(rateLimitValue) || rateLimitValue < 1000) {
      Alert.alert('Error', 'Rate limit must be at least 1000ms');
      return;
    }

    try {
      setIsSaving(true);

      // Save config
      await setConfig({
        geminiApiKey: geminiApiKey.trim(),
        telegramBotToken: telegramBotToken.trim(),
        telegramChatId: telegramChatId.trim(),
        notificationsEnabled,
        rateLimitMs: rateLimitValue,
      });

      // Initialize services with new config
      classificationService.initialize(geminiApiKey.trim(), rateLimitValue);
      telegramService.initialize(
        telegramBotToken.trim(),
        telegramChatId.trim(),
        notificationsEnabled
      );

      Alert.alert('Success', 'Configuration saved successfully!');
    } catch (error) {
      console.error('Failed to save config:', error);
      Alert.alert('Error', 'Failed to save configuration');
    } finally {
      setIsSaving(false);
    }
  };

  const handleTestGemini = async () => {
    if (!geminiApiKey.trim()) {
      Alert.alert('Error', 'Please enter Gemini API Key first');
      return;
    }

    try {
      setIsTesting(true);

      // Initialize service temporarily
      classificationService.initialize(geminiApiKey.trim(), 2000);

      // Test classification
      const result = await classificationService.testClassification();

      if (result.success) {
        Alert.alert(
          'Success',
          `Gemini AI is working!\n\nTest Classification:\nIs Spam: ${result.result?.isSpam ? 'Yes' : 'No'}\nConfidence: ${Math.round((result.result?.confidence || 0) * 100)}%\nReason: ${result.result?.reason}`
        );
      } else {
        Alert.alert('Error', `Test failed: ${result.error}`);
      }
    } catch (error) {
      console.error('Gemini test failed:', error);
      Alert.alert('Error', 'Failed to test Gemini AI connection');
    } finally {
      setIsTesting(false);
    }
  };

  const handleTestTelegram = async () => {
    if (!telegramBotToken.trim() || !telegramChatId.trim()) {
      Alert.alert('Error', 'Please enter Telegram credentials first');
      return;
    }

    try {
      setIsTesting(true);

      // Initialize service temporarily
      telegramService.initialize(
        telegramBotToken.trim(),
        telegramChatId.trim(),
        true
      );

      // Test notification
      const result = await telegramService.testNotification();

      if (result.success) {
        Alert.alert(
          'Success',
          'Test message sent to Telegram! Check your chat.'
        );
      } else {
        Alert.alert('Error', `Test failed: ${result.error}`);
      }
    } catch (error) {
      console.error('Telegram test failed:', error);
      Alert.alert('Error', 'Failed to test Telegram connection');
    } finally {
      setIsTesting(false);
    }
  };

  const handleReset = () => {
    Alert.alert(
      'Reset Configuration',
      'Are you sure you want to reset all settings? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reset',
          style: 'destructive',
          onPress: async () => {
            try {
              await setConfig({
                geminiApiKey: '',
                telegramBotToken: '',
                telegramChatId: '',
                notificationsEnabled: true,
                rateLimitMs: 2000,
                monitoringEnabled: false,
                batchSize: 10,
              });
              Alert.alert('Success', 'Configuration reset successfully');
            } catch (error) {
              Alert.alert('Error', 'Failed to reset configuration');
            }
          },
        },
      ]
    );
  };

  return (
    <ScrollView style={styles.container}>
      {/* Status */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Configuration Status</Title>
          <Paragraph>
            {isConfigured ? (
              <Text style={styles.configured}>✅ Configured</Text>
            ) : (
              <Text style={styles.notConfigured}>❌ Not Configured</Text>
            )}
          </Paragraph>
        </Card.Content>
      </Card>

      {/* Gemini AI Configuration */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Gemini AI Configuration</Title>
          <Paragraph style={styles.description}>
            Used for SMS classification. Get your API key from Google AI Studio.
          </Paragraph>

          <TextInput
            label="Gemini API Key"
            value={geminiApiKey}
            onChangeText={setGeminiApiKey}
            secureTextEntry
            mode="outlined"
            style={styles.input}
            placeholder="AIza..."
          />

          <Button
            mode="outlined"
            onPress={handleTestGemini}
            loading={isTesting}
            disabled={isTesting || !geminiApiKey.trim()}
            style={styles.testButton}
          >
            Test Connection
          </Button>
        </Card.Content>
      </Card>

      {/* Telegram Configuration */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Telegram Notifications</Title>
          <Paragraph style={styles.description}>
            Receive spam alerts via Telegram. Create a bot using @BotFather and
            get your Chat ID.
          </Paragraph>

          <TextInput
            label="Telegram Bot Token"
            value={telegramBotToken}
            onChangeText={setTelegramBotToken}
            secureTextEntry
            mode="outlined"
            style={styles.input}
            placeholder="1234567890:ABC..."
          />

          <TextInput
            label="Telegram Chat ID"
            value={telegramChatId}
            onChangeText={setTelegramChatId}
            mode="outlined"
            style={styles.input}
            placeholder="123456789"
            keyboardType="numeric"
          />

          <View style={styles.switchRow}>
            <Text>Enable Notifications</Text>
            <Switch
              value={notificationsEnabled}
              onValueChange={setNotificationsEnabled}
            />
          </View>

          <Button
            mode="outlined"
            onPress={handleTestTelegram}
            loading={isTesting}
            disabled={
              isTesting ||
              !telegramBotToken.trim() ||
              !telegramChatId.trim()
            }
            style={styles.testButton}
          >
            Send Test Message
          </Button>
        </Card.Content>
      </Card>

      {/* Advanced Settings */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Advanced Settings</Title>

          <TextInput
            label="Rate Limit (ms)"
            value={rateLimitMs}
            onChangeText={setRateLimitMs}
            mode="outlined"
            style={styles.input}
            keyboardType="numeric"
            placeholder="2000"
          />
          <Paragraph style={styles.helperText}>
            Delay between API calls to avoid rate limiting (min: 1000ms)
          </Paragraph>
        </Card.Content>
      </Card>

      {/* Action Buttons */}
      <Card style={styles.card}>
        <Card.Content>
          <Button
            mode="contained"
            onPress={handleSave}
            loading={isSaving}
            disabled={isSaving}
            style={styles.saveButton}
          >
            Save Configuration
          </Button>

          <Button
            mode="outlined"
            onPress={handleReset}
            style={styles.resetButton}
          >
            Reset to Defaults
          </Button>
        </Card.Content>
      </Card>

      {/* Help */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Need Help?</Title>
          <Paragraph style={styles.helpText}>
            • Gemini API Key: Visit https://aistudio.google.com/app/apikey
            {'\n'}• Telegram Bot: Search for @BotFather on Telegram
            {'\n'}• Chat ID: Use @userinfobot on Telegram to get your Chat ID
          </Paragraph>
        </Card.Content>
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  card: {
    margin: 16,
  },
  description: {
    marginBottom: 16,
    color: '#666',
  },
  input: {
    marginBottom: 16,
  },
  testButton: {
    marginTop: 8,
  },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginVertical: 16,
  },
  helperText: {
    fontSize: 12,
    color: '#666',
    marginTop: -8,
  },
  saveButton: {
    marginBottom: 12,
  },
  resetButton: {
    borderColor: '#d32f2f',
  },
  configured: {
    color: '#388e3c',
    fontWeight: 'bold',
  },
  notConfigured: {
    color: '#d32f2f',
    fontWeight: 'bold',
  },
  helpText: {
    fontSize: 14,
    lineHeight: 24,
  },
});
