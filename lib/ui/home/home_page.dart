import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/ai_screen.dart';
import '../profile/profile_screen.dart';
import '../../repositories/recipe_repository.dart';
import '../saved/saved_screen.dart';
import '../../stores/home_store.dart';
import '../../theme/app_theme.dart';
import 'home_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final HomeStore _homeStore;

  List<Widget> get _tabs => [
        Provider<HomeStore>.value(
          value: _homeStore,
          child: const HomeView(),
        ),
        const SavedScreen(),
        const AiScreen(),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    final repository = RecipeRepository();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    _homeStore = HomeStore(repository)..init(userId: userId);
  }

  @override
  void dispose() {
    _homeStore.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        selectedItemColor: AppTheme.buttonRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
