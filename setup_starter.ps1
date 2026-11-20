# ============================================================
# Flutter Starter Project Generator
# GetX + Clean Architecture + PIN + Themes + Localization
# Run from the Flutter project root.
# ============================================================

$ErrorActionPreference = "Stop"

function Write-ProjectFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "Created: $Path" -ForegroundColor DarkGray
}

# Ensure this is the Flutter project root.
if (!(Test-Path "pubspec.yaml") -or !(Test-Path "lib")) {
    throw "Run this script from the Flutter project root (the folder containing pubspec.yaml and lib/)."
}

Write-Host "`nInstalling required packages..." -ForegroundColor Cyan
flutter pub add get shared_preferences flutter_secure_storage cryptography

# ---------------------------
# Core: constants
# ---------------------------
Write-ProjectFile "lib/core/constants/app_constants.dart" @'
class AppConstants {
  AppConstants._();

  static const String appName = 'EJARY';
  static const int pinLength = 6;
  static const int maxPinAttempts = 5;
  static const int lockoutSeconds = 30;
}
'@

# ---------------------------
# Core: theme
# ---------------------------
Write-ProjectFile "lib/core/theme/app_theme.dart" @'
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF5267D8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FC),
          foregroundColor: Color(0xFF182033),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE9EBF2)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E4EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E4EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _seed, width: 1.5),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF10131C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF10131C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1F2B),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2B3242)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F2B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
}
'@

# ---------------------------
# Core: localization
# ---------------------------
Write-ProjectFile "lib/core/locale/app_translations.dart" @'
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'app_name': 'EJARY',
          'welcome': 'Welcome',
          'home': 'Home',
          'secure_access': 'Secure access',
          'enter_pin': 'Enter your PIN',
          'create_pin': 'Create your PIN',
          'confirm_pin': 'Confirm your PIN',
          'new_pin': 'New PIN',
          'current_pin': 'Current PIN',
          'change_pin': 'Change PIN',
          'pin_mismatch': 'PIN codes do not match.',
          'pin_invalid': 'Incorrect PIN. Please try again.',
          'pin_saved': 'PIN saved successfully.',
          'pin_changed': 'PIN changed successfully.',
          'pin_required': 'Please enter a valid 6-digit PIN.',
          'continue': 'Continue',
          'confirm': 'Confirm',
          'cancel': 'Cancel',
          'settings': 'Settings',
          'appearance': 'Appearance',
          'language': 'Language',
          'light': 'Light',
          'dark': 'Dark',
          'system': 'System',
          'english': 'English',
          'arabic': 'Arabic',
          'logout': 'Lock application',
          'dashboard': 'Dashboard',
          'starter_message': 'Your application foundation is ready.',
          'security_message': 'Your private workspace is protected.',
          'locked_message': 'Too many attempts. Try again in @seconds seconds.',
          'error': 'Error',
          'success': 'Success',
          'try_again': 'Try again',
          'setup_subtitle': 'Choose a 6-digit PIN to protect your application.',
          'verify_subtitle': 'Enter your PIN to continue.',
          'confirm_subtitle': 'Enter the same PIN again.',
          'change_pin_subtitle': 'Verify your current PIN before changing it.',
        },
        'ar_YE': {
          'app_name': 'إيجاري',
          'welcome': 'مرحباً',
          'home': 'الرئيسية',
          'secure_access': 'دخول آمن',
          'enter_pin': 'أدخل رمز PIN',
          'create_pin': 'أنشئ رمز PIN',
          'confirm_pin': 'أكد رمز PIN',
          'new_pin': 'رمز PIN الجديد',
          'current_pin': 'رمز PIN الحالي',
          'change_pin': 'تغيير رمز PIN',
          'pin_mismatch': 'الرمزان غير متطابقين.',
          'pin_invalid': 'رمز PIN غير صحيح. حاول مرة أخرى.',
          'pin_saved': 'تم حفظ رمز PIN بنجاح.',
          'pin_changed': 'تم تغيير رمز PIN بنجاح.',
          'pin_required': 'يرجى إدخال رمز مكوّن من 6 أرقام.',
          'continue': 'متابعة',
          'confirm': 'تأكيد',
          'cancel': 'إلغاء',
          'settings': 'الإعدادات',
          'appearance': 'المظهر',
          'language': 'اللغة',
          'light': 'فاتح',
          'dark': 'داكن',
          'system': 'حسب الجهاز',
          'english': 'الإنجليزية',
          'arabic': 'العربية',
          'logout': 'قفل التطبيق',
          'dashboard': 'لوحة التحكم',
          'starter_message': 'تم تجهيز أساس تطبيقك.',
          'security_message': 'مساحة عملك محمية.',
          'locked_message': 'محاولات كثيرة. حاول بعد @seconds ثانية.',
          'error': 'خطأ',
          'success': 'نجاح',
          'try_again': 'حاول مجدداً',
          'setup_subtitle': 'اختر رمزاً من 6 أرقام لحماية التطبيق.',
          'verify_subtitle': 'أدخل رمز PIN للمتابعة.',
          'confirm_subtitle': 'أدخل الرمز نفسه مرة أخرى.',
          'change_pin_subtitle': 'تحقق من الرمز الحالي قبل تغييره.',
        },
      };
}
'@

