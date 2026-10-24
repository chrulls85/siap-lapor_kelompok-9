import 'package:flutter/material.dart';
import '../constrants/colors.dart';

/// Logo + nama aplikasi di bagian atas halaman Masuk / Daftar / Lupa sandi.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Siap Lapor',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

/// Tautan "← Kembali ke masuk".
class BackLink extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const BackLink({
    super.key,
    required this.onTap,
    this.label = 'Kembali ke masuk',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: AppColors.textDark,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Data Anda aman dan terlindungi."
class SecureFooter extends StatelessWidget {
  const SecureFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 16, color: AppColors.textMuted),
        SizedBox(width: 6),
        Text(
          'Data Anda aman dan terlindungi.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

/// Kotak informasi berwarna (dipakai di halaman Lupa sandi).
class InfoBox extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;

  const InfoBox({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.background = AppColors.primarySoft,
    this.foreground = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// SnackBar seragam. Ambil `messenger` SEBELUM `await` agar aman dipakai sesudahnya.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  bool isError = false,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}
