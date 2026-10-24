/// Contoh: "Baru saja", "5 mnt lalu", "2 jam lalu", "3 hari lalu", "12 Okt 2026".
String timeAgo(DateTime? time) {
  if (time == null) return 'Baru saja';

  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';

  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${time.day} ${bulan[time.month - 1]} ${time.year}';
}
