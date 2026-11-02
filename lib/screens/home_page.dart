import 'package:flutter/material.dart';
import '../constrants/colors.dart';
import '../models/report.dart';
import 'home/beranda_tab.dart';
import 'home/buat_aduan_tab.dart';
import 'home/laporan_tab.dart';
import 'home/profil_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  ReportCategory? _presetCategory; // kategori yang dipilih dari Beranda

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: IndexedStack(
        index: _index,
        children: [
          BerandaTab(
            onCreateReport: () => _go(2),
            onSeeAllReports: () => _go(1),
            onPickCategory: (c) => setState(() {
              _presetCategory = c;
              _index = 2;
            }),
          ),
          LaporanTab(onCreateReport: () => _go(2)),
          BuatAduanTab(
            presetCategory: _presetCategory,
            onBack: () => _go(0),
            onSubmitted: () => setState(() {
              _presetCategory = null;
              _index = 1;
            }),
          ),
          const ProfilTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Buat aduan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
