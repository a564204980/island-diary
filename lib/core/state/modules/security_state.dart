part of '../user_state.dart';

/// 4. 安全保障模块
mixin SecurityMixin on ProfileMixin {
  final ValueNotifier<bool> isAppLockEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> appLockPin = ValueNotifier<String>('');
  final ValueNotifier<bool> isBiometricEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMistModeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> destructionCode = ValueNotifier<String>('');
  final ValueNotifier<bool> isScreenshotProtected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isIntruderCaptureEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<int> autoLockDuration = ValueNotifier<int>(0);
  final ValueNotifier<String> appIconType = ValueNotifier<String>('default');
  final ValueNotifier<List<Map<String, dynamic>>> intruderLogs = ValueNotifier<List<Map<String, dynamic>>>([]);

  void loadSecurity(SharedPreferences prefs) {
    isAppLockEnabled.value = prefs.getBool(_K.isAppLockEnabled) ?? false;
    appLockPin.value = prefs.getString(_K.appLockPin) ?? '';
    isBiometricEnabled.value = prefs.getBool(_K.isBiometricEnabled) ?? false;
    isMistModeEnabled.value = prefs.getBool(_K.isMistModeEnabled) ?? false;
    destructionCode.value = prefs.getString(_K.destructionCode) ?? '';
    isScreenshotProtected.value = prefs.getBool(_K.isScreenshotProtected) ?? false;
    isIntruderCaptureEnabled.value = prefs.getBool(_K.isIntruderCaptureEnabled) ?? false;
    autoLockDuration.value = prefs.getInt(_K.autoLockDuration) ?? 0;
    appIconType.value = prefs.getString(_K.appIconType) ?? 'default';
    final l = prefs.getString(_K.intruderLogs);
    if (l != null) {
      try {
        intruderLogs.value = (jsonDecode(l) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
  }

  Future<void> updateSecuritySettings({bool? appLock, String? pin, bool? biometric, bool? mistMode, String? destCode}) async {
    final prefs = await SharedPreferences.getInstance();
    if (appLock != null) {
      isAppLockEnabled.value = appLock;
      await prefs.setBool(_K.isAppLockEnabled, appLock);
    }
    if (pin != null) {
      appLockPin.value = pin;
      await prefs.setString(_K.appLockPin, pin);
    }
    if (biometric != null) {
      isBiometricEnabled.value = biometric;
      await prefs.setBool(_K.isBiometricEnabled, biometric);
    }
    if (mistMode != null) {
      isMistModeEnabled.value = mistMode;
      await prefs.setBool(_K.isMistModeEnabled, mistMode);
    }
    if (destCode != null) {
      destructionCode.value = destCode;
      await prefs.setString(_K.destructionCode, destCode);
    }
  }

  Future<void> updateAdvancedSecurity({bool? screenshot, bool? intruder, int? lockDuration, String? iconType, Map<String, dynamic>? newIntruderLog}) async {
    final prefs = await SharedPreferences.getInstance();
    if (screenshot != null) {
      isScreenshotProtected.value = screenshot;
      await prefs.setBool(_K.isScreenshotProtected, screenshot);
    }
    if (intruder != null) {
      isIntruderCaptureEnabled.value = intruder;
      await prefs.setBool(_K.isIntruderCaptureEnabled, intruder);
    }
    if (lockDuration != null) {
      autoLockDuration.value = lockDuration;
      await prefs.setInt(_K.autoLockDuration, lockDuration);
    }
    if (iconType != null) {
      appIconType.value = iconType;
      await prefs.setString(_K.appIconType, iconType);
    }
    if (newIntruderLog != null) {
      final logs = [newIntruderLog, ...intruderLogs.value];
      if (logs.length > 50) {
        logs.removeLast();
      }
      intruderLogs.value = logs;
      await prefs.setString(_K.intruderLogs, jsonEncode(logs));
    }
  }
}
