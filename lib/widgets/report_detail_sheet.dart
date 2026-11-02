import 'package:flutter/material.dart';
import '../constrants/colors.dart';
import '../models/report.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

/// Menampilkan detail satu laporan dari bawah layar.
void showReportDetail(BuildContext context, Report r) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.nomor,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                StatusChip(status: r.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              r.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),
            _StatusNote(report: r),
            const SizedBox(height: 18),
            _Row(label: 'Kategori', value: r.category.label),
            _Row(label: 'Lokasi kejadian', value: r.lokasi),
            _Row(
              label: 'Tanggal kejadian',
              value: r.tanggalKejadian == null
                  ? '-'
                  : formatTanggalPanjang(r.tanggalKejadian!),
            ),
            _Row(
              label: 'Dikirim',
              value: r.createdAt == null ? 'Baru saja' : formatTanggalPanjang(r.createdAt!),
            ),
            _Row(
              label: 'Identitas',
              value: r.anonim ? 'Disamarkan' : 'Ditampilkan',
            ),
            const SizedBox(height: 6),
            const Text(
              'Isi pengaduan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              r.description.isEmpty ? '-' : r.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusNote extends StatelessWidget {
  final Report report;

  const _StatusNote({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportStatusIcon(status: report.status),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              report.statusNote,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ikon kecil di samping keterangan status.
class ReportStatusIcon extends StatelessWidget {
  final ReportStatus status;
  final double size;

  const ReportStatusIcon({super.key, required this.status, this.size = 18});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ReportStatus.menunggu:
        return Icon(Icons.schedule_rounded, size: size, color: AppColors.primary);
      case ReportStatus.diproses:
        return Icon(Icons.timelapse_rounded, size: size, color: AppColors.warning);
      case ReportStatus.selesai:
        return Icon(Icons.check_circle_outline_rounded, size: size, color: AppColors.success);
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
