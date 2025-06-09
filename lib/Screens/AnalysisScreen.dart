import 'package:flutter/material.dart';
import 'package:music/Screens/song/SongListScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _loading = true;
  int totalSongs = 0;
  int approvedSongs = 0;
  int pendingSongs = 0;
  int disapprovedSongs = 0;
  double avgQuality = 0.0;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // Fetch all statuses for this user only
    final statusResponse = await supabase
        .from('songs_v2')
        .select('status')
        .eq('user_id', user.id);

    final List data = statusResponse;
    int total = data.length;
    int approved = data.where((row) => row['status'] == 'approved').length;
    int pending = data.where((row) => row['status'] == 'pending').length;
    int disapproved = data.where((row) => row['status'] == 'rejected').length; // <-- changed here

    // Fetch all quality values for this user only
    final qualityResponse = await supabase
        .from('songs_v2')
        .select('quality')
        .eq('user_id', user.id)
        .not('quality', 'is', null);

    double avgQ = 0.0;
    if (qualityResponse != null && qualityResponse.isNotEmpty) {
      final qualities = qualityResponse
          .map((e) => (e['quality'] as num).toDouble())
          .toList();
      avgQ = qualities.reduce((a, b) => a + b) / qualities.length;
    }

    if (!mounted) return;
    setState(() {
      totalSongs = total;
      approvedSongs = approved;
      pendingSongs = pending;
      disapprovedSongs = disapproved;
      avgQuality = avgQ;
      _loading = false;
    });
  }

  Widget _statCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.13),
              color.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qualityCard() {
    return Card(
      elevation: 0,
      color: Colors.amber[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 28),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(14),
              child: Icon(Icons.emoji_events, color: Colors.amber[800], size: 32),
            ),
            const SizedBox(width: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Average Music Quality',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
                const SizedBox(height: 4),
                Text('${avgQuality.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0, left: 2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple[100],
            child: const Icon(Icons.analytics, color: Colors.deepPurple, size: 28),
          ),
          const SizedBox(width: 14),
          const Text(
            "Music Analytics Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.deepPurple,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
     
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dashboardHeader(),
                  _statCard(
                    label: 'Total Songs',
                    value: totalSongs,
                    color: Colors.deepPurple,
                    icon: Icons.library_music,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(status: null),
                        ),
                      );
                    },
                  ),
                  _statCard(
                    label: 'Approved',
                    value: approvedSongs,
                    color: Colors.green,
                    icon: Icons.check_circle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(status: 'approved'),
                        ),
                      );
                    },
                  ),
                  _statCard(
                    label: 'Pending',
                    value: pendingSongs,
                    color: Colors.orange,
                    icon: Icons.hourglass_empty,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(status: 'pending'),
                        ),
                      );
                    },
                  ),
                  _statCard(
                    label: 'Disapproved',
                    value: disapprovedSongs,
                    color: Colors.red,
                    icon: Icons.cancel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongListScreen(status: 'rejected'), // <-- changed here
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _qualityCard(),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 0,
                    color: Colors.deepPurple.withOpacity(0.07),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.deepPurple, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Tap any card above to view the list of songs in that category. "
                              "You can then tap a song to see its full analysis report.",
                              style: TextStyle(color: Colors.deepPurple[700], fontSize: 15),
                            ),
                          ),
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