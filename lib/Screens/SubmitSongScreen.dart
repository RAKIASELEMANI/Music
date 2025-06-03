import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmitSongScreen extends StatefulWidget {
  const SubmitSongScreen({super.key});

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

  Future<void> _pickSongFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'flac'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedSong = result.files.first;
      });
    }
  }

  Future<void> _pickLyricsFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedLyrics = result.files.first;
      });
    }
  }

  void _submit() async {
    if (_selectedSong == null || _selectedSong!.bytes == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a song and enter a title.')),
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
      // Upload song file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final songPath = 'songs/$timestamp-${_selectedSong!.name}';
      await supabase.storage.from('songs-bucket').uploadBinary(songPath, _selectedSong!.bytes!);
      final songUrl = supabase.storage.from('songs-bucket').getPublicUrl(songPath);

      // Upload lyrics if provided
      String? lyricsUrl;
      if (_selectedLyrics != null && _selectedLyrics!.bytes != null) {
        final lyricsPath = 'lyrics/$timestamp-${_selectedLyrics!.name}';
        await supabase.storage.from('songs-bucket').uploadBinary(lyricsPath, _selectedLyrics!.bytes!);
        lyricsUrl = supabase.storage.from('songs-bucket').getPublicUrl(lyricsPath);
      }

      // Insert metadata into Supabase
      await supabase.from('songs').insert({
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'genre': _genreController.text.trim(),
        'language': _languageController.text.trim(),
        'song_url': songUrl,
        'lyrics_url': lyricsUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎵 Song submitted successfully!')),
      );

      // Clear form
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text(
                'Submit Your Song',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),

              // Song file picker button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickSongFile,
                  icon: const Icon(Icons.upload_file, color: Colors.deepPurple),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _selectedSong == null ? 'Choose Song File' : 'Change Song File',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepPurple, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.deepPurple.withOpacity(0.05),
                  ),
                ),
              ),
              if (_selectedSong != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected: ${_selectedSong!.name}',
                          style: const TextStyle(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              _buildInputField('Title', _titleController),
              _buildInputField('Genre', _genreController),
              _buildInputField('Language', _languageController),

              // Lyrics file picker button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickLyricsFile,
                  icon: const Icon(Icons.upload_file, color: Colors.deepPurple),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _selectedLyrics == null ? 'Upload Lyrics File' : 'Change Lyrics File',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepPurple, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.deepPurple.withOpacity(0.05),
                  ),
                ),
              ),
              if (_selectedLyrics != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lyrics: ${_selectedLyrics!.name}',
                          style: const TextStyle(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Submit button or loading indicator
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.cloud_upload, color: Colors.white),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Submit',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
