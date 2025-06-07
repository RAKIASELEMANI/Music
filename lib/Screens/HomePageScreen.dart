import 'package:flutter/material.dart';
import 'package:music/Screens/AnalysisScreen.dart';
import 'package:music/Screens/DashboardScreen.dart';
import 'package:music/Screens/submitSong.dart';
import 'package:music/Screens/profile.dart'; // <-- Add this import

class HomePage extends StatefulWidget {
  final String? artist_name;
  final String? first_name;
  final String? last_name;

  const HomePage({
    Key? key,
    this.artist_name,
    this.first_name,
    this.last_name,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  String get initials {
    String first = (widget.first_name ?? '').isNotEmpty ? widget.first_name![0] : '';
    String last = (widget.last_name ?? '').isNotEmpty ? widget.last_name![0] : '';
    return (first + last).toUpperCase();
  }

  final List<Widget> _pages = [
    DashboardScreen(),
    SubmitSongScreen(),
    AnalysisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Welcome, ',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Text(
                  widget.artist_name ?? "",
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  initials.isNotEmpty ? initials : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Submit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
        ],
      ),
    );
  }
}