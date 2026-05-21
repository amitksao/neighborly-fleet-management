import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/blocs/fleet_registration_bloc.dart';

class FleetRegistrationScreen extends StatefulWidget {
  const FleetRegistrationScreen({super.key});

  @override
  State<FleetRegistrationScreen> createState() => _FleetRegistrationScreenState();
}

class _FleetRegistrationScreenState extends State<FleetRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController();
  final _companyEmailCtrl = TextEditingController();
  final _companyPhoneCtrl = TextEditingController();
  final _companyAddressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _companyEmailCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _companyAddressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<FleetRegistrationBloc>().add(
          FleetRegistrationSubmitted(
            companyName: _companyNameCtrl.text.trim(),
            companyEmail: _companyEmailCtrl.text.trim(),
            companyPhone: _companyPhoneCtrl.text.trim().isEmpty
                ? null
                : _companyPhoneCtrl.text.trim(),
            companyAddress: _companyAddressCtrl.text.trim().isEmpty
                ? null
                : _companyAddressCtrl.text.trim(),
            description: _descriptionCtrl.text.trim().isEmpty
                ? null
                : _descriptionCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Fleet'),
        centerTitle: true,
      ),
      body: BlocConsumer<FleetRegistrationBloc, FleetRegistrationState>(
        listener: (context, state) {
          if (state is FleetRegistrationSuccess) {
            Navigator.of(context).pushReplacementNamed(
              '/fleet/pending-approval',
              arguments: state.fleet,
            );
          } else if (state is FleetRegistrationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is FleetRegistrationLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about your fleet company. Once submitted, a Neighborly admin will review your application.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _TextField(
                    controller: _companyNameCtrl,
                    label: 'Company Name',
                    hint: 'Acme Corporate Shuttles',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _TextField(
                    controller: _companyEmailCtrl,
                    label: 'Company Email',
                    hint: 'fleet@acmeshuttles.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _TextField(
                    controller: _companyPhoneCtrl,
                    label: 'Phone (optional)',
                    hint: '+1 555 000 1234',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _TextField(
                    controller: _companyAddressCtrl,
                    label: 'Company Address (optional)',
                    hint: '123 Main St, Austin TX 78701',
                  ),
                  const SizedBox(height: 16),
                  _TextField(
                    controller: _descriptionCtrl,
                    label: 'Description (optional)',
                    hint: 'Brief description of your fleet service',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
      ),
      validator: validator,
    );
  }
}