# ---------------------------
# Core: preferences service
# ---------------------------
Write-ProjectFile "lib/core/services/preferences_service.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends GetxService {
  late SharedPreferences _preferences;

  static const _themeKey = 'theme_mode';
  static const _localeKey = 'app_locale';

  Future<PreferencesService> init() async {
    _preferences = await SharedPreferences.getInstance();
    return this;
  }

  ThemeMode get themeMode {
    switch (_preferences.getString(_themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale get locale {
    final value = _preferences.getString(_localeKey) ?? 'en';
    return value == 'ar' ? const Locale('ar', 'YE') : const Locale('en', 'US');
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _preferences.setString(_themeKey, value);
  }

  Future<void> saveLocale(Locale locale) async {
    await _preferences.setString(
      _localeKey,
      locale.languageCode == 'ar' ? 'ar' : 'en',
    );
  }
}
'@

# ---------------------------
# Routes
# ---------------------------
Write-ProjectFile "lib/routes/app_routes.dart" @'
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const pinSetup = '/pin/setup';
  static const pinVerify = '/pin/verify';
  static const pinChange = '/pin/change';
  static const home = '/home';
}
'@

Write-ProjectFile "lib/routes/app_pages.dart" @'
import 'package:get/get.dart';
import '../features/splash/presentation/bindings/splash_binding.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/pin/presentation/bindings/pin_binding.dart';
import '../features/pin/presentation/screens/pin_setup_screen.dart';
import '../features/pin/presentation/screens/pin_verify_screen.dart';
import '../features/pin/presentation/screens/pin_change_screen.dart';
import '../features/home/presentation/bindings/home_binding.dart';
import '../features/home/presentation/screens/home_screen.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.pinSetup,
      page: () => const PinSetupScreen(),
      binding: PinBinding(),
    ),
    GetPage(
      name: AppRoutes.pinVerify,
      page: () => const PinVerifyScreen(),
      binding: PinBinding(),
    ),
    GetPage(
      name: AppRoutes.pinChange,
      page: () => const PinChangeScreen(),
      binding: PinBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
  ];
}
'@

# ---------------------------
# PIN domain
# ---------------------------
Write-ProjectFile "lib/features/pin/domain/repositories/pin_repository.dart" @'
abstract class PinRepository {
  Future<bool> hasPin();
  Future<void> setupPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> changePin(String currentPin, String newPin);
}
'@

Write-ProjectFile "lib/features/pin/domain/usecases/has_pin.dart" @'
import '../repositories/pin_repository.dart';

class HasPin {
  const HasPin(this.repository);
  final PinRepository repository;

  Future<bool> call() => repository.hasPin();
}
'@

Write-ProjectFile "lib/features/pin/domain/usecases/setup_pin.dart" @'
import '../repositories/pin_repository.dart';

class SetupPin {
  const SetupPin(this.repository);
  final PinRepository repository;

  Future<void> call(String pin) => repository.setupPin(pin);
}
'@

