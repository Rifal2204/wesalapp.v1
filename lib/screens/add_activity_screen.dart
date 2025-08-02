import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/image_db.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}
final userId = FirebaseAuth.instance.currentUser?.uid;//اضافة لربط الاكفيتي باليوزر

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  DateTime? _selectedDateTime;
  File? _imageFile;
  int? _imageId;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!kIsWeb) {
        final id = await ImageDB.insertImage(bytes);
        final file = File(picked.path);

        setState(() {
          _imageFile = file;
          _imageId = id;
        });
      } else {
        // On web, you can still store image in memory or skip
        setState(() {
          _imageFile = null;
          _imageId = null;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addActivity() async {
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('activities').add({
        'name': _nameCtrl.text.trim(),
        'count': int.tryParse(_countCtrl.text.trim()) ?? 0,
        'location': _locationCtrl.text.trim(),
        'time': _selectedDateTime,
        'imageId': _imageId,
        'createdAt': FieldValue.serverTimestamp(),
         'creatorId': FirebaseAuth.instance.currentUser?.uid,

      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _error = 'حدث خطأ، حاول مرة أخرى.');
    } finally {
      setState(() => _loading = false);
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
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: InputDecoration(
                        labelText: 'الموقع',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'أدخل الموقع'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        _selectedDateTime == null
                            ? 'اختر التاريخ والوقت'
                            : '${_selectedDateTime!.year}/${_selectedDateTime!.month.toString().padLeft(2, '0')}/${_selectedDateTime!.day.toString().padLeft(2, '0')} - '
                                '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          image:
                              _imageFile != null
                                  ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _imageFile == null
                                ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 40,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'تحديد صورة',
                                        style: TextStyle(color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                )
                                : null,
                      ),
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
