import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import '../services/real_embedder.dart';

class AddNotePage extends StatefulWidget {
  final NotesService notesService;
  final RealEmbedder embedder;
  final Map<String, dynamic>? noteToEdit; // nota opcional para editar

  const AddNotePage({
    required this.notesService,
    required this.embedder,
    this.noteToEdit,
    super.key,
  });

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.noteToEdit != null ? widget.noteToEdit!['text'] : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final embedding = await widget.embedder.embedText(text);

      if (widget.noteToEdit != null) {
        // Editando nota existente
        await widget.notesService.updateNote(
          widget.noteToEdit!['id'],
          text,
          embedding,
        );
      } else {
        // Criando nova nota
        await widget.notesService.addNote(text, embedding);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      // Aqui você pode mostrar um alerta de erro se quiser
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteToEdit != null ? 'Editar Nota' : 'Nova Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Digite sua anotação aqui...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveNote,
              child: _isSaving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