Write-ProjectFile "lib/features/pin/domain/usecases/verify_pin.dart" @'
import '../repositories/pin_repository.dart';

class VerifyPin {
  const VerifyPin(this.repository);
  final PinRepository repository;

  Future<bool> call(String pin) => repository.verifyPin(pin);
}
'@

Write-ProjectFile "lib/features/pin/domain/usecases/change_pin.dart" @'
import '../repositories/pin_repository.dart';

class ChangePin {
  const ChangePin(this.repository);
  final PinRepository repository;

  Future<void> call(String currentPin, String newPin) =>
      repository.changePin(currentPin, newPin);
}
'@

# ---------------------------
# PIN data source and repository
# ---------------------------
Write-ProjectFile "lib/features/pin/data/datasources/pin_local_data_source.dart" @'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinLocalDataSource {
  PinLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';
  static const _attemptsKey = 'pin_failed_attempts';
  static const _lockUntilKey = 'pin_lock_until';

  Future<String?> readHash() => _storage.read(key: _hashKey);
  Future<String?> readSalt() => _storage.read(key: _saltKey);

  Future<void> savePinMaterial({
    required String hash,
    required String salt,
  }) async {
    await _storage.write(key: _hashKey, value: hash);
    await _storage.write(key: _saltKey, value: salt);
    await resetAttempts();
  }

  Future<int> readAttempts() async =>
      int.tryParse(await _storage.read(key: _attemptsKey) ?? '0') ?? 0;

  Future<void> writeAttempts(int value) =>
      _storage.write(key: _attemptsKey, value: value.toString());

  Future<DateTime?> readLockUntil() async {
    final value = await _storage.read(key: _lockUntilKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> writeLockUntil(DateTime? value) async {
    if (value == null) {
      await _storage.delete(key: _lockUntilKey);
    } else {
      await _storage.write(key: _lockUntilKey, value: value.toIso8601String());
    }
  }

  Future<void> resetAttempts() async {
    await _storage.write(key: _attemptsKey, value: '0');
    await writeLockUntil(null);
  }
}
'@

Write-ProjectFile "lib/features/pin/data/repositories/pin_repository_impl.dart" @'
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../domain/repositories/pin_repository.dart';
import '../datasources/pin_local_data_source.dart';

class PinRepositoryImpl implements PinRepository {
  PinRepositoryImpl(this._localDataSource);

  final PinLocalDataSource _localDataSource;

  // PBKDF2 is intentionally used instead of a fast general-purpose hash.
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );

  static const int _maxAttempts = 5;
  static const int _lockoutSeconds = 30;

  @override
  Future<bool> hasPin() async =>
      (await _localDataSource.readHash()) != null &&
      (await _localDataSource.readSalt()) != null;

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  Future<String> _deriveHash(String pin, String salt) async {
    final key = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: base64Url.decode(salt),
    );
    return base64UrlEncode(await key.extractBytes());
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('PIN must contain exactly 6 digits.');
    }
  }

  @override
  Future<void> setupPin(String pin) async {
    _validatePin(pin);
    if (await hasPin()) {
      throw StateError('A PIN is already configured.');
    }
    final salt = _randomSalt();
    final hash = await _deriveHash(pin, salt);
    await _localDataSource.savePinMaterial(hash: hash, salt: salt);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    _validatePin(pin);

    final lockUntil = await _localDataSource.readLockUntil();
    if (lockUntil != null && DateTime.now().isBefore(lockUntil)) {
      final remaining = lockUntil.difference(DateTime.now()).inSeconds + 1;
      throw StateError('LOCKED:$remaining');
    }

    final storedHash = await _localDataSource.readHash();
    final salt = await _localDataSource.readSalt();
    if (storedHash == null || salt == null) return false;

    final enteredHash = await _deriveHash(pin, salt);
    final valid = storedHash == enteredHash;

    if (valid) {
      await _localDataSource.resetAttempts();
      return true;
    }

    final attempts = (await _localDataSource.readAttempts()) + 1;
    await _localDataSource.writeAttempts(attempts);

    if (attempts >= _maxAttempts) {
      await _localDataSource.writeAttempts(0);
      await _localDataSource.writeLockUntil(
        DateTime.now().add(const Duration(seconds: _lockoutSeconds)),
      );
    }
    return false;
  }

  @override
  Future<void> changePin(String currentPin, String newPin) async {
    _validatePin(newPin);
    final valid = await verifyPin(currentPin);
    if (!valid) throw StateError('Current PIN is incorrect.');

    final salt = _randomSalt();
    final hash = await _deriveHash(newPin, salt);
    await _localDataSource.savePinMaterial(hash: hash, salt: salt);
  }
}
'@

