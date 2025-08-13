import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import '../services/real_embedder.dart';

class HomePage extends StatefulWidget {
  final NotesService notesService;
  final RealEmbedder embedder;

  const HomePage({
    required this.notesService,
    required this.embedder,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];

  String _statusText = 'Pronto';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await widget.notesService.getAllNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = List.from(notes);
      _statusText = 'Encontradas ${notes.length} memórias';
    });
  }

  void _filterNotes(String query) {
    final filtered = _notes
        .where((note) => note.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      _filteredNotes = filtered;
      _statusText = 'Encontradas ${filtered.length} memórias';
    });
  }

  Future<void> _showNoteDialog({Note? note}) async {
    final TextEditingController controller =
        TextEditingController(text: note?.text ?? '');

    final isNew = note == null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Criar Nota' : 'Editar Nota'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Digite a nota aqui'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, text);
              },
              child: const Text('Salvar')),
        ],
      ),
    );

    if (result != null) {
      if (isNew) {
        await widget.notesService.addNote(result, []);
      } else {
        await widget.notesService.updateNote(note.id, result);
      }
      await _loadNotes();
      _filterNotes(_searchController.text);
    }
  }

  Future<void> _confirmDelete(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir a nota “${note.text}”?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm == true) {
      await widget.notesService.deleteNote(note.id);
      await _loadNotes();
      _filterNotes(_searchController.text);
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Anotações com Memórias'),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Pesquisar memórias',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _filterNotes,
          ),
        ),
        Expanded(
          child: _searchController.text.isEmpty
              ? Center(
                  child: Text(
                    'Digite algo para pesquisar...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = _filteredNotes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        title: Text('Memória #${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(note.text,
                              style: const TextStyle(fontSize: 14)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showNoteDialog(note: note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(note),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    bottomNavigationBar: BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          _statusText,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showNoteDialog(),
      child: const Icon(Icons.add),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
  );
}
}
