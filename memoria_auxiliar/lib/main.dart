import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/notes_service.dart';
import 'services/real_embedder.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final notesService = NotesService();
  await notesService.init();

  final embedder = RealEmbedder();

  runApp(MyApp(notesService: notesService, embedder: embedder));
}

class MyApp extends StatelessWidget {
  final NotesService notesService;
  final RealEmbedder embedder;

  const MyApp({required this.notesService, required this.embedder, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memória Auxiliar',
      home: HomePage(notesService: notesService, embedder: embedder),
    );
  }
}
