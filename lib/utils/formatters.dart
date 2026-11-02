const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _dua(int n) => n.toString().padLeft(2, '0');

/// Contoh: "08 Okt 2026".
String formatTanggal(DateTime d) => '${_dua(d.day)} ${_bulanPendek[d.month - 1]} ${d.year}';

/// Contoh: "08 Oktober 2026".
String formatTanggalPanjang(DateTime d) =>
    '${_dua(d.day)} ${_bulanPanjang[d.month - 1]} ${d.year}';

/// Contoh: "Baru saja", "5 mnt lalu", "2 jam lalu", "3 hari lalu", "12 Okt 2026".
String timeAgo(DateTime? time) {
  if (time == null) return 'Baru saja';

  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatTanggal(time);
}
