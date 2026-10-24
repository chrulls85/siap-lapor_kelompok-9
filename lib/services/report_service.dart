import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  /// Laporan milik satu pengguna, terbaru di atas, diperbarui otomatis.
  ///
  /// Diurutkan di aplikasi (bukan di Firestore) supaya tidak perlu membuat
  /// composite index di Firebase Console.
  Stream<List<Report>> watchMyReports(String uid) {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Report.fromDoc).toList();
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.now();
        final tb = b.createdAt ?? DateTime.now();
        return tb.compareTo(ta);
      });
      return list;
    });
  }
}
