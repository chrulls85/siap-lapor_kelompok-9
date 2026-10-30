import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../services/auth_service.dart';
import 'beranda_tab.dart' show displayNameOf;

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  late final Stream<Map<String, dynamic>?> _profile;

  @override
  void initState() {
    super.initState();
    final uid = AuthService.instance.currentUser?.uid;
    _profile = uid == null
        ? const Stream.empty()
        : AuthService.instance.watchProfile(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return SafeArea(
      bottom: false,
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _profile,
        builder: (context, snap) {
          final profile = snap.data;
          final nama = displayNameOf(user, profile);
          final email = (profile?['email'] as String?) ?? user?.email ?? '-';
          final telepon = (profile?['telepon'] as String?) ?? '-';
          final alamat = (profile?['alamat'] as String?) ?? '-';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    nama.isEmpty ? '?' : String.fromCharCode(nama.runes.first).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.mail_outline, label: 'Email', value: email),
                    const Divider(height: 24, color: AppColors.border),
                    _InfoRow(icon: Icons.phone_outlined, label: 'Nomor ponsel', value: telepon),
                    const Divider(height: 24, color: AppColors.border),
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Alamat domisili', value: alamat),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => AuthService.instance.signOut(),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Keluar dari akun',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
