import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/status_chip.dart';

/// Nama untuk sapaan: dari profil Firestore, lalu dari Auth, lalu "Warga".
String displayNameOf(User? user, Map<String, dynamic>? profile) {
  final fromProfile = profile?['nama'];
  if (fromProfile is String && fromProfile.trim().isNotEmpty) return fromProfile;
  final fromAuth = user?.displayName;
  if (fromAuth != null && fromAuth.trim().isNotEmpty) return fromAuth;
  return 'Warga';
}

class BerandaTab extends StatefulWidget {
  final VoidCallback onCreateReport;
  final VoidCallback onSeeAllReports;

  const BerandaTab({
    super.key,
    required this.onCreateReport,
    required this.onSeeAllReports,
  });

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  late final User? _user;
  late final Stream<Map<String, dynamic>?> _profile;
  late final Stream<List<Report>> _reports;

  @override
  void initState() {
    super.initState();
    _user = AuthService.instance.currentUser;
    final uid = _user?.uid;
    // Stream dibuat sekali di sini supaya tidak berlangganan ulang tiap rebuild.
    _profile = uid == null
        ? const Stream.empty()
        : AuthService.instance.watchProfile(uid);
    _reports = uid == null
        ? const Stream.empty()
        : ReportService.instance.watchMyReports(uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _profile,
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          final nama = displayNameOf(_user, profile);
          final alamat = (profile?['alamat'] as String?)?.trim() ?? '';

          return StreamBuilder<List<Report>>(
            stream: _reports,
            builder: (context, reportSnap) {
              if (reportSnap.hasError) {
                debugPrint('Gagal memuat laporan: ${reportSnap.error}');
              }
              final reports = reportSnap.data ?? const <Report>[];
              final diproses =
                  reports.where((r) => r.status == ReportStatus.diproses).length;
              final selesai =
                  reports.where((r) => r.status == ReportStatus.selesai).length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _Header(nama: nama, alamat: alamat),
                  const SizedBox(height: 20),
                  _HeroCard(onCreateReport: widget.onCreateReport),
                  const SizedBox(height: 24),

                  const _SectionTitle('Laporan Anda'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: reports.length,
                          label: 'Total laporan',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: diproses,
                          label: 'Diproses',
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: selesai,
                          label: 'Selesai',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const _SectionTitle('Apa yang ingin Anda laporkan?'),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CategoryItem(
                        icon: Icons.add_road_rounded,
                        label: 'Jalan & fasilitas',
                        onTap: widget.onCreateReport,
                      ),
                      _CategoryItem(
                        icon: Icons.cleaning_services_outlined,
                        label: 'Kebersihan',
                        onTap: widget.onCreateReport,
                      ),
                      _CategoryItem(
                        icon: Icons.account_balance_outlined,
                        label: 'Pelayanan',
                        onTap: widget.onCreateReport,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(child: _SectionTitle('Pembaruan terbaru')),
                      GestureDetector(
                        onTap: widget.onSeeAllReports,
                        child: const Text(
                          'Lihat semua',
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
                  if (reports.isEmpty)
                    _EmptyReports(
                      loading: reportSnap.connectionState ==
                          ConnectionState.waiting,
                      failed: reportSnap.hasError,
                    )
                  else
                    for (final r in reports.take(3)) ...[
                      _ReportTile(report: r),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ Header
class _Header extends StatelessWidget {
  final String nama;
  final String alamat;

  const _Header({required this.nama, required this.alamat});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat datang,',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (alamat.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alamat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textDark,
                    size: 24,
                  ),
                  Positioned(
                    top: 11,
                    right: 12,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------- Hero
class _HeroCard extends StatelessWidget {
  final VoidCallback onCreateReport;

  const _HeroCard({required this.onCreateReport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lingkungan\nlebih baik,\nmulai dari\nAnda.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ada masalah di sekitar? Sampaikan, kami bantu tindak lanjuti.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC7D5F2),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 92,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF133A82),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  size: 50,
                  color: Color(0xFF7FA6F5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Buat pengaduan',
            icon: Icons.arrow_forward,
            onPressed: onCreateReport,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- Potongan
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Report report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(status: report.status),
              const Spacer(),
              Text(
                timeAgo(report.createdAt),
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  final bool loading;
  final bool failed;

  const _EmptyReports({required this.loading, required this.failed});

  @override
  Widget build(BuildContext context) {
    final String title;
    final String message;
    if (loading) {
      title = 'Memuat laporan...';
      message = 'Mohon tunggu sebentar.';
    } else if (failed) {
      title = 'Laporan belum bisa dimuat';
      message = 'Periksa koneksi internet dan aturan Firestore, lalu buka ulang aplikasi.';
    } else {
      title = 'Belum ada laporan';
      message = 'Tekan Buat pengaduan untuk menyampaikan masalah pertama Anda.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.inbox_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
