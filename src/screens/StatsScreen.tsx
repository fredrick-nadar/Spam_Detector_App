import React, { useEffect } from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import { Card, Title, Paragraph, DataTable, Text } from 'react-native-paper';
import { useAppStore } from '../store/appStore';
import { databaseService } from '../services/databaseService';
import { formatPercentage, formatTimestamp } from '../utils/helpers';

export default function StatsScreen() {
  const { stats, setStats } = useAppStore();

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const newStats = await databaseService.getStats();
      setStats(newStats);
    } catch (error) {
      console.error('Failed to load stats:', error);
    }
  };

  const spamRate =
    stats.totalMessages > 0 ? stats.spamCount / stats.totalMessages : 0;
  const hamRate =
    stats.totalMessages > 0 ? stats.hamCount / stats.totalMessages : 0;
  const unclassifiedRate =
    stats.totalMessages > 0
      ? stats.unclassifiedCount / stats.totalMessages
      : 0;

  return (
    <ScrollView style={styles.container}>
      {/* Overview Card */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Overview</Title>
          <View style={styles.overviewRow}>
            <View style={styles.overviewItem}>
              <Text style={styles.overviewLabel}>Total Messages</Text>
              <Text style={styles.overviewValue}>{stats.totalMessages}</Text>
            </View>
          </View>
        </Card.Content>
      </Card>

      {/* Classification Breakdown */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Classification Breakdown</Title>
          <DataTable>
            <DataTable.Row>
              <DataTable.Cell>Spam</DataTable.Cell>
              <DataTable.Cell numeric>{stats.spamCount}</DataTable.Cell>
              <DataTable.Cell numeric>
                <Text style={styles.spamText}>{formatPercentage(spamRate)}</Text>
              </DataTable.Cell>
            </DataTable.Row>

            <DataTable.Row>
              <DataTable.Cell>Ham (Not Spam)</DataTable.Cell>
              <DataTable.Cell numeric>{stats.hamCount}</DataTable.Cell>
              <DataTable.Cell numeric>
                <Text style={styles.hamText}>{formatPercentage(hamRate)}</Text>
              </DataTable.Cell>
            </DataTable.Row>

            <DataTable.Row>
              <DataTable.Cell>Unclassified</DataTable.Cell>
              <DataTable.Cell numeric>{stats.unclassifiedCount}</DataTable.Cell>
              <DataTable.Cell numeric>
                <Text style={styles.unknownText}>
                  {formatPercentage(unclassifiedRate)}
                </Text>
              </DataTable.Cell>
            </DataTable.Row>
          </DataTable>
        </Card.Content>
      </Card>

      {/* Spam Detection Rate */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Spam Detection Rate</Title>
          <View style={styles.rateContainer}>
            <View style={styles.rateBar}>
              <View
                style={[
                  styles.rateBarFill,
                  styles.spamFill,
                  { width: `${spamRate * 100}%` },
                ]}
              />
            </View>
            <Text style={styles.rateText}>
              {formatPercentage(spamRate, 2)} of messages are spam
            </Text>
          </View>

          {stats.spamCount > 0 && (
            <Paragraph style={styles.insightText}>
              💡 Your inbox receives spam messages regularly. The detector is
              actively protecting you!
            </Paragraph>
          )}

          {stats.spamCount === 0 && stats.totalMessages > 0 && (
            <Paragraph style={styles.insightText}>
              ✅ Great! No spam detected in your messages so far.
            </Paragraph>
          )}
        </Card.Content>
      </Card>

      {/* Additional Stats */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Additional Information</Title>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Last Updated:</Text>
            <Text style={styles.infoValue}>
              {formatTimestamp(stats.lastUpdated)}
            </Text>
          </View>

          {stats.totalMessages > 0 && (
            <>
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Classification Status:</Text>
                <Text style={styles.infoValue}>
                  {stats.unclassifiedCount === 0
                    ? 'All messages classified'
                    : `${stats.unclassifiedCount} pending`}
                </Text>
              </View>

              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Detection Accuracy:</Text>
                <Text style={styles.infoValue}>
                  {stats.unclassifiedCount === 0
                    ? '100% classified'
                    : formatPercentage(
                        (stats.totalMessages - stats.unclassifiedCount) /
                          stats.totalMessages
                      )}
                </Text>
              </View>
            </>
          )}
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
  overviewRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 16,
  },
  overviewItem: {
    alignItems: 'center',
  },
  overviewLabel: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  overviewValue: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#6200ee',
  },
  spamText: {
    color: '#d32f2f',
    fontWeight: 'bold',
  },
  hamText: {
    color: '#388e3c',
    fontWeight: 'bold',
  },
  unknownText: {
    color: '#f57c00',
    fontWeight: 'bold',
  },
  rateContainer: {
    marginTop: 16,
  },
  rateBar: {
    height: 24,
    backgroundColor: '#e0e0e0',
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 8,
  },
  rateBarFill: {
    height: '100%',
  },
  spamFill: {
    backgroundColor: '#d32f2f',
  },
  rateText: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
  },
  insightText: {
    marginTop: 16,
    padding: 12,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    fontSize: 14,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  infoLabel: {
    fontSize: 14,
    color: '#666',
  },
  infoValue: {
    fontSize: 14,
    fontWeight: '500',
  },
});
