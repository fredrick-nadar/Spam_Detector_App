# 🎯 CONFIGURATION SUMMARY - Where to Put Everything

## 📍 **Quick Answer: Where Do API Keys Go?**

### ✅ **In the App Settings (Recommended)**

1. Install app on your Android device
2. Open the app
3. Tap **Settings** tab (bottom right icon)
4. Enter your keys in the appropriate fields:

```
┌──────────────────────────────────────────────────┐
│  SETTINGS TAB                                    │
├──────────────────────────────────────────────────┤
│                                                  │
│  📱 TELEGRAM CONFIGURATION                       │
│  ├─ Bot Token: [Paste here]___________________  │
│  └─ Chat ID:   [Paste here]___________________  │
│                                                  │
│  🤖 AI CONFIGURATION                             │
│  └─ Gemini API Key: [Paste here]______________  │
│                                                  │
│  ⚙️ OPTIONS                                      │
│  ├─ ☑ Auto Notify                               │
│  ├─ ☑ Enable AI Keywords                        │
│  ├─ ☑ Enable Learning                           │
│  └─ ☐ Notify Only Spam                          │
│                                                  │
│  📊 ADVANCED                                     │
│  ├─ Spam Threshold: 0.5 (50%)                   │
│  └─ Max Keywords Per SMS: 10                    │
│                                                  │
│  [💾 Save Configuration]                         │
│  [📤 Test Telegram Connection]                   │
└──────────────────────────────────────────────────┘
```

5. Tap **Save** button
6. Tap **Test Connection** to verify

---

## 🔑 **How to Get Your API Keys**

### 1. Gemini API Key (Google AI)

**URL**: https://makersuite.google.com/app/apikey

**Steps**:
1. Visit the URL
2. Sign in with Google
3. Click "Create API Key"
4. Copy the key (starts with `AIza...`)

**Format**: `AIzaSyDXXXXXXXXXXXXXXXXXXXXXXXX`

### 2. Telegram Bot Token

**Create Bot**:
1. Open Telegram
2. Search `@BotFather`
3. Send `/newbot`
4. Follow prompts
5. Copy the token

**Format**: `123456789:ABCdefGHIjklMNOpqrsT...`

### 3. Telegram Chat ID

**Method 1 (Easiest)**:
1. Search `@userinfobot` in Telegram
2. Send `/start`
3. Copy your ID number

**Format**: `123456789` (just numbers)

---

## 📱 **How to Run End-to-End**

### Phase 1: Preparation (5 minutes)

```powershell
# 1. Navigate to project
cd D:\Programming\Flutter_Test\nlp

# 2. Fix corrupted SMS monitoring file
Remove-Item "lib\services\sms_monitoring_service.dart" -Force

# 3. Create new file and paste code from COMPLETE_SETUP_GUIDE.md Part 2
# (Use your code editor to create the file)

# 4. Install dependencies
flutter pub get

# 5. Generate code files
flutter pub run build_runner build --delete-conflicting-outputs

# 6. Check for errors
flutter analyze
```

### Phase 2: Get API Keys (10 minutes)

1. **Gemini API**:
   - Visit: https://makersuite.google.com/app/apikey
   - Create key
   - Copy: `AIza...`

2. **Telegram Bot**:
   - Message @BotFather
   - Create bot
   - Copy token: `123456789:ABC...`

3. **Chat ID**:
   - Message @userinfobot
   - Get ID: `123456789`

### Phase 3: Build & Install (5 minutes)

```powershell
# 1. Connect Android device via USB
# 2. Enable USB debugging on device
# 3. Verify connection
flutter devices

# 4. Build and run
flutter run

# App will install and launch on your device
```

### Phase 4: Configure App (5 minutes)

**On Your Device**:

1. **Grant Permissions**:
   - Allow SMS ✅
   - Allow Phone ✅
   - Allow Storage ✅

2. **Open Settings Tab**:
   - Tap Settings icon (bottom right)

3. **Enter Telegram Config**:
   ```
   Bot Token: [Paste: 123456789:ABCdefGHIjkl...]
   Chat ID:   [Paste: 123456789]
   ```

4. **Enter Gemini API Key**:
   ```
   API Key: [Paste: AIzaSyDXXXXXXXX...]
   ```

5. **Enable Options**:
   - ☑ Auto Notify
   - ☑ Enable AI Keywords
   - ☑ Enable Learning

6. **Save & Test**:
   - Tap "Save"
   - Tap "Test Connection"
   - Check Telegram for test message ✅

### Phase 5: Start System (2 minutes)

1. **Go to Home Tab**
2. **Tap "Initialize System"** → Wait for success
3. **Tap "Start Monitoring"** → Status: Running ✅

### Phase 6: Test End-to-End (5 minutes)

1. **Send Test SMS** from another phone:
   ```
   URGENT! You've won $1000! Click: bit.ly/fake
   ```

2. **Wait 5-10 seconds**

3. **Check Results**:
   
   ✅ **In Telegram**:
   ```
   🚨 SPAM DETECTED
   
   📱 From: +1234567890
   📄 Message: URGENT! You've won $1000...
   🎯 Classification: SPAM
   📊 Confidence: 89.5%
   🔍 Keywords: urgent, won, click
   ```

   ✅ **In App (Messages Tab)**:
   - SMS listed with SPAM tag
   - Confidence score visible
   - Keywords shown

   ✅ **In App (Home Tab)**:
   - Messages Processed: 1
   - Spam Detected: 1
   - Last Processed: Just now

---

## 🔄 **Complete Data Flow**

