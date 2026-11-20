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
                  Text(
                    _confirming ? 'confirm_subtitle'.tr : 'setup_subtitle'.tr,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _confirming
                        ? _confirmController
                        : _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '••••••',
                      counterText: '',
                      labelText: _confirming
                          ? 'confirm_pin'.tr
                          : 'create_pin'.tr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => controller.errorMessage.value.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            controller.errorMessage.value,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.isLoading.value ? null : _submit,
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator()
                            : Text(_confirming ? 'confirm'.tr : 'continue'.tr),
                      ),
                    ),
                  ),
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
