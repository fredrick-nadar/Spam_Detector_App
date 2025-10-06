# SMS Spam Detector RN

A production-ready React Native app for Android that monitors incoming SMS messages in real-time, classifies them as spam or ham using Google Gemini AI, stores messages in a local SQLite database, and sends Telegram notifications for detected spam.

## 🚀 Features

- **Real-time SMS Monitoring**: Broadcast receiver for instant SMS detection
- **AI-Powered Classification**: Google Gemini AI for intelligent spam detection
- **Offline-First**: All core functionality works without internet (with fallback keyword detection)
- **Local Database**: SQLite for efficient message storage and retrieval
- **Telegram Notifications**: Instant spam alerts via Telegram bot
- **Modern UI**: React Native Paper components with Material Design
- **Statistics Dashboard**: Track spam rates, detection accuracy, and more
- **Privacy-Focused**: All processing happens locally on device
- **Battery Optimized**: Efficient background processing

## 📋 Requirements

- **Platform**: Android API 24+ (Android 7.0+)
- **Development**: Node.js 18+, npm/yarn, Android Studio
- **API Keys**:
  - Google Gemini API Key ([Get it here](https://aistudio.google.com/app/apikey))
  - Telegram Bot Token (Create via [@BotFather](https://t.me/BotFather))
  - Telegram Chat ID (Get via [@userinfobot](https://t.me/userinfobot))

## 🛠️ Installation

### 1. Clone and Install Dependencies

\`\`\`bash
# Clone the repository
git clone <repository-url>
cd nlp

# Install dependencies
npm install
\`\`\`

### 2. Set Up Android Environment

\`\`\`bash
# Generate Android native files (if not already done)
npx expo prebuild --platform android

# Or use EAS Build for cloud builds
npx eas build --platform android --profile development
\`\`\`

### 3. Configure API Keys

1. Launch the app
2. Navigate to **Settings** (gear icon)
3. Enter your API keys:
   - **Gemini API Key**: From [Google AI Studio](https://aistudio.google.com/app/apikey)
   - **Telegram Bot Token**: From [@BotFather](https://t.me/BotFather)
   - **Telegram Chat ID**: From [@userinfobot](https://t.me/userinfobot)
4. Test connections before saving
5. Save configuration

## 🏃 Running the App

### Development Mode

\`\`\`bash
# Start Metro bundler
npx expo start

# Run on Android device/emulator
npx expo run:android

# Or use Expo Go (limited native features)
npx expo start --android
\`\`\`

### Production Build

\`\`\`bash
# Build APK
npx eas build --platform android --profile production

# Or build locally
cd android
./gradlew assembleRelease
\`\`\`

## 📱 Usage

### First Time Setup

1. **Grant Permissions**: The app will request SMS permissions on first launch
2. **Configure API Keys**: Go to Settings and enter all required credentials
3. **Test Connections**: Use test buttons to verify Gemini and Telegram work
4. **Start Monitoring**: Tap "Start" on home screen to begin real-time monitoring
5. **Scan Inbox** (Optional): Tap FAB menu → "Scan Inbox" to classify existing messages

### Daily Use

- **Monitoring**: Keep monitoring active for real-time spam detection
- **View Messages**: Home screen shows recent messages with spam/ham labels
- **Check Stats**: Tap "Statistics" to view spam rates and detection metrics
- **Notifications**: Spam messages trigger Telegram notifications automatically
- **Battery**: Add app to battery optimization whitelist for reliable background operation

## 🏗️ Architecture

### Project Structure

\`\`\`
src/
├── components/          # Reusable UI components
├── navigation/          # React Navigation setup
├── native/             # Native module bridges
│   └── SmsModule.ts    # Android SMS module interface
├── screens/            # App screens
│   ├── HomeScreen.tsx   # Main message list
│   ├── StatsScreen.tsx  # Analytics dashboard
│   └── ConfigScreen.tsx # Settings
├── services/           # Business logic
│   ├── classificationService.ts  # Gemini AI integration
│   ├── databaseService.ts       # SQLite operations
│   ├── permissionsService.ts    # Permission handling
│   ├── smsMonitoringService.ts  # SMS coordination
│   └── telegramService.ts       # Telegram notifications
├── store/              # Global state
│   └── appStore.ts     # Zustand store
├── types/              # TypeScript interfaces
│   └── index.ts
└── utils/              # Helper functions
    ├── helpers.ts
    └── textPreprocessing.ts

android/
└── app/src/main/java/com/spamdetector/rn/
    ├── MainActivity.kt
    ├── MainApplication.kt
    ├── SmsModule.kt      # Native SMS module
    ├── SmsPackage.kt     # React Native package
    └── SmsReceiver.kt    # Broadcast receiver
\`\`\`

### Core Components

#### 1. SMS Monitoring Service
- Coordinates all SMS-related operations
- Handles real-time broadcast receiver events
- Manages inbox scanning and batch classification
- Updates database and triggers notifications

#### 2. Classification Service
- Google Gemini AI integration
- Rate limiting (default 2s between calls)
- Fallback keyword-based detection
- Confidence scoring and reason generation

#### 3. Database Service
- SQLite for local storage
- Tables: \`sms_messages\`, \`notification_queue\`
- Indexed queries for performance
- CRUD operations with TypeScript types

#### 4. Telegram Service
- Sends spam notifications
- Offline queue with retry logic
- Batch summaries
- Test notification support

#### 5. Permissions Service
- Runtime permission requests
- Permission status checking
- Battery optimization guidance
- Settings navigation

## 🔐 Security & Privacy

- **Local Processing**: All SMS data stays on device
- **Secure Storage**: API keys stored in AsyncStorage (consider SecureStore for production)
- **No Analytics**: No telemetry or third-party tracking
- **Minimal Permissions**: Only requests necessary SMS permissions
- **Encrypted Transit**: API calls use HTTPS
- **User Control**: Users can disable monitoring anytime

## 🧪 Testing

### Manual Testing

1. **SMS Reception**:
   - Send test SMS to device
   - Verify real-time detection and classification
   - Check database storage

2. **Spam Detection**:
   - Send spam-like messages (e.g., "URGENT! You won $1000!")
   - Verify classification as spam
   - Check Telegram notification

3. **Offline Mode**:
   - Disable internet
   - Send SMS (should still be stored)
   - Re-enable internet (should classify and notify)

4. **Permissions**:
   - Revoke SMS permissions
   - Verify graceful error handling
   - Re-grant and verify recovery

### Emulator Testing

\`\`\`bash
# Send SMS via adb
adb emu sms send +1234567890 "Test message"

# Send spam SMS
adb emu sms send +1234567890 "URGENT! Win $1000 now! Click here!"

# Check logs
adb logcat | grep -E 'SmsReceiver|SmsModule'
\`\`\`

### Unit Tests (Future Enhancement)

\`\`\`bash
# Run tests
npm test

# Coverage
npm run test:coverage
\`\`\`

## 🐛 Troubleshooting

### SMS Not Being Detected

1. **Check Permissions**: Settings → Apps → SMS Spam Detector → Permissions
2. **Default SMS App**: Some devices require setting as default SMS app (not recommended)
3. **Battery Optimization**: Disable for this app in device settings
4. **Logs**: Use \`adb logcat\` to check for errors

### Classification Not Working

1. **API Key**: Verify Gemini API key is correct
2. **Internet**: Ensure device has internet connection
3. **Rate Limit**: Check if hitting API rate limits (increase delay in settings)
4. **Fallback**: App should use keyword detection if AI fails

### Telegram Notifications Not Sending

1. **Bot Token**: Verify token is correct (test in Settings)
2. **Chat ID**: Must match your Telegram user ID
3. **Bot Started**: Ensure you've sent /start to the bot
4. **Queue**: Check notification queue is being processed

### Build Errors

\`\`\`bash
# Clean build
cd android
./gradlew clean

# Rebuild
cd ..
npx expo prebuild --clean
npm run android
\`\`\`

## 📈 Performance Optimization

- **Rate Limiting**: Prevents API throttling (configurable)
- **Batch Processing**: Processes multiple messages efficiently
- **Indexed Queries**: Fast database lookups
- **Limited UI Updates**: Only shows last 50 messages
- **Background Processing**: Non-blocking classification
- **Lazy Loading**: Messages loaded on demand

## 🔮 Future Enhancements

- [ ] User-trainable ML model
- [ ] Whitelist/blacklist management
- [ ] Export message history
- [ ] Multiple classification models
- [ ] Auto-delete spam messages
- [ ] SMS reply automation
- [ ] Dark mode support
- [ ] Localization (i18n)
- [ ] Cloud sync (optional)
- [ ] iOS support (if possible)

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (\`git checkout -b feature/AmazingFeature\`)
3. Commit changes (\`git commit -m 'Add AmazingFeature'\`)
4. Push to branch (\`git push origin feature/AmazingFeature\`)
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Google Gemini AI for classification
- React Native & Expo teams
- React Native Paper for UI components
- Community contributors

## 📧 Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Contact: [Your Contact Info]

---

**Note**: This app is for educational purposes. Always comply with local laws regarding SMS monitoring and privacy.