```
┌──────────────────────────────────────────────────┐
│ 1. INCOMING SMS                                  │
│    +1234567890: "URGENT! Win $1000..."          │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 2. APP RECEIVES (via telephony plugin)          │
│    • Copies to local database                   │
│    • Marks as unclassified                      │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 3. NLP PREPROCESSING                             │
│    • Tokenize: [urgent, win, 1000]              │
│    • Features: {urls:1, caps:0.2, $:1}          │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 4. GEMINI AI ANALYSIS                            │
│    YOUR GEMINI API KEY USED HERE ←─────────┐    │
│    • Extract keywords: urgent, won, fake    │    │
│    • Spam probability: 0.92                 │    │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 5. CLASSIFICATION                                │
│    • Rule score: 0.7                             │
│    • Keyword score: 0.85                         │
│    • AI score: 0.92                              │
│    • Final: SPAM (0.89)                          │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 6. STORE IN DATABASE                             │
│    • Update SMS: classification=SPAM             │
│    • Save keywords: urgent, won, click           │
│    • Store confidence: 0.89                      │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 7. SEND TELEGRAM NOTIFICATION                    │
│    YOUR BOT TOKEN & CHAT ID USED HERE ←────┐    │
│    • Format message with details            │    │
│    • Send via Telegram API                  │    │
│    • You receive notification               │    │
└──────────────────────────────────────────────────┘
```

---

## 📊 **Where Data is Stored**

### On Your Device:

**Database Location**:
```
/data/data/com.example.nlp/databases/sms_spam_detector.db
```

**Tables**:

1. **sms_messages** - All SMS data
   ```
   - id, sender, body, timestamp
   - classification, confidence
   - detected_keywords
   ```

2. **spam_keywords** - AI-extracted keywords
   ```
   - keyword, weight, frequency
   - source (gemini_ai)
   - created_at, last_seen
   ```

3. **classifications** - Detailed results
   ```
   - sms_id, classification
   - confidence, model_version
   ```

4. **app_config** - Your settings
   ```
   - telegram_bot_token ← YOUR TOKEN
   - telegram_chat_id   ← YOUR CHAT ID
   - gemini_api_key     ← YOUR API KEY
   - spam_threshold, auto_notify
   - enable_ai_keywords
   ```

**Security**: All encrypted by Android's built-in security.

---

## 🔐 **Security Best Practices**

### ✅ DO:

- Store API keys in app settings
- Use app's secure storage
- Enable Android encryption
- Keep keys private

### ❌ DON'T:

- Commit keys to GitHub
- Share keys publicly
- Hardcode in source files
- Send keys via unsecured channels

### If Keys Compromised:

1. **Gemini**: Generate new key at https://makersuite.google.com/app/apikey
2. **Telegram**: Message @BotFather → `/mybots` → Revoke token
3. Update in app settings
4. Save again

---

## ✅ **Verification Checklist**

After configuration, verify:

```
Configuration Status:
├─ [ ] Gemini API Key entered
├─ [ ] Telegram Bot Token entered
├─ [ ] Telegram Chat ID entered
├─ [ ] Test message received on Telegram
├─ [ ] All permissions granted
└─ [ ] Settings saved successfully

System Status:
├─ [ ] System initialized
├─ [ ] Monitoring started
├─ [ ] Status shows "Running"
└─ [ ] No error messages

Test Results:
├─ [ ] Test SMS sent
├─ [ ] SMS classified (SPAM/HAM)
├─ [ ] Telegram notification received
├─ [ ] Keywords visible in app
└─ [ ] Database updated

Ready to Use: [ ]
```

---

## 🆘 **Troubleshooting Config Issues**

### "Failed to initialize"
→ Check all three API keys are entered correctly

### "Telegram unauthorized"
→ Verify bot token has no spaces before/after

### "Gemini API error"
→ Check API key is valid, billing enabled

### "No permissions"
→ Settings → Apps → SMS Spam Detector → Permissions

### "Configuration not saved"
→ Tap Save button, wait for confirmation

---

## 📞 **Quick Support**

### Check Logs:
```powershell
flutter logs
```

### Look for:
- "Configuration saved successfully" ✅
- "Gemini API initialized" ✅
- "Telegram service initialized" ✅
- "SMS monitoring started" ✅

### Common Errors:
- "Invalid API key" → Check Gemini key
- "Unauthorized" → Check Telegram token
- "Permission denied" → Grant SMS permission

---

## 🎯 **Final Answer to Your Question**

### **Where to put API keys?**

👉 **In the app's Settings tab** after installing

### **How to run end-to-end?**

1. Fix corrupted file (see COMPLETE_SETUP_GUIDE.md Part 2)
2. Run `flutter pub get`
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`
4. Run `flutter run` on connected device
5. Grant permissions in app
6. Enter API keys in Settings tab
7. Save configuration
8. Test connection
9. Initialize system
10. Start monitoring
11. Send test SMS
12. Check Telegram notification ✅

**Total Time**: ~30 minutes first time, ~5 minutes after that

---

## 📚 **Additional Resources**

- **Complete Setup**: See `COMPLETE_SETUP_GUIDE.md`
- **Telegram Bot**: See `TELEGRAM_BOT_SETUP.md`
- **Quick Ref**: See `QUICK_REFERENCE.md`
- **Architecture**: See `SMS_FLOW_IMPLEMENTATION.md`
- **Features**: See `IMPLEMENTATION_GUIDE.md`

---

**You're All Set! 🎉**

Everything is documented and ready to use. Just follow the steps above!
