import 'package:flutter/material.dart';
import '../constrants/colors.dart';
import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../utils/formatters.dart';
import 'auth_widgets.dart';
import 'buttons.dart';
import 'report_detail_sheet.dart';
import 'status_chip.dart';

/// Sheet untuk admin: lihat laporan lengkap + ubah status dan catatan.
void showAdminReportSheet(BuildContext context, Report report) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AdminReportSheet(report: report),
  );
}

class AdminReportSheet extends StatefulWidget {
  final Report report;

  const AdminReportSheet({super.key, required this.report});

  @override
  State<AdminReportSheet> createState() => _AdminReportSheetState();
}

class _AdminReportSheetState extends State<AdminReportSheet> {
  late ReportStatus _status = widget.report.status;
  late final TextEditingController _noteC =
      TextEditingController(text: widget.report.catatan);
  bool _saving = false;

  @override
  void dispose() {
    _noteC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ReportService.instance.updateStatus(
        id: widget.report.id,
        status: _status,
        catatan: _noteC.text,
        adminUid: uid,
      );
      navigator.pop();
      showAppSnackBar(messenger, 'Laporan ${widget.report.nomor} diperbarui.');
    } on ReportException catch (e) {
      showAppSnackBar(messenger, e.message, isError: true);
    } catch (_) {
      showAppSnackBar(messenger, 'Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.nomor,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
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
              const SizedBox(height: 16),
              DetailRow(label: 'Kategori', value: r.category.label),
              DetailRow(label: 'Lokasi kejadian', value: r.lokasi),
              DetailRow(
                label: 'Tanggal kejadian',
                value: r.tanggalKejadian == null ? '-' : formatTanggalPanjang(r.tanggalKejadian!),
              ),
              DetailRow(
                label: 'Identitas pelapor',
                value: r.anonim ? 'Ingin disamarkan' : 'Boleh ditampilkan',
              ),
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
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textDark),
              ),
              const Divider(height: 32, color: AppColors.border),

              const Text(
                'Ubah status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in ReportStatus.values)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _saving ? null : () => setState(() => _status = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: _status == s ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _status == s ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          s.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _status == s ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteC,
                enabled: !_saving,
                maxLength: 200,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Catatan untuk pelapor',
                  hintText: 'Contoh: Petugas Dinas PU sedang meninjau lokasi',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Simpan perubahan',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
