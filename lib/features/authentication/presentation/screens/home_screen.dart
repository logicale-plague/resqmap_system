import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00ff00),
              unselectedLabelColor: const Color.fromARGB(255, 255, 255, 255),
              labelColor: const Color(0xFF00ff00),
              tabs: const [
                Tab(text: 'Tips'),
                Tab(text: 'News'),
                Tab(text: 'NOAH'),
                Tab(text: 'USGS'),
                Tab(text: 'About'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tips Tab
                  _buildTipsTab(),
                  // News Tab
                  _buildPlaceholderTab('News'),
                  // NOAH Tab
                  _buildPlaceholderTab('NOAH'),
                  // USGS Tab
                  _buildPlaceholderTab('USGS'),
                  // About Tab
                  _buildPlaceholderTab('About'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'DISASTER\nPREPAREDNESS\nTIPS',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ff00),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.home, size: 60, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // DO'S AND DON'TS Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(color: Color(0xFFFFD700)),
                    child: const Text(
                      "DO'S AND DON'TS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    'Never assume and underestimate the extent of disaster.',
                    '(e.g. the flood will never reach the second floor, the fire is too far away from my house; the typhoon is only signal no.2).',
                    Icons.flood,
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    "Don't get carried away by rumors and/or do not spread rumors.",
                    'Only rely on verified information from legitimate sources.',
                    Icons.people,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTipItem(
                          'Obey orders from the authorities / government.',
                          '',
                          Icons.account_balance,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTipItem(
                          "When disaster strikes, don't panic. Stay calm.",
                          '',
                          Icons.sentiment_satisfied,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    'Stay focused to keep your senses alert and functioning.',
                    'Before helping someone, make sure that you yourself is safe and capable to do so.',
                    Icons.psychology,
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    'Lives and safety should be prioritized above anything else.',
                    "Don't worry about material possessions which can be replaced, however, valuable they may be.",
                    Icons.people_outline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0099ff), size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderTab(String tabName) {
    return Center(
      child: Text(
        '$tabName Content',
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
