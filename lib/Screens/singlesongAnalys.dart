import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SingleSongAnalysisScreen extends StatefulWidget {
  final String songId;

  const SingleSongAnalysisScreen({Key? key, required this.songId})
      : super(key: key);

  @override
  State<SingleSongAnalysisScreen> createState() =>
      _SingleSongAnalysisScreenState();
}

class _SingleSongAnalysisScreenState extends State<SingleSongAnalysisScreen> {
  Map<String, dynamic>? song;
  bool loading = true;
  String? error;
  String? lyricsText;

  @override
  void initState() {
    super.initState();
    fetchSong();
  }

  Future<void> fetchSong() async {
    setState(() {
      loading = true;
      error = null;
      lyricsText = null;
    });

    final supabase = Supabase.instance.client;

    // Try parsing the songId to int because your DB id is int
    final int? id = int.tryParse(widget.songId);
    if (id == null) {
      setState(() {
        error = 'Invalid song ID';
        loading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('songs_v2')
          .select()
          .eq('id', id)
          .single();

      song = response;

      // Fetch lyrics from .txt file if lyrics_url exists
      if (song != null && song!['lyrics_url'] != null) {
        await fetchLyrics(song!['lyrics_url']);
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load song: $e';
        loading = false;
      });
    }
  }

  Future<void> fetchLyrics(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          lyricsText = utf8.decode(response.bodyBytes);
        });
      } else {
        setState(() {
          lyricsText = 'Failed to load lyrics.';
        });
      }
    } catch (e) {
      setState(() {
        lyricsText = 'Failed to load lyrics: $e';
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'disapproved':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(song?['status']);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(song != null ? (song!['title'] ?? 'Song Details') : 'Loading...'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : song == null
                  ? const Center(child: Text('Song not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: const Icon(Icons.music_note, color: Colors.deepPurple, size: 36),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song!['title'] ?? 'Untitled',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.circle, color: statusColor, size: 12),
                                            const SizedBox(width: 6),
                                            Text(
                                              (song!['status'] ?? 'Unknown').toString().toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Quality: ${song!['quality']?.toString() ?? 'N/A'}%',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Submitted: ${song!['created_at']?.toString().substring(0, 10) ?? 'Unknown'}',
                                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Lyrics",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: lyricsText == null
                                        ? const Center(child: CircularProgressIndicator())
                                        : SingleChildScrollView(
                                            child: Text(
                                              lyricsText!,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Analysis",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.flag, color: Colors.deepPurple, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Offensive Words: ${song!['offensive_count'] ?? 0}",
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.language, color: Colors.deepPurple, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Language: ${song!['language'] ?? 'Unknown'}",
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  // --- Offensive Words Section ---
                                  if (song!['offensive_words'] != null &&
                                      (song!['offensive_words'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    const Text(
                                      "Detected Offensive Words:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.redAccent,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: (song!['offensive_words'] as List)
                                          .map<Widget>((word) => Chip(
                                                label: Text(
                                                  word.toString(),
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                                backgroundColor: Colors.redAccent,
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
