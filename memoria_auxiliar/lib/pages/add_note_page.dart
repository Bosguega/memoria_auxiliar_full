import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import '../services/real_embedder.dart';

class AddNotePage extends StatefulWidget {
  final NotesService notesService;
  final IEmbedder embedder;

  const AddNotePage({required this.notesService, required this.embedder, super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _textController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveNote() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final embedding = await widget.embedder.generate(text);
      await widget.notesService.addNote(text, embedding);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Nota')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Texto da nota',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveNote,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
