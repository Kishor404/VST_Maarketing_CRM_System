import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const regions = [
    'rajapalayam',
    'ambasamuthiram',
    'sankarankovil',
    'tenkasi',
    'tirunelveli',
    'chennai',
  ];

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers (NOT inside build)
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final postalCtrl = TextEditingController();

  String selectedRegion = RegisterPage.regions.first;
  bool isFormValid = false;

  final authController = Get.find<AuthController>();

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    postalCtrl.dispose();
    super.dispose();
  }

  void _validateForm() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != isFormValid) {
      setState(() => isFormValid = valid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.secondary,
      appBar: AppBar(
        title: const Text('Customer Registration'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Header
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Register as a VST customer',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 28),

                    /// Name
                    _input(
                      controller: nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      onComplete: _validateForm,
                    ),

                    const SizedBox(height: 16),

                    /// Phone (+91)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                            color: cs.secondary,
                          ),
                          child: const Text(
                            '+91',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            onEditingComplete: _validateForm,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                                return 'Phone must be 10 digits';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'XXXXXXXXXX',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// Password
                    _input(
                      controller: passwordCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                      onComplete: _validateForm,
                    ),

                    const SizedBox(height: 16),

                    /// Address
                    _input(
                      controller: addressCtrl,
                      label: 'Address',
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      onComplete: _validateForm,
                    ),

                    const SizedBox(height: 16),

                    /// City
                    _input(
                      controller: cityCtrl,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                      onComplete: _validateForm,
                    ),

                    const SizedBox(height: 16),

                    /// Postal Code
                    _input(
                      controller: postalCtrl,
                      label: 'Postal Code',
                      icon: Icons.local_post_office_outlined,
                      keyboardType: TextInputType.number,
                      onComplete: _validateForm,
                    ),

                    const SizedBox(height: 16),

                    /// Region
                    DropdownButtonFormField<String>(
                      value: selectedRegion,
                      onChanged: (v) {
                        selectedRegion = v!;
                        _validateForm();
                      },
                      validator: (v) =>
                          v == null ? 'Region is required' : null,
                      items: RegisterPage.regions
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.toUpperCase()),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Region',
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// Register Button (ONLY this rebuilds)
                    Obx(() => SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isFormValid ? cs.primary : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (!isFormValid ||
                                    authController.loading.value)
                                ? null
                                : () {
                                    authController.register(
                                      name: nameCtrl.text.trim(),
                                      phone:
                                          '+91${phoneCtrl.text.trim()}',
                                      password:
                                          passwordCtrl.text.trim(),
                                      address:
                                          addressCtrl.text.trim(),
                                      city: cityCtrl.text.trim(),
                                      postalCode:
                                          postalCtrl.text.trim(),
                                      region: selectedRegion,
                                    );
                                  },
                            child: authController.loading.value
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable input
  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onComplete,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onEditingComplete: onComplete,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
