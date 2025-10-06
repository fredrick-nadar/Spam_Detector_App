import React, { useState, useEffect, useCallback } from 'react';
import { View, ScrollView, StyleSheet, RefreshControl } from 'react-native';
import {
  Appbar,
  Card,
  Title,
  Paragraph,
  Button,
  Chip,
  DataTable,
  Searchbar,
  Menu,
  Divider,
  Text,
  Portal,
  Dialog,
} from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import { databaseService } from '../services/databaseService';
import { SMSMessage } from '../types';
import { formatTimestamp } from '../utils/helpers';

export const DatabaseViewerScreen: React.FC = () => {
  const navigation = useNavigation();
  const [messages, setMessages] = useState<SMSMessage[]>([]);
  const [filteredMessages, setFilteredMessages] = useState<SMSMessage[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'spam' | 'ham' | 'unclassified'>('all');
  const [sortBy, setSortBy] = useState<'date' | 'sender' | 'classification'>('date');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [menuVisible, setMenuVisible] = useState(false);
  const [selectedMessage, setSelectedMessage] = useState<SMSMessage | null>(null);
  const [detailsVisible, setDetailsVisible] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);

  // Load messages from database
  const loadMessages = useCallback(async () => {
    try {
      setLoading(true);
      const allMessages = await databaseService.getAllMessages();
      setMessages(allMessages);
      applyFilters(allMessages, searchQuery, filterType, sortBy, sortOrder);
    } catch (error) {
      console.error('Failed to load messages:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [searchQuery, filterType, sortBy, sortOrder]);

  useEffect(() => {
    loadMessages();
  }, []);

  // Apply filters and sorting
  const applyFilters = (
    msgs: SMSMessage[],
    search: string,
    filter: typeof filterType,
    sort: typeof sortBy,
    order: typeof sortOrder
  ) => {
    let filtered = [...msgs];

    // Apply search filter
    if (search) {
      const query = search.toLowerCase();
      filtered = filtered.filter(
        msg =>
          msg.body.toLowerCase().includes(query) ||
          msg.sender.toLowerCase().includes(query) ||
          (msg.reason && msg.reason.toLowerCase().includes(query))
      );
    }

    // Apply classification filter
    if (filter !== 'all') {
      if (filter === 'spam') {
        filtered = filtered.filter(msg => msg.isSpam === true);
      } else if (filter === 'ham') {
        filtered = filtered.filter(msg => msg.isSpam === false);
      } else if (filter === 'unclassified') {
        filtered = filtered.filter(msg => msg.isSpam === null);
      }
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let comparison = 0;
      
      if (sort === 'date') {
        comparison = a.timestamp - b.timestamp;
      } else if (sort === 'sender') {
        comparison = a.sender.localeCompare(b.sender);
      } else if (sort === 'classification') {
        const aClass = a.isSpam === null ? 'unknown' : a.isSpam ? 'spam' : 'ham';
        const bClass = b.isSpam === null ? 'unknown' : b.isSpam ? 'spam' : 'ham';
        comparison = aClass.localeCompare(bClass);
      }

      return order === 'asc' ? comparison : -comparison;
    });

    setFilteredMessages(filtered);
  };

  // Handle search
  const handleSearch = (query: string) => {
    setSearchQuery(query);
    applyFilters(messages, query, filterType, sortBy, sortOrder);
  };

  // Handle filter change
  const handleFilterChange = (filter: typeof filterType) => {
    setFilterType(filter);
    applyFilters(messages, searchQuery, filter, sortBy, sortOrder);
  };

  // Handle sort change
  const handleSortChange = (sort: typeof sortBy) => {
    const newOrder = sort === sortBy && sortOrder === 'desc' ? 'asc' : 'desc';
    setSortBy(sort);
    setSortOrder(newOrder);
    applyFilters(messages, searchQuery, filterType, sort, newOrder);
  };

  // Handle refresh
  const onRefresh = useCallback(() => {
    setRefreshing(true);
    loadMessages();
  }, [loadMessages]);

  // Show message details
  const showDetails = (message: SMSMessage) => {
    setSelectedMessage(message);
    setDetailsVisible(true);
  };

  // Delete message
  const handleDelete = async (message: SMSMessage) => {
    try {
      await databaseService.deleteMessage(message.id);
      await loadMessages();
      setDetailsVisible(false);
    } catch (error) {
      console.error('Failed to delete message:', error);
    }
  };

  // Clear all messages
  const handleClearAll = async () => {
    try {
      for (const msg of messages) {
        await databaseService.deleteMessage(msg.id);
      }
      await loadMessages();
    } catch (error) {
      console.error('Failed to clear messages:', error);
    }
  };

  // Helper to get classification string
  const getClassification = (message: SMSMessage): string => {
    if (message.isSpam === null) return 'unknown';
    return message.isSpam ? 'spam' : 'ham';
  };

  // Get classification chip color
  const getChipColor = (classification: string) => {
    switch (classification) {
      case 'spam':
        return '#ffcdd2';
      case 'ham':
        return '#c8e6c9';
      default:
        return '#e0e0e0';
    }
  };

  // Get classification icon
  const getChipIcon = (classification: string) => {
    switch (classification) {
      case 'spam':
        return 'alert-circle';
      case 'ham':
        return 'check-circle';
      default:
        return 'help-circle';
    }
  };

  return (
    <View style={styles.container}>
      {/* App Bar */}
      <Appbar.Header>
        <Appbar.BackAction onPress={() => navigation.goBack()} />
        <Appbar.Content title="Database Viewer" />
        <Appbar.Action
          icon="refresh"
          onPress={onRefresh}
          disabled={refreshing}
        />
        <Appbar.Action
          icon="dots-vertical"
          onPress={() => setMenuVisible(true)}
        />
      </Appbar.Header>

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Search Bar */}
        <Searchbar
          placeholder="Search messages..."
          onChangeText={handleSearch}
          value={searchQuery}
          style={styles.searchBar}
        />

        {/* Filter Chips */}
        <View style={styles.filterContainer}>
          <Chip
            selected={filterType === 'all'}
            onPress={() => handleFilterChange('all')}
            style={styles.filterChip}
          >
            All ({messages.length})
          </Chip>
          <Chip
            selected={filterType === 'spam'}
            onPress={() => handleFilterChange('spam')}
            style={styles.filterChip}
          >
            Spam ({messages.filter(m => m.isSpam === true).length})
          </Chip>
          <Chip
            selected={filterType === 'ham'}
            onPress={() => handleFilterChange('ham')}
            style={styles.filterChip}
          >
            Ham ({messages.filter(m => m.isSpam === false).length})
          </Chip>
          <Chip
            selected={filterType === 'unclassified'}
            onPress={() => handleFilterChange('unclassified')}
            style={styles.filterChip}
          >
            Unknown ({messages.filter(m => m.isSpam === null).length})
          </Chip>
        </View>

        {/* Sort Options */}
        <View style={styles.sortContainer}>
          <Text style={styles.sortLabel}>Sort by:</Text>
          <Button
            mode={sortBy === 'date' ? 'contained' : 'outlined'}
            onPress={() => handleSortChange('date')}
            style={styles.sortButton}
            compact
          >
            Date {sortBy === 'date' && (sortOrder === 'desc' ? '↓' : '↑')}
          </Button>
          <Button
            mode={sortBy === 'sender' ? 'contained' : 'outlined'}
            onPress={() => handleSortChange('sender')}
            style={styles.sortButton}
            compact
          >
            Sender {sortBy === 'sender' && (sortOrder === 'desc' ? '↓' : '↑')}
          </Button>
          <Button
            mode={sortBy === 'classification' ? 'contained' : 'outlined'}
            onPress={() => handleSortChange('classification')}
            style={styles.sortButton}
            compact
          >
            Type {sortBy === 'classification' && (sortOrder === 'desc' ? '↓' : '↑')}
          </Button>
        </View>

        {/* Messages List */}
        {loading ? (
          <Card style={styles.card}>
            <Card.Content>
              <Paragraph>Loading messages...</Paragraph>
            </Card.Content>
          </Card>
        ) : filteredMessages.length === 0 ? (
          <Card style={styles.card}>
            <Card.Content>
              <Paragraph>No messages found.</Paragraph>
            </Card.Content>
          </Card>
        ) : (
          filteredMessages.map(message => {
            const classification = getClassification(message);
            return (
              <Card
                key={message.id}
                style={styles.messageCard}
                onPress={() => showDetails(message)}
              >
                <Card.Content>
                  <View style={styles.messageHeader}>
                    <Text style={styles.sender}>{message.sender}</Text>
                    <Chip
                      icon={getChipIcon(classification)}
                      style={{ backgroundColor: getChipColor(classification) }}
                      textStyle={styles.chipText}
                    >
                      {classification}
                    </Chip>
                  </View>
                  <Paragraph style={styles.messageBody} numberOfLines={2}>
                    {message.body}
                  </Paragraph>
                  <Text style={styles.timestamp}>
                    {formatTimestamp(message.timestamp)}
                  </Text>
                  {message.confidence !== undefined && (
                    <Text style={styles.confidence}>
                      Confidence: {Math.round(message.confidence * 100)}%
                    </Text>
                  )}
                </Card.Content>
              </Card>
            );
          })
        )}

        {/* Stats Summary */}
        <Card style={styles.card}>
          <Card.Content>
            <Title>Database Summary</Title>
            <Divider style={styles.divider} />
            <DataTable>
              <DataTable.Row>
                <DataTable.Cell>Total Messages</DataTable.Cell>
                <DataTable.Cell numeric>{messages.length}</DataTable.Cell>
              </DataTable.Row>
              <DataTable.Row>
                <DataTable.Cell>Spam</DataTable.Cell>
                <DataTable.Cell numeric>
                  {messages.filter(m => m.isSpam === true).length}
                </DataTable.Cell>
              </DataTable.Row>
              <DataTable.Row>
                <DataTable.Cell>Ham (Legitimate)</DataTable.Cell>
                <DataTable.Cell numeric>
                  {messages.filter(m => m.isSpam === false).length}
                </DataTable.Cell>
              </DataTable.Row>
              <DataTable.Row>
                <DataTable.Cell>Unclassified</DataTable.Cell>
                <DataTable.Cell numeric>
                  {messages.filter(m => m.isSpam === null).length}
                </DataTable.Cell>
              </DataTable.Row>
            </DataTable>
          </Card.Content>
        </Card>
      </ScrollView>

      {/* Menu */}
      <Portal>
        <Menu
          visible={menuVisible}
          onDismiss={() => setMenuVisible(false)}
          anchor={{ x: 1000, y: 50 }}
        >
          <Menu.Item
            onPress={() => {
              setMenuVisible(false);
              handleClearAll();
            }}
            title="Clear All Messages"
            leadingIcon="delete"
          />
          <Divider />
          <Menu.Item
            onPress={() => {
              setMenuVisible(false);
              onRefresh();
            }}
            title="Refresh"
            leadingIcon="refresh"
          />
        </Menu>
      </Portal>

      {/* Message Details Dialog */}
      <Portal>
        <Dialog
          visible={detailsVisible}
          onDismiss={() => setDetailsVisible(false)}
        >
          <Dialog.Title>Message Details</Dialog.Title>
          <Dialog.Content>
            {selectedMessage && (
              <View>
                <Text style={styles.detailLabel}>ID:</Text>
                <Text style={styles.detailValue}>{selectedMessage.id}</Text>

                <Text style={styles.detailLabel}>From:</Text>
                <Text style={styles.detailValue}>{selectedMessage.sender}</Text>

                <Text style={styles.detailLabel}>Date:</Text>
                <Text style={styles.detailValue}>
                  {formatTimestamp(selectedMessage.timestamp)}
                </Text>

                <Text style={styles.detailLabel}>Classification:</Text>
                <Chip
                  icon={getChipIcon(getClassification(selectedMessage))}
                  style={{
                    backgroundColor: getChipColor(getClassification(selectedMessage)),
                    alignSelf: 'flex-start',
                    marginBottom: 12,
                  }}
                >
                  {getClassification(selectedMessage)}
                </Chip>

                {selectedMessage.confidence !== undefined && (
                  <>
                    <Text style={styles.detailLabel}>Confidence:</Text>
                    <Text style={styles.detailValue}>
                      {Math.round(selectedMessage.confidence * 100)}%
                    </Text>
                  </>
                )}

                {selectedMessage.reason && (
                  <>
                    <Text style={styles.detailLabel}>Reason:</Text>
                    <Text style={styles.detailValue}>{selectedMessage.reason}</Text>
                  </>
                )}

                <Text style={styles.detailLabel}>Message:</Text>
                <Text style={styles.detailValue}>{selectedMessage.body}</Text>
              </View>
            )}
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setDetailsVisible(false)}>Close</Button>
            <Button
              onPress={() => selectedMessage && handleDelete(selectedMessage)}
              textColor="#f44336"
            >
              Delete
            </Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  searchBar: {
    marginBottom: 16,
  },
  filterContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 16,
    gap: 8,
  },
  filterChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  sortContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    flexWrap: 'wrap',
  },
  sortLabel: {
    marginRight: 8,
    fontWeight: 'bold',
  },
  sortButton: {
    marginRight: 8,
  },
  card: {
    marginBottom: 16,
  },
  messageCard: {
    marginBottom: 12,
  },
  messageHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  sender: {
    fontWeight: 'bold',
    fontSize: 16,
    flex: 1,
  },
  chipText: {
    fontSize: 12,
  },
  messageBody: {
    marginBottom: 8,
    color: '#666',
  },
  timestamp: {
    fontSize: 12,
    color: '#999',
  },
  confidence: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  divider: {
    marginVertical: 12,
  },
  detailLabel: {
    fontWeight: 'bold',
    marginTop: 12,
    marginBottom: 4,
  },
  detailValue: {
    marginBottom: 8,
  },
});
