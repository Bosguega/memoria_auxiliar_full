import 'dart:math';
import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import '../services/real_embedder.dart';
import 'add_note_page.dart';

class HomePage extends StatefulWidget {
  final NotesService notesService;
  final IEmbedder embedder;

  const HomePage({required this.notesService, required this.embedder, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _allNotes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await widget.notesService.getNotes();
    setState(() {
      _allNotes = notes;
      _filteredNotes = notes;
    });
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, magA = 0, magB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    return dot / (sqrt(magA) * sqrt(magB));
  }

  Future<void> _searchNotes(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _filteredNotes = List.from(_allNotes));
      return;
    }

    final queryEmbedding = await widget.embedder.generate(query);
    final filtered = _allNotes.where((note) {
      final emb = List<double>.from(note['embedding'] ?? []);
      if (emb.isEmpty) return false;
      final sim = _cosineSimilarity(queryEmbedding, emb);
      return sim > 0.6;
    }).toList();

    filtered.sort((a, b) {
      final embA = List<double>.from(a['embedding']);
      final embB = List<double>.from(b['embedding']);
      final simA = _cosineSimilarity(queryEmbedding, embA);
      final simB = _cosineSimilarity(queryEmbedding, embB);
      return simB.compareTo(simA);
    });

    setState(() => _filteredNotes = filtered);
  }

  Future<void> _deleteNote(String id) async {
    await widget.notesService.deleteNote(id);
    await _loadNotes();
  }

  void _goToAddNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNotePage(notesService: widget.notesService, embedder: widget.embedder),
      ),
    ).then((_) => _loadNotes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memória Auxiliar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToAddNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Pesquisar notas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchNotes,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredNotes.length,
              itemBuilder: (_, i) {
                final note = _filteredNotes[i];
                return ListTile(
                  title: Text(note['text']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteNote(note['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddNote,
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Nota',
      ),
    );
  }
}
