
import 'package:flutter/material.dart';

class CustomerInfoScreen extends StatefulWidget {
  const CustomerInfoScreen({super.key});

  @override
  State<CustomerInfoScreen> createState() =>
      _CustomerInfoScreenState();
}

class _CustomerInfoScreenState
    extends State<CustomerInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalController = TextEditingController();
  final _notesController = TextEditingController();

  bool _sameAsBilling = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $label.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your contact number.';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 10 || digits.length > 13) {
      return 'Please enter a valid contact number.';
    }

    return null;
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _continueToPayment() {
    if (!_formKey.currentState!.validate()) return;

    final customer = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'shipping_address': _addressController.text.trim(),
      'shipping_city': _cityController.text.trim(),
      'shipping_province': _provinceController.text.trim(),
      'shipping_postal_code': _postalController.text.trim(),
      'shipping_notes': _notesController.text.trim(),
    };

    Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: const Text(
          'CUSTOMER INFORMATION',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'PERSONAL DETAILS',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your details before proceeding to checkout.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              _field(
                controller: _nameController,
                label: 'Full Name *',
                hint: 'Juan Dela Cruz',
                validator: (v) => _required(v, 'full name'),
              ),
              _field(
                controller: _emailController,
                label: 'Email Address *',
                hint: 'juan@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _field(
                controller: _phoneController,
                label: 'Contact Number *',
                hint: '09XXXXXXXXX',
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),

              const SizedBox(height: 8),
              const Text(
                'SHIPPING ADDRESS',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              _field(
                controller: _addressController,
                label: 'House No., Street, Barangay *',
                hint: 'House number, street, barangay',
                validator: (v) =>
                    _required(v, 'complete street address'),
              ),
              _field(
                controller: _cityController,
                label: 'City / Municipality *',
                hint: 'Meycauayan',
                validator: (v) => _required(v, 'city'),
              ),
              _field(
                controller: _provinceController,
                label: 'Province *',
                hint: 'Bulacan',
                validator: (v) => _required(v, 'province'),
              ),
              _field(
                controller: _postalController,
                label: 'Postal Code *',
                hint: '3020',
                keyboardType: TextInputType.number,
                validator: (v) => _required(v, 'postal code'),
              ),
              _field(
                controller: _notesController,
                label: 'Delivery Notes (Optional)',
                hint: 'Landmarks or delivery instructions',
                maxLines: 3,
                validator: (_) => null,
              ),

              const SizedBox(height: 4),
              const Text(
                '* Required fields',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _continueToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE TO PAYMENT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
