import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/report_detail_sheet.dart';
import '../../widgets/status_chip.dart';

class LaporanTab extends StatefulWidget {
  final VoidCallback onCreateReport;

  const LaporanTab({super.key, required this.onCreateReport});

  @override
  State<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<LaporanTab> {
  late final Stream<List<Report>> _stream;
  final _searchC = TextEditingController();

  String _query = '';
  ReportStatus? _filter; // null = Semua
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    final uid = AuthService.instance.currentUser?.uid;
    _stream = uid == null
        ? const Stream.empty()
        : ReportService.instance.watchMyReports(uid);
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<Report> _apply(List<Report> all) {
    final q = _query.trim().toLowerCase();
    var list = all.where((r) {
      if (_filter != null && r.status != _filter) return false;
      if (q.isEmpty) return true;
      return r.title.toLowerCase().contains(q) ||
          r.nomor.toLowerCase().contains(q) ||
          r.lokasi.toLowerCase().contains(q);
    }).toList();
    if (!_newestFirst) list = list.reversed.toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Report>>(
        stream: _stream,
        builder: (context, snap) {
          final all = snap.data ?? const <Report>[];
          final shown = _apply(all);
          int count(ReportStatus s) => all.where((r) => r.status == s).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              const Text(
                'Laporan Saya',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pantau setiap langkah tindak lanjut aduan.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Pencarian
              TextField(
                controller: _searchC,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Cari judul atau nomor laporan',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: () => setState(() {
                            _searchC.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter status
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua (${all.length})',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final s in ReportStatus.values) ...[
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '${s.label} (${count(s)})',
                        selected: _filter == s,
                        onTap: () => setState(() => _filter = s),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Jumlah + urutan
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${shown.length} laporan ditemukan',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _newestFirst = !_newestFirst),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _newestFirst ? 'Terbaru' : 'Terlama',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (snap.hasError)
                const _Empty(
                  icon: Icons.cloud_off_rounded,
                  title: 'Laporan belum bisa dimuat',
                  message: 'Periksa koneksi internet dan aturan Firestore, lalu buka ulang aplikasi.',
                )
              else if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (all.isEmpty)
                _Empty(
                  icon: Icons.inbox_outlined,
                  title: 'Belum ada laporan',
                  message: 'Pengaduan yang Anda kirim akan muncul di sini lengkap dengan statusnya.',
                  actionLabel: 'Buat pengaduan',
                  onAction: widget.onCreateReport,
                )
              else if (shown.isEmpty)
                const _Empty(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak ada yang cocok',
                  message: 'Coba kata kunci lain atau ubah filter status.',
                )
              else
                for (final r in shown) ...[
                  _ReportCard(report: r),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showReportDetail(context, report),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${report.nomor} · ${formatTanggal(report.createdAt ?? DateTime.now())}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                  StatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                report.category.shortLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ReportStatusIcon(status: report.status, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      report.statusNote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
