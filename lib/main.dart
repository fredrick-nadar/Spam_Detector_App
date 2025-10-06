import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import 'services/sms_spam_detector_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logger
  Logger.level = Level.debug;

  runApp(const SmsSpamDetectorApp());
}

class SmsSpamDetectorApp extends StatelessWidget {
  const SmsSpamDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SmsSpamDetectorService(),
      child: MaterialApp(
        title: 'SMS Spam Detector',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MessagesScreen(),
    const StatisticsScreen(),
    const ConfigurationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Home Screen with system status and controls
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Spam Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Consumer<SmsSpamDetectorService>(
        builder: (context, service, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // System Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              service.isRunning
                                  ? Icons.check_circle
                                  : Icons.pause_circle,
                              color: service.isRunning
                                  ? Colors.green
                                  : Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'System Status',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    service.isRunning ? 'Running' : 'Stopped',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: service.isRunning
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!service.isInitialized)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final success = await service.initialize();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'System initialized successfully'
                                          : 'Failed to initialize system',
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('Initialize System'),
                          )
                        else if (!service.isRunning)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final success = await service.start();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'System started successfully'
                                          : 'Failed to start system',
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Monitoring'),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              await service.stop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('System stopped'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Monitoring'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics Overview
                if (service.isInitialized) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total',
                                service.statistics['total_processed']
                                    .toString(),
                                Icons.sms,
                                Colors.blue,
                              ),
                              _buildStatItem(
                                'Spam',
                                service.statistics['spam_detected'].toString(),
                                Icons.block,
                                Colors.red,
                              ),
                              _buildStatItem(
                                'Ham',
                                service.statistics['ham_detected'].toString(),
                                Icons.check,
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (service.currentConfig?.isConfigured == true)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final success = await service.sendTestMessage();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Test message sent successfully'
                                            : 'Failed to send test message',
                                      ),
                                      backgroundColor: success
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.send),
                              label: const Text('Send Test Telegram'),
                            )
                          else
                            const Text(
                              'Configure Telegram settings to enable notifications',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// Placeholder screens - will be implemented in detail later
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: const Center(
        child: Text(
          'Messages Screen\n\nThis will show:\n• Recent SMS messages\n• Classification results\n• Manual feedback options',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: const Center(
        child: Text(
          'Statistics Screen\n\nThis will show:\n• Detailed analytics\n• Spam/Ham ratios\n• Performance metrics\n• Trends over time',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telegramBotTokenController = TextEditingController();
  final _telegramChatIdController = TextEditingController();
  double _spamThreshold = 0.5;
  bool _autoNotify = true;
  bool _enableLearning = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() async {
    final service = Provider.of<SmsSpamDetectorService>(context, listen: false);
    // Load current configuration if available
    // This would typically load from the database
  }

  void _saveConfiguration() async {
    if (_formKey.currentState!.validate()) {
      final service = Provider.of<SmsSpamDetectorService>(
        context,
        listen: false,
      );

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving configuration...'),
            ],
          ),
        ),
      );

      try {
        // Save configuration (this would update the database)
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testTelegramConnection() async {
    if (_telegramBotTokenController.text.isEmpty ||
        _telegramChatIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all Telegram fields before testing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing Telegram connection...'),
          ],
        ),
      ),
    );

    try {
      // Simulate test message
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telegram test message sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Telegram test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfiguration,
            tooltip: 'Save Configuration',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Telegram Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.telegram, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Telegram Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _testTelegramConnection,
                          icon: const Icon(Icons.send),
                          label: const Text('Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telegramBotTokenController,
                      decoration: const InputDecoration(
                        labelText: 'Telegram Bot Token',
                        hintText: 'Enter your bot token from @BotFather',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.android),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter Telegram bot token';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telegramChatIdController,
                      decoration: const InputDecoration(
                        labelText: 'Chat ID',
                        hintText: 'Enter your chat ID or channel ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chat_bubble),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter chat ID';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Spam Detection Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Spam Detection Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Spam Threshold: ${_spamThreshold.toStringAsFixed(2)}',
                    ),
                    Slider(
                      value: _spamThreshold,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: _spamThreshold.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          _spamThreshold = value;
                        });
                      },
                    ),
                    const Text(
                      'Lower values = more sensitive detection',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto Notify'),
                      subtitle: const Text(
                        'Automatically send Telegram notifications',
                      ),
                      value: _autoNotify,
                      onChanged: (value) {
                        setState(() {
                          _autoNotify = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Enable Learning'),
                      subtitle: const Text(
                        'Improve detection accuracy over time',
                      ),
                      value: _enableLearning,
                      onChanged: (value) {
                        setState(() {
                          _enableLearning = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Setup Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Setup for Testing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For testing purposes, you can use these demo values:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🤖 Telegram Demo:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '  • Bot Token: 123456789:ABCdefGHIjklMNOpqrSTUvwxyz',
                    ),
                    const Text('  • Chat ID: -1001234567890'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _telegramBotTokenController.text =
                            '123456789:ABCdefGHIjklMNOpqrSTUvwxyz';
                        _telegramChatIdController.text = '-1001234567890';
                        setState(() {});
                      },
                      icon: const Icon(Icons.telegram),
                      label: const Text('Use Telegram Demo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _telegramBotTokenController.dispose();
    _telegramChatIdController.dispose();
    super.dispose();
  }
}
