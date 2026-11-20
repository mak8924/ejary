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
                  Text(
                    'secure_access'.tr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
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
                  Obx(
                    () => controller.errorMessage.value.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.unlock(_pinController.text),
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator()
                            : Text('continue'.tr),
                      ),
                    ),
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
