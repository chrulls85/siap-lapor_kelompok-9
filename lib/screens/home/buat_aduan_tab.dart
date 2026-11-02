import 'package:flutter/material.dart';
import '../../constrants/colors.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/custom_input_field.dart';

class BuatAduanTab extends StatefulWidget {
  /// Tombol panah kembali -> ke Beranda.
  final VoidCallback onBack;

  /// Dipanggil setelah pengaduan tersimpan -> pindah ke tab Laporan.
  final VoidCallback onSubmitted;

  /// Kategori yang sudah dipilih dari Beranda (boleh kosong).
  final ReportCategory? presetCategory;

  const BuatAduanTab({
    super.key,
    required this.onBack,
    required this.onSubmitted,
    this.presetCategory,
  });

  @override
  State<BuatAduanTab> createState() => _BuatAduanTabState();
}

class _BuatAduanTabState extends State<BuatAduanTab> {
  static const _maxDesc = 1000;

  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _categoryC = TextEditingController();
  final _dateC = TextEditingController();
  final _locationC = TextEditingController();
  final _descC = TextEditingController();

  ReportCategory? _category;
  DateTime? _date;
  bool _anonim = false;
  bool _agreed = false;
  bool _showAgreeError = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _applyCategory(widget.presetCategory);
  }

  @override
  void didUpdateWidget(covariant BuatAduanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = widget.presetCategory;
    if (c != null && c != oldWidget.presetCategory) _applyCategory(c);
  }

  @override
  void dispose() {
    _titleC.dispose();
    _categoryC.dispose();
    _dateC.dispose();
    _locationC.dispose();
    _descC.dispose();
    super.dispose();
  }

  void _applyCategory(ReportCategory? c) {
    _category = c;
    _categoryC.text = c?.label ?? '';
  }

  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<ReportCategory>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            for (final c in ReportCategory.values)
              ListTile(
                leading: Icon(c.icon, color: AppColors.primary),
                title: Text(c.label, style: const TextStyle(fontSize: 14.5)),
                trailing: c == _category
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(c),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _applyCategory(picked));
      _formKey.currentState?.validate();
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      helpText: 'Tanggal kejadian',
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _dateC.text = formatTanggalPanjang(picked);
      });
    }
  }

  Future<void> _useMyAddress() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await AuthService.instance.getProfile(uid);
    if (!mounted) return;
    final alamat = (profile?['alamat'] as String?)?.trim() ?? '';
    if (alamat.isEmpty) {
      showAppSnackBar(
        ScaffoldMessenger.of(context),
        'Alamat domisili belum tersimpan di profil Anda.',
        isError: true,
      );
      return;
    }
    setState(() => _locationC.text = alamat);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _showAgreeError = !_agreed);
    if (!valid || !_agreed) return;

    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await ReportService.instance.create(
        uid: uid,
        title: _titleC.text,
        category: _category!,
        tanggalKejadian: _date!,
        lokasi: _locationC.text,
        description: _descC.text,
        anonim: _anonim,
      );
      if (!mounted) return;
      _resetForm();
      showAppSnackBar(messenger, 'Pengaduan terkirim. Pantau statusnya di menu Laporan.');
      widget.onSubmitted();
    } on ReportException catch (e) {
      showAppSnackBar(messenger, e.message, isError: true);
    } catch (_) {
      showAppSnackBar(messenger, 'Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleC.clear();
    _locationC.clear();
    _descC.clear();
    setState(() {
      _applyCategory(null);
      _date = null;
      _dateC.clear();
      _anonim = false;
      _agreed = false;
      _showAgreeError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);

    return SafeArea(
      bottom: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat pengaduan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Ceritakan masalah, biar kami bertindak.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const InfoBox(
              message: 'Isi informasi dengan jelas dan benar. Kolom bertanda * wajib diisi.',
            ),
            const SizedBox(height: 20),

            const Text(
              'Informasi pengaduan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 14),

            CustomInputField(
              label: 'Judul pengaduan *',
              hintText: 'Contoh: Jalan berlubang di Jl. Melati',
              controller: _titleC,
              enabled: !_loading,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final e = Validators.notEmpty(v, 'Judul pengaduan');
                if (e != null) return e;
                if (v!.trim().length < 5) return 'Judul minimal 5 karakter.';
                return null;
              },
            ),
            gap,
            CustomInputField(
              label: 'Kategori *',
              hintText: 'Pilih kategori',
              controller: _categoryC,
              readOnly: true,
              enabled: !_loading,
              onTap: _pickCategory,
              validator: (_) => _category == null ? 'Pilih salah satu kategori.' : null,
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
            ),
            gap,
            CustomInputField(
              label: 'Tanggal kejadian *',
              hintText: 'Pilih tanggal',
              controller: _dateC,
              readOnly: true,
              enabled: !_loading,
              onTap: _pickDate,
              validator: (_) => _date == null ? 'Pilih tanggal kejadian.' : null,
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textMuted),
            ),
            gap,
            CustomInputField(
              label: 'Lokasi kejadian *',
              hintText: 'Jalan, kelurahan, dan kecamatan',
              controller: _locationC,
              enabled: !_loading,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.notEmpty(v, 'Lokasi kejadian'),
              suffixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _loading ? null : _useMyAddress,
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text(
                  'Gunakan alamat saya',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 4),
            CustomInputField(
              label: 'Isi pengaduan *',
              hintText: 'Ceritakan apa yang terjadi',
              helperText: 'Jelaskan kondisi dan dampaknya. Maksimal 1.000 karakter.',
              controller: _descC,
              enabled: !_loading,
              minLines: 5,
              maxLines: 8,
              maxLength: _maxDesc,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final e = Validators.notEmpty(v, 'Isi pengaduan');
                if (e != null) return e;
                if (v!.trim().length < 20) {
                  return 'Jelaskan lebih rinci, minimal 20 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Samarkan identitas
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Samarkan identitas saya',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Nama Anda tidak ditampilkan kepada publik.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _anonim,
                    onChanged: _loading ? null : (v) => setState(() => _anonim = v),
                    thumbColor: const WidgetStatePropertyAll(Colors.white),
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pernyataan
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _loading
                  ? null
                  : () => setState(() {
                        _agreed = !_agreed;
                        if (_agreed) _showAgreeError = false;
                      }),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreed,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(
                        color: _showAgreeError ? AppColors.danger : AppColors.textMuted,
                        width: 1.5,
                      ),
                      onChanged: _loading
                          ? null
                          : (v) => setState(() {
                                _agreed = v ?? false;
                                if (_agreed) _showAgreeError = false;
                              }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Saya menyatakan informasi yang disampaikan benar dan sesuai fakta.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            if (_showAgreeError)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 34),
                child: Text(
                  'Centang pernyataan untuk melanjutkan.',
                  style: TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 20),

            AppButton(
              label: 'Kirim pengaduan',
              icon: Icons.send_outlined,
              isLoading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Setelah dikirim, pantau status di menu Laporan.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
