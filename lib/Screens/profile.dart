import 'package:flutter/material.dart';
import 'package:music/Screens/LoginScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String artistName = '';
  String firstName = '';
  String lastName = '';
  String userEmail = '';
  String userJoinDate = '';
  String phone = '';
  String userId = '';
  int id = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    final userProfile = await supabase
        .from('users')
        .select('id, user_id, artist_name, first_name, last_name, email, phone, created_at')
        .eq('user_id', user.id)
        .maybeSingle();

    setState(() {
      id = userProfile?['id'] ?? 0;
      userId = userProfile?['user_id'] ?? '';
      artistName = userProfile?['artist_name'] ?? '';
      firstName = userProfile?['first_name'] ?? '';
      lastName = userProfile?['last_name'] ?? '';
      userEmail = userProfile?['email'] ?? '';
      userJoinDate = userProfile?['created_at']?.toString().substring(0, 10) ?? '';
      phone = userProfile?['phone'] ?? '';
      loading = false;
    });
  }

  Future<void> _logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
    // Replace with your login route if different
  }

  Widget _profileTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.deepPurple).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor ?? Colors.deepPurple, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String initials = artistName.isNotEmpty
        ? artistName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.transparent,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    artistName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                  if (firstName.isNotEmpty || lastName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "$firstName $lastName",
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 22, horizontal: 20),
                      child: Column(
                        children: [
                          _profileTile(
                              icon: Icons.badge,
                              label: 'User ID',
                              value: userId,
                              iconColor: Colors.deepPurple),
                          const Divider(height: 24),
                          _profileTile(
                              icon: Icons.numbers,
                              label: 'Profile ID',
                              value: id.toString(),
                              iconColor: Colors.indigo),
                          const Divider(height: 24),
                          _profileTile(
                              icon: Icons.email,
                              label: 'Email',
                              value: userEmail,
                              iconColor: Colors.blue),
                          const Divider(height: 24),
                          _profileTile(
                              icon: Icons.phone,
                              label: 'Phone',
                              value: phone,
                              iconColor: Colors.green),
                          const Divider(height: 24),
                          _profileTile(
                              icon: Icons.calendar_today,
                              label: 'Joined',
                              value: userJoinDate,
                              iconColor: Colors.orange),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
