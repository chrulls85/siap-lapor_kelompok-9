import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/admin/admin_home_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'services/auth_service.dart';

/// Penjaga pintu:
///  - belum masuk            -> halaman Masuk
///  - masuk, role = "admin"  -> Dasbor admin
///  - masuk, role lain       -> Beranda warga
/// Otomatis berpindah saat pengguna masuk, daftar, keluar, atau saat role
/// di Firestore diubah.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snapshot.data;
        if (user == null) return const LoginPage();
        return _RoleRouter(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

class _RoleRouter extends StatefulWidget {
  final String uid;
  const _RoleRouter({super.key, required this.uid});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  late final Stream<Map<String, dynamic>?> _profile =
      AuthService.instance.watchProfile(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _profile,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        // Error baca profil / profil belum ada -> perlakukan sebagai warga.
        return AuthService.isAdmin(snap.data)
            ? const AdminHomePage()
            : const HomePage();
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
