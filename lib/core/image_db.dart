import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageDB {
  static Database? _db;

  static Future<void> init() async {
    if (kIsWeb || _db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'images.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image BLOB
          )
        ''');
      },
    );
  }

  static Future<int> insertImage(Uint8List imageBytes) async {
    // if (kIsWeb) {
    //   // Optionally: throw or return null-equivalent
    //   return -1;
    // }
    await init();
    return await _db!.insert('images', {'image': imageBytes});
  }

  static Future<Uint8List?> getImage(int id) async {
    await init();
    final result = await _db!.query(
      'images',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['image'] as Uint8List;
    }

    return null;
  }
}
