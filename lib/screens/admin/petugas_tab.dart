import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/custom_input_field.dart';
import '../../utils/validators.dart';

// ------------------------------------------------------------------ Model
enum PetugasStatus {
  tersedia('Tersedia'),
  menangani('Menangani'),
  tidakAktif('Tidak aktif');

  final String label;
  const PetugasStatus(this.label);

  static PetugasStatus fromName(String? name) => PetugasStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => PetugasStatus.tersedia,
      );
}

class Petugas {
  final String id;
  final String nama;
  final String instansi;
  final String wilayah;
  final String kode; // contoh: PTG-001
  final PetugasStatus status;
  final int aktif; // jumlah laporan yang sedang ditangani
  final int kapasitas;

  const Petugas({
    required this.id,
    required this.nama,
    required this.instansi,
    required this.wilayah,
    required this.kode,
    required this.status,
    required this.aktif,
    required this.kapasitas,
  });

  String get inisial {
    final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory Petugas.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Petugas(
      id: doc.id,
      nama: (d['nama'] as String?) ?? 'Tanpa nama',
      instansi: (d['instansi'] as String?) ?? '-',
      wilayah: (d['wilayah'] as String?) ?? '-',
      kode: (d['kode'] as String?) ?? doc.id,
      status: PetugasStatus.fromName(d['status'] as String?),
      aktif: (d['laporanAktif'] as num?)?.toInt() ?? 0,
      kapasitas: ((d['kapasitas'] as num?)?.toInt() ?? 5).clamp(1, 999),
    );
  }
}

// -------------------------------------------------------------------- Tab
class PetugasTab extends StatefulWidget {
  const PetugasTab({super.key});

  @override
  State<PetugasTab> createState() => _PetugasTabState();
}

class _PetugasTabState extends State<PetugasTab> {
  late final Stream<List<Petugas>> _stream = FirebaseFirestore.instance
      .collection('petugas')
      .orderBy('kode')
      .snapshots()
      .map((s) => s.docs.map(Petugas.fromDoc).toList());

