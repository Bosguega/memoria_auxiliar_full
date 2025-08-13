import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/notes_service.dart';
import '../services/real_embedder.dart';
import 'add_note_page.dart';
import 'dart:math';

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
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });
    final notes = await widget.notesService.getNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = notes;
      _isLoading = false;
    });
  }

  Future<List<double>> _fetchEmbedding(String text) async {
    final url = Uri.parse('http://127.0.0.1:5000/embed');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'texts': [text]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> embeddings = data['embeddings'];
      return (embeddings[0] as List).map((e) => (e as num).toDouble()).toList();
    } else {
      throw Exception('Failed to fetch embedding');
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0;
    double magA = 0.0;
    double magB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0.0;
    return dot / (sqrt(magA) * sqrt(magB));
  }

  void _searchNotes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = _notes;
      });
      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      final queryEmbedding = await _fetchEmbedding(query);

      // Filtrar notas por similaridade, ordenando decrescente
      final filtered = _notes.map((note) {
        final emb = (note['embedding'] as List).map((e) => (e as num).toDouble()).toList();
        final score = _cosineSimilarity(queryEmbedding, emb);
        return {...note, 'similarity': score};
      }).toList();

      filtered.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));

      setState(() {
        _filteredNotes = filtered;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar embedding: $e')),
      );
    } finally {
      setState(() {
        _searching = false;
      });
    }
  }

  void _openAddNotePage({Map<String, dynamic>? noteToEdit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNotePage(
          notesService: widget.notesService,
          embedder: widget.embedder,
          noteToEdit: noteToEdit,
        ),
      ),
    );

    if (result == true) {
      _loadNotes();
      _searchController.clear();
      setState(() {
        _filteredNotes = _notes;
      });
    }
  }

  void _deleteNote(String id) async {
    await widget.notesService.deleteNote(id);
    _loadNotes();
    _searchController.clear();
    setState(() {
      _filteredNotes = _notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memória Auxiliar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Digite sua busca',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _searchNotes(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _searching
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _searchNotes,
                              child: const Text('Pesquisar'),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredNotes.isEmpty
                      ? const Center(child: Text('Nenhuma nota encontrada.'))
                      : ListView.builder(
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text('Memória #${index + 1}'),
                                subtitle: Text(note['text'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _openAddNotePage(noteToEdit: note),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteNote(note['id']),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddNotePage(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
