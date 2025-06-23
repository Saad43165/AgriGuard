import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/home/presentation/widgets/nav_bar.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, dynamic> _userProfile = {
    'name': 'John Farmer',
    'email': 'john@agriguard.com',
    'phone': '+92 300 1234567',
    'location': 'Punjab, Pakistan',
    'farmSize': '5 acres',
    'crops': ['Wheat', 'Cotton', 'Rice'],
    'joinDate': 'Joined: January 2023',
    'scanCount': 24,
  };

  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = _userProfile['name'];
    _emailController.text = _userProfile['email'];
    _phoneController.text = _userProfile['phone'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save changes
        _userProfile['name'] = _nameController.text;
        _userProfile['email'] = _emailController.text;
        _userProfile['phone'] = _phoneController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Picture Section
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                ),
                if (_isEditing)
                  FloatingActionButton.small(
                    onPressed: () {}, // Add image picker functionality
                    child: const Icon(Icons.camera_alt),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Information
            _buildProfileInfoSection(),

            // Statistics Section
            _buildStatisticsSection(),

            // Actions Section
            _buildActionsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildProfileInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEditableField(
              label: 'Full Name',
              value: _userProfile['name'],
              controller: _nameController,
              icon: AppIcons.name,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: 'Email',
              value: _userProfile['email'],
              controller: _emailController,
              icon: AppIcons.email,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: 'Phone',
              value: _userProfile['phone'],
              controller: _phoneController,
              icon: Icons.phone,
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location'),
              subtitle: Text(_userProfile['location']),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.agriculture),
              title: const Text('Farm Size'),
              subtitle: Text(_userProfile['farmSize']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: _isEditing
          ? TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Statistics'),
              subtitle: Text(_userProfile['joinDate']),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    value: _userProfile['scanCount'].toString(),
                    label: 'Scans',
                    icon: Icons.camera_alt,
                  ),
                  _buildStatItem(
                    value: _userProfile['crops'].length.toString(),
                    label: 'Crops',
                    icon: Icons.eco,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(AppIcons.history),
            title: const Text('Scan History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ],
      ),
    );
  }
}