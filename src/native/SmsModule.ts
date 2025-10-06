import { NativeModules, NativeEventEmitter, Platform } from 'react-native';

interface SmsModuleInterface {
  requestPermissions(): Promise<PermissionResult>;
  checkPermissions(): Promise<PermissionResult>;
  getAllMessages(limit: number): Promise<NativeSmsMessage[]>;
  getMessagesSince(timestamp: number): Promise<NativeSmsMessage[]>;
}

export interface PermissionResult {
  readSms: 'granted' | 'denied';
  receiveSms: 'granted' | 'denied';
  sendSms: 'granted' | 'denied';
  readPhoneState: 'granted' | 'denied';
}

export interface NativeSmsMessage {
  id: string;
  sender: string;
  body: string;
  timestamp: number;
  read?: boolean;
}

export interface SmsReceivedEvent {
  sender: string;
  body: string;
  timestamp: number;
}

const LINKING_ERROR =
  `The package 'SmsModule' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// Get the native module
const SmsModule: SmsModuleInterface = NativeModules.SmsModule
  ? NativeModules.SmsModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

// Create event emitter for SMS events
const smsEventEmitter = new NativeEventEmitter(NativeModules.SmsModule);

export { SmsModule, smsEventEmitter };

// Event listener types
export type SmsReceivedListener = (event: SmsReceivedEvent) => void;

// Helper to add listener with proper typing
export function addSmsReceivedListener(listener: SmsReceivedListener) {
  return smsEventEmitter.addListener('onSmsReceived', listener);
}

// Helper to remove all listeners
export function removeAllSmsListeners() {
  smsEventEmitter.removeAllListeners('onSmsReceived');
}
