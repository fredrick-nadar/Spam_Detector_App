import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  StyleSheet,
  FlatList,
  RefreshControl,
  Alert,
} from 'react-native';
import {
  Button,
  Card,
  Title,
  Paragraph,
  Chip,
  FAB,
  Portal,
  Provider as PaperProvider,
  Text,
  ActivityIndicator,
} from 'react-native-paper';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/AppNavigator';
import { useAppStore } from '../store/appStore';
import { databaseService } from '../services/databaseService';
import { classificationService } from '../services/classificationService';
import { telegramService } from '../services/telegramService';
import { smsMonitoringService } from '../services/smsMonitoringService';
import { permissionsService } from '../services/permissionsService';
import { formatTimestamp, formatPercentage } from '../utils/helpers';
import { SMSMessage } from '../types';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export default function HomeScreen({ navigation }: Props) {
  const {
    messages,
    stats,
    config,
    isConfigured,
    isMonitoring,
    isLoadingMessages,
    setMessages,
    setStats,
    setMonitoring,
    setLoadingMessages,
    addMessage,
    loadConfig,
  } = useAppStore();

  const [fabOpen, setFabOpen] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    initializeApp();
  }, []);

  const initializeApp = async () => {
    try {
      // Load config
      await loadConfig();

      // Initialize database
      await databaseService.initialize();

      // Load messages
      await loadMessages();

      // Load stats
      await loadStats();

      // Check if configured and initialize services
      if (config.geminiApiKey) {
        classificationService.initialize(config.geminiApiKey, config.rateLimitMs);
      }

      if (config.telegramBotToken && config.telegramChatId) {
        telegramService.initialize(
          config.telegramBotToken,
          config.telegramChatId,
          config.notificationsEnabled
        );
      }
    } catch (error) {
      console.error('Failed to initialize app:', error);
      Alert.alert('Error', 'Failed to initialize app. Please restart.');
    }
  };

  const loadMessages = async () => {
    try {
      setLoadingMessages(true);
      const msgs = await databaseService.getAllMessages(50);
      setMessages(msgs);
    } catch (error) {
      console.error('Failed to load messages:', error);
    } finally {
      setLoadingMessages(false);
    }
  };

  const loadStats = async () => {
    try {
      const newStats = await databaseService.getStats();
      setStats(newStats);
    } catch (error) {
      console.error('Failed to load stats:', error);
    }
  };

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadMessages();
    await loadStats();
    setRefreshing(false);
  }, []);

  const handleToggleMonitoring = async () => {
    if (!isConfigured) {
      Alert.alert(
        'Configuration Required',
        'Please configure API keys before starting monitoring.',
        [{ text: 'OK', onPress: () => navigation.navigate('Config') }]
      );
      return;
    }

    if (isMonitoring) {
      smsMonitoringService.stopMonitoring();
      setMonitoring(false);
    } else {
      // Check permissions
      const hasPermissions = await permissionsService.hasRequiredPermissions();

      if (!hasPermissions) {
        const shouldRequest = await permissionsService.showPermissionRationale();

        if (shouldRequest) {
          const permissions = await permissionsService.requestPermissions();

          if (
            permissions.readSms !== 'granted' ||
            permissions.receiveSms !== 'granted'
          ) {
            Alert.alert('Permissions Denied', 'Cannot start monitoring without SMS permissions.');
            return;
          }
        } else {
          return;
        }
      }

      // Start monitoring
      try {
        await smsMonitoringService.startMonitoring(
          (message: SMSMessage) => {
            addMessage(message);
            loadStats();
          },
          () => {
            loadStats();
          }
        );
        setMonitoring(true);
      } catch (error) {
        console.error('Failed to start monitoring:', error);
        Alert.alert('Error', 'Failed to start SMS monitoring.');
      }
    }
  };

  const handleScanInbox = async () => {
    if (!isConfigured) {
      Alert.alert(
        'Configuration Required',
        'Please configure API keys first.',
        [{ text: 'OK', onPress: () => navigation.navigate('Config') }]
      );
      return;
    }

    Alert.alert(
      'Scan Inbox',
      'This will load and classify the 15 most recent messages from your inbox. This may take a while.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Scan',
          onPress: async () => {
            try {
              setLoadingMessages(true);
              const count = await smsMonitoringService.loadAndClassifyInbox(15);
              await loadMessages();
              await loadStats();
              Alert.alert('Success', `Processed ${count} messages from inbox.`);
            } catch (error) {
              console.error('Failed to scan inbox:', error);
              Alert.alert('Error', 'Failed to scan inbox.');
            } finally {
              setLoadingMessages(false);
            }
          },
        },
      ]
    );
  };

  const renderMessageItem = ({ item }: { item: SMSMessage }) => (
    <Card style={styles.messageCard}>
      <Card.Content>
        <View style={styles.messageHeader}>
          <Text style={styles.sender}>{item.sender}</Text>
          <Text style={styles.timestamp}>{formatTimestamp(item.timestamp)}</Text>
        </View>
        <Paragraph numberOfLines={2} style={styles.messageBody}>
          {item.body}
        </Paragraph>
        <View style={styles.messageFooter}>
          {item.isSpam === null ? (
            <Chip icon="help-circle" style={styles.chipUnknown}>
              Unclassified
            </Chip>
          ) : item.isSpam ? (
            <Chip icon="alert-circle" style={styles.chipSpam}>
              Spam ({formatPercentage(item.confidence || 0)})
            </Chip>
          ) : (
            <Chip icon="check-circle" style={styles.chipHam}>
              Ham ({formatPercentage(item.confidence || 0)})
            </Chip>
          )}
        </View>
      </Card.Content>
    </Card>
  );

  return (
    <PaperProvider>
      <View style={styles.container}>
        {/* Stats Summary */}
        <Card style={styles.statsCard}>
          <Card.Content>
            <View style={styles.statsRow}>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Total</Text>
                <Text style={styles.statValue}>{stats.totalMessages}</Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Spam</Text>
                <Text style={[styles.statValue, styles.spamText]}>
                  {stats.spamCount}
                </Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Ham</Text>
                <Text style={[styles.statValue, styles.hamText]}>
                  {stats.hamCount}
                </Text>
              </View>
            </View>
          </Card.Content>
        </Card>

        {/* Monitoring Status */}
        <View style={styles.statusBar}>
          <Text style={styles.statusText}>
            {isMonitoring ? '🟢 Monitoring Active' : '🔴 Monitoring Stopped'}
          </Text>
          <Button
            mode="contained"
            onPress={handleToggleMonitoring}
            style={styles.toggleButton}
          >
            {isMonitoring ? 'Stop' : 'Start'}
          </Button>
        </View>

        {/* Messages List */}
        {isLoadingMessages ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" />
            <Text style={styles.loadingText}>Loading messages...</Text>
          </View>
        ) : (
          <FlatList
            data={messages}
            renderItem={renderMessageItem}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.listContent}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
            }
            ListEmptyComponent={
              <View style={styles.emptyContainer}>
                <Text style={styles.emptyText}>
                  No messages yet. Tap "Scan Inbox" to load existing messages.
                </Text>
              </View>
            }
          />
        )}

        {/* FAB Menu */}
        <Portal>
          <FAB.Group
            visible={true}
            open={fabOpen}
            icon={fabOpen ? 'close' : 'menu'}
            actions={[
              {
                icon: 'cog',
                label: 'Settings',
                onPress: () => navigation.navigate('Config'),
              },
              {
                icon: 'chart-bar',
                label: 'Statistics',
                onPress: () => navigation.navigate('Stats'),
              },
              {
                icon: 'inbox',
                label: 'Scan Inbox',
                onPress: handleScanInbox,
              },
            ]}
            onStateChange={({ open }) => setFabOpen(open)}
          />
        </Portal>
      </View>
    </PaperProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  statsCard: {
    margin: 16,
    marginBottom: 8,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  spamText: {
    color: '#d32f2f',
  },
  hamText: {
    color: '#388e3c',
  },
  statusBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  statusText: {
    fontSize: 16,
    fontWeight: '500',
  },
  toggleButton: {
    minWidth: 100,
  },
  listContent: {
    padding: 16,
  },
  messageCard: {
    marginBottom: 12,
  },
  messageHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  sender: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  timestamp: {
    fontSize: 12,
    color: '#666',
  },
  messageBody: {
    fontSize: 14,
    marginBottom: 8,
  },
  messageFooter: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  chipSpam: {
    backgroundColor: '#ffebee',
  },
  chipHam: {
    backgroundColor: '#e8f5e9',
  },
  chipUnknown: {
    backgroundColor: '#fff3e0',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  emptyContainer: {
    padding: 32,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
});
