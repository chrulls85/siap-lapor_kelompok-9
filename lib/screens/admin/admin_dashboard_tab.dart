import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/admin_report_sheet.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/stat_card.dart';

class AdminDashboardTab extends StatefulWidget {
  /// Dipanggil oleh tautan "Lihat semua" -> pindah ke tab Laporan admin.
  final VoidCallback onSeeAll;

  const AdminDashboardTab({super.key, required this.onSeeAll});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  late final Stream<List<Report>> _stream = ReportService.instance.watchAllReports();
  bool _thisMonthOnly = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Report>>(
        stream: _stream,
        builder: (context, snap) {
          final all = snap.data ?? const <Report>[];
          final now = DateTime.now();

          // Ringkasan mengikuti filter periode.
          final period = _thisMonthOnly
              ? all.where((r) => isSameMonth(r.createdAt ?? now, now)).toList()
              : all;
          int count(ReportStatus s) => period.where((r) => r.status == s).length;
          final total = period.length;
          final selesai = count(ReportStatus.selesai);
          final percent = total == 0 ? 0 : (selesai * 100 / total).round();

          // Prioritas = laporan "menunggu" yang paling lama belum disentuh.
          final waiting = all.where((r) => r.status == ReportStatus.menunggu).toList();
          final urgent = waiting.isEmpty ? null : waiting.last; // list terbaru -> terlama

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
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
                      'Dasbor admin',
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
                      'Admin aktif',
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
                'Pantau dan tindak lanjuti aduan warga.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 22),

              // Ringkasan
              Row(
                children: [
                  const Expanded(child: _Title('Ringkasan laporan')),
                  PopupMenuButton<bool>(
                    initialValue: _thisMonthOnly,
                    onSelected: (v) => setState(() => _thisMonthOnly = v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: true, child: Text('Bulan ini')),
                      PopupMenuItem(value: false, child: Text('Semua waktu')),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _thisMonthOnly ? 'Bulan ini' : 'Semua waktu',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total pengaduan',
                            style: TextStyle(fontSize: 12, color: Color(0xFFC7D5F2)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'laporan terselesaikan',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFFC7D5F2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      value: count(ReportStatus.menunggu),
                      label: 'Menunggu',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      value: count(ReportStatus.diproses),
                      label: 'Diproses',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      value: selesai,
                      label: 'Selesai',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Prioritas
              Row(
                children: [
                  const Expanded(child: _Title('Prioritas tindak lanjut')),
                  _SeeAll(onTap: widget.onSeeAll),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.hasError)
                const _Note(
                  icon: Icons.cloud_off_rounded,
                  text: 'Data belum bisa dimuat. Pastikan akun ini role-nya admin dan firestore.rules terbaru sudah di-Publish.',
                )
              else if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (urgent == null)
                const _Note(
                  icon: Icons.task_alt_rounded,
                  text: 'Tidak ada laporan yang menunggu. Kerja bagus!',
                )
              else
                _PriorityCard(report: urgent),
              const SizedBox(height: 24),

              // Laporan masuk
              Row(
                children: [
                  const Expanded(child: _Title('Laporan masuk')),
                  _SeeAll(onTap: widget.onSeeAll),
                ],
              ),
              const SizedBox(height: 12),
              if (all.isEmpty && snap.connectionState != ConnectionState.waiting && !snap.hasError)
                const _Note(
                  icon: Icons.inbox_outlined,
                  text: 'Belum ada laporan masuk dari warga.',
                ),
              for (final r in all.take(3)) ...[
                _IncomingTile(report: r),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

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

class _SeeAll extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeAll({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Text(
        'Lihat semua',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final Report report;
  const _PriorityCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(report.createdAt ?? DateTime.now()).inDays;
    final high = days >= 3;
    final chipBg = high ? const Color(0xFFFEE2E2) : AppColors.primarySoft;
    final chipFg = high ? AppColors.danger : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(high ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                        size: 14, color: chipFg),
                    const SizedBox(width: 5),
                    Text(
                      high ? 'Prioritas tinggi' : 'Perlu ditinjau',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: chipFg),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                days < 1 ? 'Masuk hari ini' : 'Menunggu $days hari',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.nomor} · ${report.lokasi}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            report.statusNote,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TextButton.icon(
              onPressed: () => showAdminReportSheet(context, report),
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
              label: const Text(
                'Proses laporan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingTile extends StatelessWidget {
  final Report report;
  const _IncomingTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final Color tag;
    switch (report.status) {
      case ReportStatus.menunggu:
        tag = AppColors.primary;
      case ReportStatus.diproses:
        tag = AppColors.warning;
      case ReportStatus.selesai:
        tag = AppColors.success;
    }
    final label = report.status == ReportStatus.menunggu ? 'Baru' : report.status.label;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showAdminReportSheet(context, report),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(report.category.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: tag,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo(report.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report.lokasi} · ${report.nomor}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
