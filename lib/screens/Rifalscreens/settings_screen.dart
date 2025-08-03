import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wesalapp/screens/login.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _bioController.text = data['bio'] ?? '';
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ التغييرات بنجاح')),
        );
      }
    } catch (e) {
      setState(() {
        _error = '❌ حدث خطأ أثناء حفظ التغييرات';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          title: const Text('الإعدادات', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.amber),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'معلومات المستخدم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _nameController,
                label: 'الاسم الكامل',
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _bioController,
                label: 'نبذة عنك',
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'Cairo')),
              ],
              const SizedBox(height: 24),
              _buildPrimaryButton(
                text: ' حفظ التغييرات',
                onPressed: _loading ? null : _saveChanges,
                loading: _loading,
              ),
              const SizedBox(height: 16),
              _buildSecondaryButton(
                text: ' تسجيل الخروج',
                icon: Icons.logout,
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.amber),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.red),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
