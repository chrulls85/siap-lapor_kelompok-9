import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import '../edit_profile_page.dart';
import '../home/beranda_tab.dart' show displayNameOf;

/// Profil untuk akun admin, mengikuti desain Figma "Profil admin".
class AdminProfilTab extends StatefulWidget {
  const AdminProfilTab({super.key});

  @override
  State<AdminProfilTab> createState() => _AdminProfilTabState();
}

class _AdminProfilTabState extends State<AdminProfilTab> {
  late final Stream<Map<String, dynamic>?> _profile;
  bool _notifikasi = true; // sementara hanya tersimpan selama aplikasi terbuka

  @override
  void initState() {
    super.initState();
    final uid = AuthService.instance.currentUser?.uid;
    _profile = uid == null
        ? const Stream.empty()
        : AuthService.instance.watchProfile(uid);
    AuthService.instance.refreshUser().then((_) {
      if (mounted) setState(() {});
    });
  }

  String _initials(String nama) {
    final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _sendPasswordReset(String email) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.instance.sendPasswordReset(email);
      showAppSnackBar(messenger, 'Tautan ubah kata sandi dikirim ke $email.');
    } on AuthException catch (e) {
      showAppSnackBar(messenger, e.message, isError: true);
    }
  }

  Future<void> _sendVerification() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.instance.sendEmailVerification();
      showAppSnackBar(messenger, 'Tautan verifikasi dikirim. Periksa email Anda (termasuk folder spam).');
    } on AuthException catch (e) {
      showAppSnackBar(messenger, e.message, isError: true);
    }
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk memakai Siap Lapor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (yes == true) await AuthService.instance.signOut();
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
          final telepon = (profile?['telepon'] as String?) ?? '';
          final instansi = (profile?['instansi'] as String?)?.trim().isNotEmpty == true
              ? profile!['instansi'] as String
              : 'Admin Siap Lapor';
          final wilayah = (profile?['wilayah'] as String?)?.trim().isNotEmpty == true
              ? profile!['wilayah'] as String
              : ((profile?['alamat'] as String?) ?? '');
          final verified = user?.emailVerified ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Bar atas: logo + notifikasi
              Row(
                children: [
                  const Expanded(child: Align(alignment: Alignment.centerLeft, child: AuthHeader())),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => showAppSnackBar(
                        ScaffoldMessenger.of(context),
                        'Belum ada notifikasi baru.',
                      ),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profil admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Admin kota',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola biodata dan keamanan akun Anda.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),

              // Kartu identitas (navy)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _initials(nama),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            instansi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFFC7D5F2)),
                          ),
                          const SizedBox(height: 6),
                          if (verified)
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 15, color: Color(0xFFC7D5F2)),
                                SizedBox(width: 6),
                                Text(
                                  'Admin terverifikasi',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFC7D5F2)),
                                ),
                              ],
                            )
                          else
                            InkWell(
                              onTap: _sendVerification,
                              child: const Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFFDE68A)),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Email belum diverifikasi · Kirim verifikasi',
                                      style: TextStyle(fontSize: 12, color: Color(0xFFFDE68A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Biodata
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Biodata',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: profile == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditProfilePage(profile: profile, isAdmin: true),
                              ),
                            ),
                    child: const Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Card(
                children: [
                  _BioRow(label: 'Email dinas', value: email),
                  _BioRow(label: 'Nomor telepon', value: telepon),
                  _BioRow(label: 'Wilayah layanan', value: wilayah),
                ],
              ),
              const SizedBox(height: 24),

              // Pengaturan akun
              const Text(
                'Pengaturan akun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                children: [
                  _SettingTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Ubah kata sandi',
                    subtitle: 'Jaga keamanan akun Anda',
                    onTap: () => _sendPasswordReset(email),
                  ),
                  _SettingTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Verifikasi dua langkah',
                    subtitle: 'Segera hadir · akun lebih terlindungi',
                    onTap: () => showAppSnackBar(
                      ScaffoldMessenger.of(context),
                      'Verifikasi dua langkah belum tersedia.',
                    ),
                  ),
                  _SettingTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifikasi laporan',
                    subtitle: 'Aduan baru dan pembaruan status',
                    trailing: Switch(
                      value: _notifikasi,
                      onChanged: (v) => setState(() => _notifikasi = v),
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      trackColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Keluar
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _confirmLogout,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 20, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text(
                          'Keluar dari akun',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Siap Lapor · Versi 1.0.0',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _BioRow extends StatelessWidget {
  final String label;
  final String value;
  const _BioRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 3),
            Text(
              empty ? 'Belum diisi' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: empty ? FontWeight.normal : FontWeight.w600,
                color: empty ? AppColors.textMuted : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
