import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = '';
  String userInitials = '';
  String userEmail = '';
  String userJoinDate = '';
  bool loading = true;
  int totalSongs = 0;
  int accreditedSongs = 0;
  int failedSongs = 0;
  int pendingSongs = 0;
  List<Map<String, dynamic>> songs = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    // Fetch user profile using user_id (UUID stored as text)
    final userProfile = await supabase
        .from('users')
        .select('artist_name, email, created_at')
        .eq('user_id', user.id)
        .maybeSingle();

    userName = userProfile?['artist_name'] ?? 'User';
    userInitials = userName.isNotEmpty
        ? userName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';
    userEmail = userProfile?['email'] ?? '';
    userJoinDate = userProfile?['created_at']?.toString().substring(0, 10) ?? '';

    // Fetch songs where user_id matches current user.id (UUID)
    final songList = await supabase
        .from('songs_v2')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> safeSongList =
        (songList as List).map((e) => Map<String, dynamic>.from(e)).toList();

    totalSongs = safeSongList.length;
    accreditedSongs = safeSongList
        .where((s) =>
            (s['status'] ?? '').toString().toLowerCase() == 'accredited' ||
            (s['status'] ?? '').toString().toLowerCase() == 'approved')
        .length;
    failedSongs = safeSongList
        .where((s) =>
            (s['status'] ?? '').toString().toLowerCase() == 'failed' ||
            (s['status'] ?? '').toString().toLowerCase() == 'disapproved')
        .length;
    pendingSongs = safeSongList
        .where((s) => (s['status'] ?? '').toString().toLowerCase() == 'pending')
        .length;

    songs = safeSongList;

    setState(() {
      loading = false;
    });
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "accredited":
      case "approved":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "failed":
      case "disapproved":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                   
                    const SizedBox(height: 18),
                    // Stats
                    Row(
                      children: [
                        _statCard("Total Songs", totalSongs.toString()),
                        const SizedBox(width: 12),
                        _statCard(
                            "Accredited Songs", accreditedSongs.toString()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statCard("Failed Songs", failedSongs.toString()),
                        const SizedBox(width: 12),
                        _statCard("Pending Songs", pendingSongs.toString()),
                      ],
                    ),
                    const SizedBox(height: 22),
                    // Upload Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Your Songs",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.black87),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to Upload Song Screen
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Upload New Song"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Song List
                    ...songs.map((song) => _songTile(song)).toList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _songTile(Map<String, dynamic> song) {
    final status = (song["status"] ?? "").toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child:
                const Icon(Icons.music_note, color: Colors.deepPurple, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song["title"] ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  "Uploaded: ${song["created_at"]?.toString().substring(0, 10) ?? ""}",
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: statusColor(status).withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.isNotEmpty
                  ? status[0].toUpperCase() + status.substring(1)
                  : "",
              style: TextStyle(
                  color: statusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
