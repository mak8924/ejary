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
    InputDecoration decoration(String label) =>
        InputDecoration(labelText: label);
    return Scaffold(
      appBar: AppBar(title: Text('change_pin'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: decoration('current_pin'.tr).copyWith(counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPin,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: decoration('new_pin'.tr).copyWith(counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: decoration('confirm_pin'.tr).copyWith(counterText: ''),
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
                  ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => FilledButton(
              onPressed: controller.isLoading.value ? null : _submit,
              child: controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : Text('confirm'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
