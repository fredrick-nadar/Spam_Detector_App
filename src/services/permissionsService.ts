import { Platform, Linking, Alert } from 'react-native';
import { SmsModule, PermissionResult } from '../native/SmsModule';
import { PermissionState, PermissionStatus } from '../types';

class PermissionsService {
  /**
   * Check current permission status
   */
  async checkPermissions(): Promise<PermissionState> {
    if (Platform.OS !== 'android') {
      return {
        readSms: 'denied',
        receiveSms: 'denied',
        sendSms: 'denied',
      };
    }

    try {
      const result = await SmsModule.checkPermissions();
      return this.mapPermissionResult(result);
    } catch (error) {
      console.error('Error checking permissions:', error);
      throw error;
    }
  }

  /**
   * Request SMS permissions
   */
  async requestPermissions(): Promise<PermissionState> {
    if (Platform.OS !== 'android') {
      Alert.alert(
        'Not Supported',
        'SMS monitoring is only available on Android devices.'
      );
      return {
        readSms: 'denied',
        receiveSms: 'denied',
        sendSms: 'denied',
      };
    }

    try {
      const result = await SmsModule.requestPermissions();
      return this.mapPermissionResult(result);
    } catch (error) {
      console.error('Error requesting permissions:', error);
      throw error;
    }
  }

  /**
   * Check if all required permissions are granted
   */
  async hasRequiredPermissions(): Promise<boolean> {
    const permissions = await this.checkPermissions();
    return (
      permissions.readSms === 'granted' && permissions.receiveSms === 'granted'
    );
  }

  /**
   * Request battery optimization exemption
   * This helps the app run in background without being killed
   */
  async requestBatteryOptimizationExemption(): Promise<void> {
    if (Platform.OS !== 'android') {
      return;
    }

    Alert.alert(
      'Battery Optimization',
      'To ensure reliable SMS monitoring, please disable battery optimization for this app.',
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Open Settings',
          onPress: () => {
            // Open battery optimization settings
            Linking.openSettings();
          },
        },
      ]
    );
  }

  /**
   * Show permission rationale
   */
  showPermissionRationale(): Promise<boolean> {
    return new Promise((resolve) => {
      Alert.alert(
        'SMS Permissions Required',
        'This app needs SMS permissions to:\n\n' +
          '• Read SMS messages for spam detection\n' +
          '• Receive new SMS in real-time\n' +
          '• Monitor incoming messages\n\n' +
          'Your messages are processed locally and never sent to external servers.',
        [
          {
            text: 'Cancel',
            style: 'cancel',
            onPress: () => resolve(false),
          },
          {
            text: 'Grant Permissions',
            onPress: () => resolve(true),
          },
        ]
      );
    });
  }

  /**
   * Open app settings
   */
  openAppSettings(): void {
    Linking.openSettings();
  }

  /**
   * Handle permission denied scenario
   */
  handlePermissionDenied(permission: string): void {
    Alert.alert(
      'Permission Denied',
      `The app needs ${permission} permission to function properly. Please enable it in app settings.`,
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Open Settings',
          onPress: () => this.openAppSettings(),
        },
      ]
    );
  }

  /**
   * Map native permission result to app permission state
   */
  private mapPermissionResult(result: PermissionResult): PermissionState {
    return {
      readSms: this.mapPermissionStatus(result.readSms),
      receiveSms: this.mapPermissionStatus(result.receiveSms),
      sendSms: this.mapPermissionStatus(result.sendSms),
    };
  }

  /**
   * Map permission string to PermissionStatus
   */
  private mapPermissionStatus(status: string): PermissionStatus {
    switch (status) {
      case 'granted':
        return 'granted';
      case 'denied':
        return 'denied';
      default:
        return 'not_requested';
    }
  }
}

// Export singleton instance
export const permissionsService = new PermissionsService();
