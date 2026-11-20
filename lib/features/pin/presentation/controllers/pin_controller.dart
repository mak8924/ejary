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
