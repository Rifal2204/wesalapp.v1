import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});
  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  DateTime? _selectedTime;
  File? _imageFile;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Save image locally
      final directory = await getApplicationDocumentsDirectory();
      final localPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localImage = await File(picked.path).copy(localPath);
      setState(() => _imageFile = localImage);
    }
  }

  Future<void> _addActivity() async {
    if (!_formKey.currentState!.validate() || _selectedTime == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseFirestore.instance.collection('activities').add({
        'name': _nameCtrl.text.trim(),
        'count': int.tryParse(_countCtrl.text.trim()) ?? 0,
        'time': _selectedTime,
        'imagePath': _imageFile?.path, // Save local path (optional)
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ، حاول مرة أخرى.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة نشاط جديد'),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.amber),
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFFFBF8F0),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.amber.shade50,
                        backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                        child:
                            _imageFile == null
                                ? const Icon(
                                  Icons.add_a_photo,
                                  size: 32,
                                  color: Colors.amber,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم النشاط',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'أدخل اسم النشاط'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countCtrl,
                      decoration: InputDecoration(
                        labelText: 'عدد الموجودين',
                        prefixIcon: const Icon(Icons.people),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'أدخل العدد'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        _selectedTime == null
                            ? 'اختر الوقت'
                            : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    if (_error != null) const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: _loading ? null : _addActivity,
                        child:
                            _loading
                                ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('إضافة النشاط'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
