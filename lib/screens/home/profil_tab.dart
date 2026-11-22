import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/auth_widgets.dart';
import '../edit_profile_page.dart';
import '../help_page.dart';
import 'beranda_tab.dart' show displayNameOf;

class ProfilTab extends StatefulWidget {
  /// true = tampilan untuk admin (tanpa NIK / tanggal lahir).
  final bool isAdmin;

  const ProfilTab({super.key, this.isAdmin = false});

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
    // Ambil status verifikasi email terbaru.
    AuthService.instance.refreshUser().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// 3273123456780001 -> 3273 •••• •••• 0001
  String _maskNik(String nik) {
    if (nik.length != 16) return nik;
    return '${nik.substring(0, 4)} •••• •••• ${nik.substring(12)}';
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

  Future<void> _sendPasswordReset(String email) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.instance.sendPasswordReset(email);
      showAppSnackBar(messenger, 'Tautan ubah kata sandi dikirim ke $email.');
    } on AuthException catch (e) {
      showAppSnackBar(messenger, e.message, isError: true);
    }
  }

  void _showSecurity(String email) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Keamanan akun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                title: const Text('Ubah kata sandi'),
                subtitle: Text('Kami kirim tautan ke $email'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _sendPasswordReset(email);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
          final alamat = (profile?['alamat'] as String?) ?? '';
          final nik = (profile?['nik'] as String?) ?? '';
          final dob = (profile?['tanggalLahir'] as Timestamp?)?.toDate();
          final since = (profile?['createdAt'] as Timestamp?)?.toDate();
          final verified = user?.emailVerified ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profil saya',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: profile == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditProfilePage(
                                  profile: profile,
                                  isAdmin: widget.isAdmin,
                                ),
                              ),
                            ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Kartu identitas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (verified)
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Akun terverifikasi',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _sendVerification,
                        child: const Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 16, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text(
                              'Email belum diverifikasi · Kirim verifikasi',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isAdmin
                          ? 'Administrator Siap Lapor'
                          : since == null
                              ? 'Warga Siap Lapor'
                              : 'Warga sejak ${formatBulanTahun(since)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Biodata diri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                children: [
                  _BioRow(label: 'Nama lengkap', value: nama),
                  if (!widget.isAdmin)
                    _BioRow(label: 'NIK', value: nik.isEmpty ? '' : _maskNik(nik)),
                  _BioRow(label: 'Email', value: email),
                  _BioRow(label: 'Nomor ponsel', value: telepon),
                  if (!widget.isAdmin)
                    _BioRow(
                      label: 'Tanggal lahir',
                      value: dob == null ? '' : formatTanggalPanjang(dob),
                    ),
                  _BioRow(label: 'Alamat domisili', value: alamat),
                ],
              ),
              const SizedBox(height: 16),
              const InfoBox(
                message: 'Biodata Anda digunakan untuk verifikasi dan tindak lanjut pengaduan Anda.',
              ),
              const SizedBox(height: 16),

              _Card(
                children: [
                  _MenuTile(
                    icon: Icons.shield_outlined,
                    label: 'Keamanan akun',
                    onTap: () => _showSecurity(email),
                  ),
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Pusat bantuan',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Keluar dari akun',
                    color: AppColors.danger,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kartu putih; anak-anaknya dipisah garis tipis.
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color == AppColors.danger ? color : AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
