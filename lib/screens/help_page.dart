import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constrants/colors.dart';
import '../widgets/auth_widgets.dart';

// GANTI dengan kontak resmi layanan Anda.
const _kontakEmail = 'bantuan@bekasikota.go.id';
const _kontakTelepon = '0812 3456 7890';

/// Halaman Pusat bantuan. Dibuka dari Profil (Pusat bantuan) dan
/// dari halaman Lupa kata sandi (Hubungi bantuan).
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faq = <(String, String)>[
    (
      'Bagaimana cara membuat pengaduan?',
      'Buka menu Buat aduan, isi judul, kategori, tanggal, lokasi, dan isi pengaduan, lalu tekan Kirim pengaduan.',
    ),
    (
      'Bagaimana memantau status laporan saya?',
      'Buka menu Laporan. Setiap laporan menampilkan status Menunggu, Diproses, atau Selesai beserta catatan dari petugas.',
    ),
    (
      'Apakah identitas saya bisa disembunyikan?',
      'Bisa. Aktifkan Samarkan identitas saya saat membuat pengaduan. Nama Anda tidak ditampilkan kepada publik.',
    ),
    (
      'Saya lupa kata sandi, apa yang harus dilakukan?',
      'Di halaman Masuk, tekan Lupa kata sandi lalu masukkan email terdaftar. Tautan reset akan dikirim ke email Anda.',
    ),
    (
      'Berapa lama laporan ditindaklanjuti?',
      'Lama penanganan bergantung pada jenis laporan dan dinas terkait. Pantau pembaruan di menu Laporan.',
    ),
  ];

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    showAppSnackBar(ScaffoldMessenger.of(context), '$label disalin.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat bantuan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Temukan jawaban atau hubungi kami.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Pertanyaan yang sering diajukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    for (var i = 0; i < _faq.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: AppColors.border),
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.textMuted,
                        title: Text(
                          _faq[i].$1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        children: [
                          Text(
                            _faq[i].$2,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Masih butuh bantuan?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.mail_outline_rounded,
              label: 'Email bantuan',
              value: _kontakEmail,
              onTap: () => _copy(context, 'Email', _kontakEmail),
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.phone_outlined,
              label: 'Telepon layanan',
              value: _kontakTelepon,
              onTap: () => _copy(context, 'Nomor telepon', _kontakTelepon),
            ),
            const SizedBox(height: 16),
            const InfoBox(
              message: 'Ketuk kontak untuk menyalin. Layanan bantuan aktif pada jam kerja.',
            ),
            const SizedBox(height: 24),
            const SecureFooter(),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
              const Icon(Icons.copy_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