# ---------------------------
# PIN presentation
# ---------------------------
Write-ProjectFile "lib/features/pin/presentation/bindings/pin_binding.dart" @'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../data/datasources/pin_local_data_source.dart';
import '../../data/repositories/pin_repository_impl.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/usecases/change_pin.dart';
import '../../domain/usecases/setup_pin.dart';
import '../../domain/usecases/verify_pin.dart';
import '../controllers/pin_controller.dart';

class PinBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PinRepository>()) {
      Get.lazyPut<PinRepository>(
        () => PinRepositoryImpl(
          PinLocalDataSource(const FlutterSecureStorage()),
        ),
      );
    }
    Get.lazyPut(() => SetupPin(Get.find<PinRepository>()));
    Get.lazyPut(() => VerifyPin(Get.find<PinRepository>()));
    Get.lazyPut(() => ChangePin(Get.find<PinRepository>()));
    Get.lazyPut(() => PinController(
          setupPin: Get.find<SetupPin>(),
          verifyPin: Get.find<VerifyPin>(),
          changePin: Get.find<ChangePin>(),
        ));
  }
}
'@

Write-ProjectFile "lib/features/pin/presentation/controllers/pin_controller.dart" @'
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/usecases/change_pin.dart';
import '../../domain/usecases/setup_pin.dart';
import '../../domain/usecases/verify_pin.dart';

class PinController extends GetxController {
  PinController({
    required this.setupPin,
    required this.verifyPin,
    required this.changePin,
  });

