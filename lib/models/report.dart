import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter/material.dart' show Icons;

enum ReportStatus {
  menunggu('Menunggu', 'Laporan diterima, menunggu verifikasi'),
  diproses('Diproses', 'Sedang ditindaklanjuti petugas'),
  selesai('Selesai', 'Laporan telah diselesaikan');

  final String label;
  final String defaultNote;
  const ReportStatus(this.label, this.defaultNote);

  /// Mengubah teks dari Firestore ("diproses") menjadi enum.
  static ReportStatus fromName(String? name) {
    return ReportStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ReportStatus.menunggu,
    );
  }
}

/// Sumber tunggal kategori: Beranda dan form Buat Pengaduan membaca dari sini,
/// jadi nama dan ikonnya selalu sama.
enum ReportCategory {
  jalan('Jalan & fasilitas', 'Jalan & fasilitas umum', Icons.add_road_rounded),
  kebersihan('Kebersihan', 'Kebersihan lingkungan', Icons.cleaning_services_outlined),
  laluLintas('Lalu Lintas', 'Lalu Lintas', Icons.traffic_outlined);

  final String shortLabel; // dipakai di Beranda dan kartu laporan
  final String label; // dipakai di form
  final IconData icon;
  const ReportCategory(this.shortLabel, this.label, this.icon);

  static ReportCategory fromKey(String? key) {
    // 'pelayanan' = nama lama kategori Lalu Lintas (data uji sebelumnya).
    if (key == 'pelayanan') return ReportCategory.laluLintas;
    return ReportCategory.values.firstWhere(
      (c) => c.name == key,
      orElse: () => ReportCategory.jalan,
    );
  }
}

class Report {
  final String id;
  final String nomor; // contoh: SIP-A1B2C3
  final String title;
  final String description;
  final ReportCategory category;
  final String lokasi;
  final DateTime? tanggalKejadian;
  final bool anonim;
  final ReportStatus status;
  final String catatan; // keterangan status, diisi petugas/admin
  final DateTime? createdAt;

  const Report({
    required this.id,
    required this.nomor,
    required this.title,
    required this.description,
    required this.category,
    required this.lokasi,
    required this.tanggalKejadian,
    required this.anonim,
    required this.status,
    required this.catatan,
    required this.createdAt,
  });

  /// Keterangan status; jika petugas belum mengisi, pakai teks bawaan.
  String get statusNote => catatan.trim().isNotEmpty ? catatan : status.defaultNote;

  factory Report.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Report(
      id: doc.id,
      nomor: (d['nomor'] as String?) ?? 'SIP-${doc.id.substring(0, 6).toUpperCase()}',
      title: (d['title'] as String?) ?? 'Tanpa judul',
      description: (d['description'] as String?) ?? '',
      category: ReportCategory.fromKey(d['kategori'] as String?),
      lokasi: (d['lokasi'] as String?) ?? '-',
      tanggalKejadian: (d['tanggalKejadian'] as Timestamp?)?.toDate(),
      anonim: (d['anonim'] as bool?) ?? false,
      status: ReportStatus.fromName(d['status'] as String?),
      catatan: (d['catatan'] as String?) ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
