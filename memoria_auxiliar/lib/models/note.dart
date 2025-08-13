class Note {
  final String id;
  final String text;
  final List<double>? vector; // AGORA guarda embedding

  Note({
    required this.id,
    required this.text,
    this.vector,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'vector': vector,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      text: map['text'],
      vector: map['vector'] != null
          ? List<double>.from(map['vector'])
          : null,
    );
  }
}