  final SetupPin setupPin;
  final VerifyPin verifyPin;
  final ChangePin changePin;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<bool> createPin(String pin) async {
    errorMessage.value = '';
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      errorMessage.value = 'pin_required'.tr;
      return false;
    }
    isLoading.value = true;
    try {
      await setupPin(pin);
      Get.offAllNamed(AppRoutes.home);
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> unlock(String pin) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final valid = await verifyPin(pin);
      if (valid) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        errorMessage.value = 'pin_invalid'.tr;
      }
      return valid;
    } catch (error) {
      final message = error.toString();
      if (message.contains('LOCKED:')) {
        final seconds = message.split('LOCKED:').last.replaceAll(')', '');
        errorMessage.value = 'locked_message'.trParams({'seconds': seconds});
      } else {
        errorMessage.value = 'pin_invalid'.tr;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePin(String currentPin, String newPin) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      await changePin(currentPin, newPin);
      Get.back();
      Get.snackbar('success'.tr, 'pin_changed'.tr);
      return true;
    } catch (error) {
      errorMessage.value = error.toString().contains('incorrect')
          ? 'pin_invalid'.tr
          : error.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
'@

Write-ProjectFile "lib/features/pin/presentation/screens/pin_setup_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pin_controller.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _confirming = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      Get.find<PinController>().errorMessage.value = 'pin_required'.tr;
      return;
    }
    if (!_confirming) {
      setState(() => _confirming = true);
      return;
    }
    if (_confirmController.text != pin) {
      Get.find<PinController>().errorMessage.value = 'pin_mismatch'.tr;
      return;
    }
    await Get.find<PinController>().createPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PinController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    _confirming ? 'confirm_pin'.tr : 'create_pin'.tr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_confirming ? 'confirm_subtitle'.tr : 'setup_subtitle'.tr),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _confirming ? _confirmController : _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '••••••',
                      counterText: '',
                      labelText: _confirming ? 'confirm_pin'.tr : 'create_pin'.tr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => controller.errorMessage.value.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        )),
                  const SizedBox(height: 20),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: controller.isLoading.value ? null : _submit,
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator()
                              : Text(_confirming ? 'confirm'.tr : 'continue'.tr),
                        ),
                      )),
                  if (_confirming)
                    TextButton(
                      onPressed: () => setState(() {
                        _confirming = false;
                        _confirmController.clear();
                        controller.errorMessage.value = '';
                      }),
                      child: Text('cancel'.tr),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
'@

Write-ProjectFile "lib/features/pin/presentation/screens/pin_verify_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pin_controller.dart';

class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen({super.key});

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PinController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 64),
                  const SizedBox(height: 24),
                  Text('secure_access'.tr,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('verify_subtitle'.tr),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    autofocus: true,
                    onSubmitted: (_) => controller.unlock(_pinController.text),
                    decoration: InputDecoration(
                      labelText: 'enter_pin'.tr,
                      hintText: '••••••',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => controller.errorMessage.value.isEmpty
                      ? const SizedBox.shrink()
                      : Text(controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 20),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.unlock(_pinController.text),
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator()
                              : Text('continue'.tr),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
'@

Write-ProjectFile "lib/features/pin/presentation/screens/pin_change_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pin_controller.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = Get.find<PinController>();
    if (!RegExp(r'^\d{6}$').hasMatch(_newPin.text)) {
      controller.errorMessage.value = 'pin_required'.tr;
      return;
    }
    if (_newPin.text != _confirm.text) {
      controller.errorMessage.value = 'pin_mismatch'.tr;
      return;
    }
    await controller.updatePin(_current.text, _newPin.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PinController>();
    InputDecoration decoration(String label) => InputDecoration(labelText: label);
    return Scaffold(
      appBar: AppBar(title: Text('change_pin'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: _current, obscureText: true, maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: decoration('current_pin'.tr).copyWith(counterText: '')),
          const SizedBox(height: 12),
          TextField(controller: _newPin, obscureText: true, maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: decoration('new_pin'.tr).copyWith(counterText: '')),
          const SizedBox(height: 12),
          TextField(controller: _confirm, obscureText: true, maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: decoration('confirm_pin'.tr).copyWith(counterText: '')),
          const SizedBox(height: 12),
          Obx(() => controller.errorMessage.value.isEmpty
              ? const SizedBox.shrink()
              : Text(controller.errorMessage.value,
                  style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 20),
          Obx(() => FilledButton(
                onPressed: controller.isLoading.value ? null : _submit,
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : Text('confirm'.tr),
              )),
        ],
      ),
    );
  }
}
'@

# ---------------------------
# Splash
# ---------------------------
Write-ProjectFile "lib/features/splash/domain/repositories/startup_repository.dart" @'
abstract class StartupRepository {
  Future<bool> hasPin();
}
'@

Write-ProjectFile "lib/features/splash/domain/usecases/check_startup.dart" @'
import '../repositories/startup_repository.dart';

class CheckStartup {
  const CheckStartup(this.repository);
  final StartupRepository repository;

  Future<bool> call() => repository.hasPin();
}
'@

Write-ProjectFile "lib/features/splash/data/repositories/startup_repository_impl.dart" @'
import '../../../pin/domain/repositories/pin_repository.dart';
import '../../domain/repositories/startup_repository.dart';

class StartupRepositoryImpl implements StartupRepository {
  const StartupRepositoryImpl(this.pinRepository);
  final PinRepository pinRepository;

  @override
  Future<bool> hasPin() => pinRepository.hasPin();
}
'@

Write-ProjectFile "lib/features/splash/presentation/bindings/splash_binding.dart" @'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../pin/data/datasources/pin_local_data_source.dart';
import '../../../pin/data/repositories/pin_repository_impl.dart';
import '../../../pin/domain/repositories/pin_repository.dart';
import '../../data/repositories/startup_repository_impl.dart';
import '../../domain/repositories/startup_repository.dart';
import '../../domain/usecases/check_startup.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PinRepository>()) {
      Get.lazyPut<PinRepository>(
        () => PinRepositoryImpl(PinLocalDataSource(const FlutterSecureStorage())),
      );
    }
    Get.lazyPut<StartupRepository>(
      () => StartupRepositoryImpl(Get.find<PinRepository>()),
    );
    Get.lazyPut(() => CheckStartup(Get.find<StartupRepository>()));
    Get.lazyPut(() => SplashController(Get.find<CheckStartup>()));
  }
}
'@