  final _searchC = TextEditingController();
  String _query = '';
  PetugasStatus? _filter; // null = Semua

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<Petugas> _apply(List<Petugas> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_filter != null && p.status != _filter) return false;
      if (q.isEmpty) return true;
      return p.nama.toLowerCase().contains(q) ||
          p.instansi.toLowerCase().contains(q) ||
          p.kode.toLowerCase().contains(q);
    }).toList();
  }

  void _openAdd(int currentCount) {
    final kode = 'PTG-${(currentCount + 1).toString().padLeft(3, '0')}';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddPetugasSheet(kode: kode),
    );
  }

  void _openDetail(Petugas p) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PetugasDetailSheet(petugas: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Petugas>>(
        stream: _stream,
        builder: (context, snap) {
          final all = snap.data ?? const <Petugas>[];
          final shown = _apply(all);
          final tersedia = all.where((p) => p.status == PetugasStatus.tersedia).length;
          final laporanAktif = all.fold<int>(0, (sum, p) => sum + p.aktif);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const _TopBar(),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Petugas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  _AdminChip(),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Atur petugas dan pemerataan penanganan aduan.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),

              // Ringkasan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _Summary(value: all.length, label: 'Total petugas'),
                    _Summary(value: tersedia, label: 'Tersedia'),
                    _Summary(value: laporanAktif, label: 'Laporan aktif'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pencarian
              TextField(
                controller: _searchC,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau instansi petugas',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: () => setState(() {
                            _searchC.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Pill(
                      label: 'Semua',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final s in PetugasStatus.values) ...[
                      const SizedBox(width: 8),
                      _Pill(
                        label: s.label,
                        selected: _filter == s,
                        onTap: () => setState(() => _filter = s),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Petugas terdaftar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAdd(all.length),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (snap.hasError)
                const _Note(
                  icon: Icons.cloud_off_rounded,
                  text: 'Data petugas belum bisa dimuat. Pastikan akun ini admin dan firestore.rules terbaru sudah di-Publish.',
                )
              else if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (all.isEmpty)
                const _Note(
                  icon: Icons.groups_outlined,
                  text: 'Belum ada petugas. Tekan Tambah untuk mendaftarkan petugas pertama.',
                )
              else if (shown.isEmpty)
                const _Note(
                  icon: Icons.search_off_rounded,
                  text: 'Tidak ada petugas yang cocok. Coba kata kunci lain atau ubah filter.',
                )
              else ...[
                for (final p in shown) ...[
                  _PetugasCard(petugas: p, onTap: () => _openDetail(p)),
                  const SizedBox(height: 12),
                ],
                Center(
                  child: Text(
                    'Menampilkan ${shown.length} dari ${all.length} petugas',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- Potongan
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Align(alignment: Alignment.centerLeft, child: AuthHeader())),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showAppSnackBar(
              ScaffoldMessenger.of(context),
              'Belum ada notifikasi baru.',
            ),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Admin kota',
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int value;
  final String label;
  const _Summary({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFC7D5F2)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PetugasStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case PetugasStatus.tersedia:
        bg = AppColors.successSoft;
        fg = AppColors.success;
      case PetugasStatus.menangani:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
      case PetugasStatus.tidakAktif:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _PetugasCard extends StatelessWidget {
  final Petugas petugas;
  final VoidCallback onTap;
  const _PetugasCard({required this.petugas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = petugas;
    final Color barColor;
    switch (p.status) {
      case PetugasStatus.tersedia:
        barColor = AppColors.primary;
      case PetugasStatus.menangani:
        barColor = AppColors.warning;
      case PetugasStatus.tidakAktif:
        barColor = AppColors.textMuted;
    }
    final ratio = (p.aktif / p.kapasitas).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      p.inisial,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.instansi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.wilayah} · ${p.kode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  _StatusBadge(status: p.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Laporan aktif',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  Text(
                    '${p.aktif} dari ${p.kapasitas} kapasitas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: AppColors.primarySoft,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Tambah petugas
class _AddPetugasSheet extends StatefulWidget {
  final String kode;
  const _AddPetugasSheet({required this.kode});

  @override
  State<_AddPetugasSheet> createState() => _AddPetugasSheetState();
}

class _AddPetugasSheetState extends State<_AddPetugasSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _instansiC = TextEditingController();
  final _wilayahC = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _namaC.dispose();
    _instansiC.dispose();
    _wilayahC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('petugas').add({
        'nama': _namaC.text.trim(),
        'instansi': _instansiC.text.trim(),
        'wilayah': _wilayahC.text.trim(),
        'kode': widget.kode,
        'status': PetugasStatus.tersedia.name,
        'laporanAktif': 0,
        'kapasitas': 5,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
      navigator.pop();
      showAppSnackBar(messenger, 'Petugas ${_namaC.text.trim()} ditambahkan.');
    } on FirebaseException catch (e) {
      showAppSnackBar(
        messenger,
        e.code == 'permission-denied'
            ? 'Ditolak: akun ini bukan admin atau firestore.rules belum di-Publish.'
            : 'Gagal menyimpan (${e.code}). Coba lagi.',
        isError: true,
      );
    } catch (_) {
      showAppSnackBar(messenger, 'Koneksi lambat. Coba lagi sebentar.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tambah petugas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kode petugas otomatis: ${widget.kode}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              CustomInputField(
                label: 'Nama lengkap',
                hintText: 'Nama petugas',
                controller: _namaC,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.notEmpty(v, 'Nama petugas'),
              ),
              const SizedBox(height: 14),
              CustomInputField(
                label: 'Instansi',
                hintText: 'Contoh: Dinas Pekerjaan Umum',
                controller: _instansiC,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.notEmpty(v, 'Instansi'),
              ),
              const SizedBox(height: 14),
              CustomInputField(
                label: 'Wilayah tugas',
                hintText: 'Contoh: Bekasi Selatan',
                controller: _wilayahC,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                validator: (v) => Validators.notEmpty(v, 'Wilayah tugas'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Simpan petugas',
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

// ------------------------------------------------------------ Detail petugas
class _PetugasDetailSheet extends StatelessWidget {
  final Petugas petugas;
  const _PetugasDetailSheet({required this.petugas});

  Future<void> _setStatus(BuildContext context, PetugasStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    try {
      await FirebaseFirestore.instance
          .collection('petugas')
          .doc(petugas.id)
          .update({'status': status.name}).timeout(const Duration(seconds: 15));
      showAppSnackBar(messenger, '${petugas.nama} sekarang ${status.label.toLowerCase()}.');
    } on FirebaseException catch (e) {
      showAppSnackBar(messenger, 'Gagal mengubah status (${e.code}).', isError: true);
    } catch (_) {
      showAppSnackBar(messenger, 'Koneksi lambat. Coba lagi sebentar.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = petugas;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                _StatusBadge(status: p.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${p.instansi} · ${p.wilayah} · ${p.kode}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ubah ketersediaan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
              title: const Text('Tandai tersedia'),
              trailing: p.status == PetugasStatus.tersedia
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => _setStatus(context, PetugasStatus.tersedia),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pause_circle_outline_rounded, color: AppColors.textMuted),
              title: const Text('Tandai tidak aktif'),
              trailing: p.status == PetugasStatus.tidakAktif
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => _setStatus(context, PetugasStatus.tidakAktif),
            ),
          ],
        ),
      ),
    );
  }
}
