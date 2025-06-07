import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../singlesongAnalys.dart';

class SongListScreen extends StatefulWidget {
  final String? status; // null for all, or 'approved', 'pending', 'disapproved'

  const SongListScreen({Key? key, this.status}) : super(key: key);

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  List<Map<String, dynamic>> songs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        songs = [];
        loading = false;
      });
      return;
    }
    var query = supabase.from('songs_v2').select().eq('user_id', user.id);
    if (widget.status != null) {
      query = query.eq('status', widget.status as Object);
    }
    final result = await query.order('created_at', ascending: false);
    setState(() {
      songs = List<Map<String, dynamic>>.from(result);
      loading = false;
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.library_music, color: Colors.deepPurple, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.status == null
                    ? 'All Songs'
                    : '${widget.status![0].toUpperCase()}${widget.status!.substring(1)} Songs',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
              ? const Center(child: Text('No songs found.', style: TextStyle(fontSize: 18)))
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final song = songs[i];
                    final int songId = song['id'] is int
                        ? song['id']
                        : int.tryParse(song['id'].toString()) ?? -1;
                    final statusColor = _statusColor(song['status']);
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: songId == -1
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SingleSongAnalysisScreen(songId: songId.toString()),
                                ),
                              );
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(Icons.music_note, color: Colors.deepPurple, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.circle, color: statusColor, size: 10),
                                        const SizedBox(width: 6),
                                        Text(
                                          (song['status'] ?? 'Unknown').toString().toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submitted: ${song['created_at']?.toString().substring(0, 10) ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.deepPurple),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}