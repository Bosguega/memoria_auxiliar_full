import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String text;
  final List<double> embedding;

  Note({
    required this.id,
    required this.text,
    required this.embedding,
  });

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'],
        text: map['text'],
        embedding: List<double>.from(map['embedding']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'embedding': embedding,
      };
}

class NotesService {
  static const _boxName = 'notesBox';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<List<Note>> getAllNotes() async {
    return _box.values
        .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addNote(String text, List<double> embedding) async {
    final id = const Uuid().v4();
    final note = Note(id: id, text: text, embedding: embedding);
    await _box.put(id, note.toMap());
  }

  Future<void> updateNote(String id, String newText) async {
    final existing = _box.get(id);
    if (existing == null) return;
    final updated = Map<String, dynamic>.from(existing);
    updated['text'] = newText;
    await _box.put(id, updated);
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }
}
