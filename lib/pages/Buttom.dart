import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'package:fe/pages/homepage.dart';
import 'package:fe/pages/like.dart';
import 'package:fe/pages/tambah.dart';
import 'package:fe/pages/keranjang.dart';
import 'package:fe/pages/profile.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  int homeRefreshKey = 0;

  Future<void> _handleProductAdded() async {
    setState(() {
      selectedIndex = 0;
      homeRefreshKey++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produk berhasil ditambahkan!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomePage(key: ValueKey(homeRefreshKey)),
          const FavoritePage(),
          AddProductPage(onProductAdded: _handleProductAdded),
          CartPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home_outlined),
            title: const Text(''),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.favorite_border),
            title: const Text(''),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.add),
            title: const Text(''),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            title: const Text(''),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person_outline),
            title: const Text(''),
          ),
        ],
      ),
    );
  }
}
