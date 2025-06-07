import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class SubmitSongScreen extends StatefulWidget {
  const SubmitSongScreen({Key? key}) : super(key: key);

  @override
  State<SubmitSongScreen> createState() => _SubmitSongScreenState();
}

class _SubmitSongScreenState extends State<SubmitSongScreen> {
  PlatformFile? _selectedSong;
  PlatformFile? _selectedLyrics;
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _languageController = TextEditingController();
  bool _loading = false;

  Future<List<String>> loadOffensiveWords() async {
    final jsonString = await rootBundle.loadString('assets/Offensive.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return [
      ...jsonData['drug_related_terms'] ?? [],
      ...jsonData['curse_words'] ?? [],
    ].map((e) => e.toString().toLowerCase()).toList();
  }

  List<String> findOffensiveWords(String lyrics, List<String> offensiveWords) {
    final lyricsLower = lyrics.toLowerCase();
    final found = <String>{};
    for (final word in offensiveWords) {
      if (lyricsLower.contains(word)) {
        found.add(word);
      }
    }
    return found.toList();
  }

  String getSongStatus(int offensiveCount) {
    if (offensiveCount <= 3) return 'approved';
    if (offensiveCount <= 6) return 'pending';
    return 'disapproved';
  }

  double calculateQuality(String lyrics, int offensiveCount) {
    final totalWords = lyrics.trim().split(RegExp(r'\s+')).length;
    if (totalWords == 0) return 100.0;
    final cleanWords = (totalWords - offensiveCount).clamp(0, totalWords);
    return (cleanWords / totalWords) * 100;
  }

  Future<void> _pickSong() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedSong = result.files.first);
    }
  }

  Future<void> _pickLyrics() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedLyrics = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_selectedSong == null || _selectedSong!.bytes == null ||
        _selectedLyrics == null || _selectedLyrics!.bytes == null ||
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a song, lyrics, and enter a title.')),
      );
      return;
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final songPath = 'songs/$timestamp-${_selectedSong!.name}';
      await supabase.storage.from('music-bucket').uploadBinary(songPath, _selectedSong!.bytes!);
      final songUrl = supabase.storage.from('music-bucket').getPublicUrl(songPath);

      final lyricsPath = 'lyrics/$timestamp-${_selectedLyrics!.name}';
      await supabase.storage.from('music-bucket').uploadBinary(lyricsPath, _selectedLyrics!.bytes!);
      final lyricsUrl = supabase.storage.from('music-bucket').getPublicUrl(lyricsPath);
      final lyricsContent = utf8.decode(_selectedLyrics!.bytes!);

      final offensiveWords = await loadOffensiveWords();
      final foundWords = findOffensiveWords(lyricsContent, offensiveWords);
      final offensiveCount = foundWords.length;
      final status = getSongStatus(offensiveCount);
      final quality = calculateQuality(lyricsContent, offensiveCount);

      await supabase.from('songs_v2').insert({
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'genre': _genreController.text.trim(),
        'language': _languageController.text.trim(),
        'song_url': songUrl,
        'lyrics_url': lyricsUrl,
        'status': status,
        'quality': quality,
        'offensive_count': offensiveCount,
        'offensive_words': foundWords,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song submitted successfully!')),
      );

      setState(() {
        _selectedSong = null;
        _selectedLyrics = null;
        _titleController.clear();
        _genreController.clear();
        _languageController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _fileUploadButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    PlatformFile? file,
    bool isLyrics = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLyrics)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4),
            child: Text(
              "Upload Lyrics (txt or pdf)",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color.fromARGB(255, 235, 233, 233), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: file == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 32, color: Colors.black),
                        const SizedBox(height: 4),
                        Text(
                          isLyrics
                              ? "Click to Upload or Drag and Drop"
                              : "Choose file",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            file.name,
                            style: const TextStyle(
                                color: Colors.black87, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              if (isLyrics) {
                                _selectedLyrics = null;
                              } else {
                                _selectedSong = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Upload Audio",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 8),
                _fileUploadButton(
                  label: 'Choose file',
                  onTap: _pickSong,
                  icon: Icons.music_note,
                  file: _selectedSong,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Song Details",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 8),
                _buildInputField('Title', _titleController),
                _buildInputField('Genre', _genreController),
                _buildInputField('Language', _languageController),
                const SizedBox(height: 24),
                _fileUploadButton(
                  label: 'Click to Upload or Drag and Drop',
                  onTap: _pickLyrics,
                  icon: Icons.upload,
                  file: _selectedLyrics,
                  isLyrics: true,
                ),
                const SizedBox(height: 32),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Submit For Analysis', style: TextStyle(color: Colors.white)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}