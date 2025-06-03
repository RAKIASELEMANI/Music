import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _songsWithArtist = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSongsWithArtist();
  }

  Future<void> _loadSongsWithArtist() async {
    setState(() {
      _loading = true;
    });

    try {
      // Fetch all songs
      final songsResponse = await supabase.from('songs').select('id, title, user_id, created_at');

      if (songsResponse == null || songsResponse is! List) {
        setState(() {
          _songsWithArtist = [];
        });
        return;
      }

      List songs = songsResponse as List;

      // Extract unique user_ids from songs
      final userIds = songs.map((song) => song['user_id']).toSet().toList();

      // Fetch user details for these user_ids
      final usersResponse = await supabase
          .from('users')
          .select('user_id, artist_name')
          .inFilter('user_id', userIds);

      if (usersResponse == null || usersResponse is! List) {
        setState(() {
          _songsWithArtist = [];
        });
        return;
      }

      List users = usersResponse as List;
      final Map<String, String> userMap = {
        for (var user in users)
          user['user_id'] as String: user['artist_name'] as String? ?? 'Unknown Artist'
      };

      // Combine song and artist data
      List<Map<String, dynamic>> combined = songs.map((song) {
        return {
          'title': song['title'],
          'artist_name': userMap[song['user_id']] ?? 'Unknown Artist',
          'created_at': song['created_at'],
        };
      }).toList();

      setState(() {
        _songsWithArtist = combined;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load songs: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String formatDate(String dateStr) {
    final dateTime = DateTime.tryParse(dateStr);
    if (dateTime == null) return 'Unknown date';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songsWithArtist.isEmpty
              ? const Center(child: Text('No songs submitted yet.'))
              : ListView.builder(
                  itemCount: _songsWithArtist.length,
                  itemBuilder: (context, index) {
                    final song = _songsWithArtist[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(song['title']),
                        subtitle: Text('Artist: ${song['artist_name']}'),
                        trailing: Text(formatDate(song['created_at'])),
                      ),
                    );
                  },
                ),
    );
  }
}
