import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../widgets/coming_soon.dart';
import '../home/laporan_tab.dart';
import '../home/profil_tab.dart';
import 'admin_dashboard_tab.dart';

/// Kerangka halaman untuk akun dengan role "admin".
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: IndexedStack(
        index: _index,
        children: [
          AdminDashboardTab(onSeeAll: () => _go(1)),
          const LaporanTab(adminMode: true),
          const ComingSoonTab(icon: Icons.groups_outlined, title: 'Petugas'),
          const ProfilTab(isAdmin: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dasbor',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Petugas',
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