Write-ProjectFile "lib/features/splash/presentation/controllers/splash_controller.dart" @'
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/usecases/check_startup.dart';

class SplashController extends GetxController {
  SplashController(this.checkStartup);

  final CheckStartup checkStartup;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    try {
      final configured = await checkStartup();
      Get.offAllNamed(configured ? AppRoutes.pinVerify : AppRoutes.pinSetup);
    } catch (_) {
      Get.offAllNamed(AppRoutes.pinSetup);
    }
  }
}
'@

Write-ProjectFile "lib/features/splash/presentation/screens/splash_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('app_name'.tr,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
'@

# ---------------------------
# Home
# ---------------------------
Write-ProjectFile "lib/features/home/presentation/bindings/home_binding.dart" @'
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(HomeController.new);
  }
}
'@

Write-ProjectFile "lib/features/home/presentation/controllers/home_controller.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/preferences_service.dart';
import '../../../../routes/app_routes.dart';

class HomeController extends GetxController {
  final preferences = Get.find<PreferencesService>();

  Future<void> setTheme(ThemeMode mode) async {
    await preferences.saveThemeMode(mode);
    Get.changeThemeMode(mode);
  }

  Future<void> setLanguage(String languageCode) async {
    final locale = languageCode == 'ar'
        ? const Locale('ar', 'YE')
        : const Locale('en', 'US');
    await preferences.saveLocale(locale);
    Get.updateLocale(locale);
  }

  void lockApp() => Get.offAllNamed(AppRoutes.pinVerify);

  void openChangePin() => Get.toNamed(AppRoutes.pinChange);
}
'@

Write-ProjectFile "lib/features/home/presentation/screens/home_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        actions: [
          IconButton(
            tooltip: 'logout'.tr,
            onPressed: controller.lockApp,
            icon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('welcome'.tr, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('starter_message'.tr),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.shield_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text('security_message'.tr)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('settings'.tr, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text('appearance'.tr),
                  trailing: DropdownButton<ThemeMode>(
                    value: controller.preferences.themeMode,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('system'.tr)),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('light'.tr)),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('dark'.tr)),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setTheme(value);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text('language'.tr),
                  trailing: DropdownButton<String>(
                    value: controller.preferences.locale.languageCode,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text('english'.tr)),
                      DropdownMenuItem(value: 'ar', child: Text('arabic'.tr)),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setLanguage(value);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: Text('change_pin'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: controller.openChangePin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
'@

# ---------------------------
# Main
# ---------------------------
Write-ProjectFile "lib/main.dart" @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/locale/app_translations.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await PreferencesService().init();
  Get.put<PreferencesService>(preferences, permanent: true);

  runApp(const StarterApp());
}

class StarterApp extends StatelessWidget {
  const StarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = Get.find<PreferencesService>();

    return GetMaterialApp(
      title: 'EJARY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: preferences.themeMode,
      translations: AppTranslations(),
      locale: preferences.locale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppPages.pages,
      initialRoute: AppRoutes.splash,
    );
  }
}
'@

# ---------------------------
# Format and analyze
# ---------------------------
Write-Host "`nFormatting Dart files..." -ForegroundColor Cyan
dart format lib

Write-Host "`nGetting packages..." -ForegroundColor Cyan
flutter pub get

Write-Host "`nRunning Flutter analyzer..." -ForegroundColor Cyan
flutter analyze

Write-Host "`n====================================================" -ForegroundColor Green
Write-Host " STARTER PROJECT FILES GENERATED" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Review flutter analyze output above before running." -ForegroundColor Yellow
Write-Host "Run the app with: flutter run" -ForegroundColor Cyan
Write-Host "Note: Secure storage support depends on the target platform." -ForegroundColor Yellow
