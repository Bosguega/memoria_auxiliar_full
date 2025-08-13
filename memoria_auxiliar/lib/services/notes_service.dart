import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class NotesService {
  static const _boxName = 'notesBox';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    return _box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addNote(String text, List<double> embedding) async {
    final id = const Uuid().v4();
    final note = {
      'id': id,
      'text': text,
      'embedding': embedding,
    };
    await _box.put(id, note);
  }

  Future<void> updateNote(String id, String newText, List<double> newEmbedding) async {
    final note = {
      'id': id,
      'text': newText,
      'embedding': newEmbedding,
    };
    await _box.put(id, note);
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }
}
