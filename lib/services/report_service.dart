import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportException implements Exception {
  final String message;
  const ReportException(this.message);

  @override
  String toString() => message;
}

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('reports');

  /// Laporan milik satu pengguna, terbaru di atas, diperbarui otomatis.
  ///
  /// Diurutkan di aplikasi (bukan di Firestore) supaya tidak perlu membuat
  /// composite index di Firebase Console.
  Stream<List<Report>> watchMyReports(String uid) {
    return _col.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Report.fromDoc).toList();
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.now();
        final tb = b.createdAt ?? DateTime.now();
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// SEMUA laporan (khusus admin; aturan Firestore menolak untuk warga).
  /// Dibatasi 200 terbaru; nanti bisa dibuat per halaman.
  Stream<List<Report>> watchAllReports() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(Report.fromDoc).toList());
  }

  /// Admin mengubah status dan catatan sebuah laporan.
  Future<void> updateStatus({
    required String id,
    required ReportStatus status,
    required String catatan,
    required String adminUid,
  }) async {
    try {
      await _col.doc(id).update({
        'status': status.name,
        'catatan': catatan.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'handledBy': adminUid,
      }).timeout(const Duration(seconds: 15));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ReportException(
          'Ditolak: akun ini bukan admin atau firestore.rules belum di-Publish.',
        );
      }
      throw ReportException('Gagal menyimpan (${e.code}). Coba lagi.');
    } on TimeoutException {
      throw const ReportException('Koneksi lambat. Coba lagi sebentar.');
    }
  }

  /// Menyimpan pengaduan baru. Status awal selalu "menunggu".
  Future<void> create({
    required String uid,
    required String title,
    required ReportCategory category,
    required DateTime tanggalKejadian,
    required String lokasi,
    required String description,
    required bool anonim,
  }) async {
    final ref = _col.doc(); // ID dibuat dulu, nomor laporan diambil dari ID
    try {
      await ref.set({
        'userId': uid,
        'nomor': 'SIP-${ref.id.substring(0, 6).toUpperCase()}',
        'title': title.trim(),
        'kategori': category.name,
        'lokasi': lokasi.trim(),
        'tanggalKejadian': Timestamp.fromDate(DateTime(
          tanggalKejadian.year,
          tanggalKejadian.month,
          tanggalKejadian.day,
        )),
        'description': description.trim(),
        'anonim': anonim,
        'status': ReportStatus.menunggu.name,
        'catatan': '',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ReportException(
          'Pengaduan ditolak oleh aturan Firestore. Pastikan firestore.rules terbaru sudah di-Publish.',
        );
      }
      throw ReportException('Gagal mengirim pengaduan (${e.code}). Coba lagi.');
    } on TimeoutException {
      throw const ReportException(
        'Koneksi lambat. Cek menu Laporan sebelum mengirim ulang agar tidak dobel.',
      );
    }
  }
}
