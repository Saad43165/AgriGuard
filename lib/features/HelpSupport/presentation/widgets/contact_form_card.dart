import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/glass_card.dart';

/// A contact form that sends user input to a specified email address.
class ContactFormCard extends StatefulWidget {
  final double itemSpacing;

  const ContactFormCard({
    super.key,
    required this.itemSpacing,
  });

  @override
  ContactFormCardState createState() => ContactFormCardState();
}

class ContactFormCardState extends State<ContactFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPadding = EdgeInsets.all(AppMeasurements.getResponsivePadding(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title: 'Contact Us', icon: Icons.contact_support_rounded),
        SizedBox(height: widget.itemSpacing),
        GlassCard(
          borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
          child: Padding(
            padding: cardPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send us your query',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                    ),
                  ),
                  SizedBox(height: widget.itemSpacing),
                  _buildTextField(
                    context,
                    label: 'Name',
                    controller: _nameController,
                    validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                  ),
                  SizedBox(height: widget.itemSpacing),
                  _buildTextField(
                    context,
                    label: 'Email',
                    controller: _emailController,
                    validator: (value) {
                      if (value!.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: widget.itemSpacing),
                  _buildTextField(
                    context,
                    label: 'Message',
                    controller: _messageController,
                    maxLines: 4,
                    validator: (value) => value!.isEmpty ? 'Please enter a message' : null,
                  ),
                  SizedBox(height: widget.itemSpacing),
                  _buildSubmitButton(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the section header with title and icon.
  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(widget.itemSpacing),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
          ),
        ),
        SizedBox(width: widget.itemSpacing),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
      ],
    );
  }

  /// Builds a text field with validation and accessibility.
  Widget _buildTextField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Semantics(
      label: label,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          errorStyle: TextStyle(
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
          ),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
        ),
      ),
    );
  }

  /// Builds a submit button that sends the form data via email.
  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          HapticFeedback.lightImpact();
          final success = await _sendEmail(
            context,
            name: _nameController.text,
            email: _emailController.text,
            message: _messageController.text,
          );
          if (success) {
            _nameController.clear();
            _emailController.clear();
            _messageController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Message sent successfully'),
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        ),
        padding: EdgeInsets.symmetric(
          vertical: AppMeasurements.getResponsivePadding(context) / 1.5,
          horizontal: AppMeasurements.getResponsivePadding(context),
        ),
        child: Text(
          'Submit',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
          ),
        ),
      ),
    );
  }

  /// Sends the form data to the specified email address.
  Future<bool> _sendEmail(BuildContext context, {required String name, required String email, required String message}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'saadnaz43165@gmail.com',
      queryParameters: {
        'subject': 'Contact Form Submission from $name',
        'body': 'Name: $name\nEmail: $email\n\nMessage:\n$message',
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No email client found'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending email: $e'),
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
        ),
      );
      return false;
    }
  }
}