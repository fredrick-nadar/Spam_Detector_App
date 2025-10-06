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

  // Safe calculations with fallbacks to prevent NaN
  const safeTotal = stats.totalMessages || 0;
  const safeSpam = stats.spamCount || 0;
  const safeHam = stats.hamCount || 0;
  const safeUnclassified = stats.unclassifiedCount || 0;

  const spamRate = safeTotal > 0 ? safeSpam / safeTotal : 0;
  const hamRate = safeTotal > 0 ? safeHam / safeTotal : 0;
  const unclassifiedRate = safeTotal > 0 ? safeUnclassified / safeTotal : 0;

  // Ensure rates are valid numbers
  const validSpamRate = isNaN(spamRate) ? 0 : spamRate;
  const validHamRate = isNaN(hamRate) ? 0 : hamRate;
  const validUnclassifiedRate = isNaN(unclassifiedRate) ? 0 : unclassifiedRate;

  return (
    <ScrollView style={styles.container}>
      {/* Overview Card */}
      <Card style={styles.card}>
        <Card.Content>
          <Title>Overview</Title>
          <View style={styles.overviewRow}>
            <View style={styles.overviewItem}>
              <Text style={styles.overviewLabel}>Total Messages</Text>
              <Text style={styles.overviewValue}>{safeTotal}</Text>
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
              <DataTable.Cell numeric>{safeSpam}</DataTable.Cell>
              <DataTable.Cell numeric>
                <Text style={styles.spamText}>{formatPercentage(validSpamRate)}</Text>
              </DataTable.Cell>
            </DataTable.Row>

            <DataTable.Row>
              <DataTable.Cell>Ham (Not Spam)</DataTable.Cell>
              <DataTable.Cell numeric>{safeHam}</DataTable.Cell>
              <DataTable.Cell numeric>
                <Text style={styles.hamText}>{formatPercentage(validHamRate)}</Text>
              </DataTable.Cell>
            </DataTable.Row>

            <DataTable.Row>
              <DataTable.Cell>Unclassified</DataTable.Cell>
              <DataTable.Cell numeric>{safeUnclassified}</DataTable.Cell>
              <DataTable.Cell numeric>
                <Text style={styles.unknownText}>
                  {formatPercentage(validUnclassifiedRate)}
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
                  { width: `${Math.min(validSpamRate * 100, 100)}%` },
                ]}
              />
            </View>
            <Text style={styles.rateText}>
              {formatPercentage(validSpamRate, 2)} of messages are spam
            </Text>
          </View>

          {safeSpam > 0 && (
            <Paragraph style={styles.insightText}>
              💡 Your inbox receives spam messages regularly. The detector is
              actively protecting you!
            </Paragraph>
          )}

          {safeSpam === 0 && safeTotal > 0 && (
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
              {formatTimestamp(stats.lastUpdated || Date.now())}
            </Text>
          </View>

          {safeTotal > 0 && (
            <>
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Classification Status:</Text>
                <Text style={styles.infoValue}>
                  {safeUnclassified === 0
                    ? 'All messages classified'
                    : `${safeUnclassified} pending`}
                </Text>
              </View>

              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Detection Accuracy:</Text>
                <Text style={styles.infoValue}>
                  {safeUnclassified === 0
                    ? '100% classified'
                    : formatPercentage(
                        (safeTotal - safeUnclassified) / safeTotal
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
