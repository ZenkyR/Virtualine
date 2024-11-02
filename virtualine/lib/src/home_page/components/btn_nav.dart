import 'package:flutter/material.dart';
import '../../../set_stats.dart';

class NavBttn extends StatefulWidget {
  const NavBttn({super.key});

  @override
  State<NavBttn> createState() => _NavBttnState();
}

class _NavBttnState extends State<NavBttn> {
  void _onItemTapped(int index) {
    setState(() {
      navIndex.value = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.brush),
            label: 'Dessin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_filter),
            label: 'Animation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.audiotrack),
            label: 'Son',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Constructeur',
          ),
        ],
        currentIndex: navIndex.value,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
