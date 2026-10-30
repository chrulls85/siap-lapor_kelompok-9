import 'package:flutter/material.dart';
import '../constrants/colors.dart';
import '../models/report.dart';

class StatusChip extends StatelessWidget {
  final ReportStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case ReportStatus.menunggu:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
      case ReportStatus.diproses:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
      case ReportStatus.selesai:
        bg = AppColors.successSoft;
        fg = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
