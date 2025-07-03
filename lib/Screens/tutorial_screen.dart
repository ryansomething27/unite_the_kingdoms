// lib/screens/tutorial_screen.dart
import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<TutorialPage> _pages = [
    TutorialPage(
      title: 'Welcome to Unite the Kingdoms',
      description: 'Conquer medieval England by capturing enemy towers and defending your own.',
      icon: Icons.castle,
      color: const Color(0xFFD4AF37),
    ),
    TutorialPage(
      title: 'Choose Your Faction',
      description: 'Play as Saxons for defensive strength or Danes for aggressive raids.',
      icon: Icons.shield,
      color: const Color(0xFF4CAF50),
    ),
    TutorialPage(
      title: 'Build Your Army',
      description: 'Place spawn towers to create units and archer towers for ranged support.',
      icon: Icons.add_business,
      color: const Color(0xFF2196F3),
    ),
    TutorialPage(
      title: 'Strategic Placement',
      description: 'Draw walls to protect your towers and control unit movement.',
      icon: Icons.fence,
      color: const Color(0xFF5D4037),
    ),
    TutorialPage(
      title: 'Tower Combat',
      description: 'Units automatically march to enemy towers. Capture all enemy towers to win!',
      icon: Icons.gps_fixed,
      color: const Color(0xFF8B0000),
    ),
    TutorialPage(
      title: 'Campaign Mode',
      description: 'Progress through 100 sections across 4 kingdoms. Conquer castle levels to claim each realm!',
      icon: Icons.map,
      color: const Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'SKIP',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(_pages.length, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentPage 
                          ? const Color(0xFFD4AF37)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Tutorial content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        page.icon,
                        size: 120,
                        color: page.color,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.description,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF5D4037),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0 
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  child: const Text('BACK'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'NEXT' : 'START PLAYING',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}