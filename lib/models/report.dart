import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  menunggu('Menunggu'),
  diproses('Diproses'),
  selesai('Selesai');

  final String label;
  const ReportStatus(this.label);

  /// Mengubah teks dari Firestore ("diproses") menjadi enum.
  static ReportStatus fromName(String? name) {
    return ReportStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ReportStatus.menunggu,
    );
  }
}

class Report {
  final String id;
  final String title;
  final String description;
  final ReportStatus status;
  final DateTime? createdAt;

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Report(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Tanpa judul',
      description: (data['description'] as String?) ?? '',
      status: ReportStatus.fromName(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
