import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constrants/colors.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';
import '../widgets/custom_input_field.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  /// Admin tidak perlu mengisi NIK dan tanggal lahir.
  final bool isAdmin;

  const EditProfilePage({super.key, required this.profile, this.isAdmin = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameC = TextEditingController(text: _s('nama'));
  late final _phoneC = TextEditingController(text: _s('telepon'));
  late final _addressC = TextEditingController(text: _s('alamat'));
  late final _nikC = TextEditingController(text: _s('nik'));
  final _dobC = TextEditingController();

  DateTime? _dob;
  bool _loading = false;

  String _s(String key) => (widget.profile[key] as String?) ?? '';

  @override
  void initState() {
    super.initState();
    final ts = widget.profile['tanggalLahir'];
    if (ts is Timestamp) {
      _dob = ts.toDate();
      _dobC.text = formatTanggalPanjang(_dob!);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _nikC.dispose();
    _dobC.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Tanggal lahir',
    );
    if (picked != null && mounted) {
      setState(() {
        _dob = picked;
        _dobC.text = formatTanggalPanjang(picked);
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await AuthService.instance.updateProfile(uid: uid, data: {
        'nama': _nameC.text.trim(),
        'telepon': _phoneC.text.trim(),
        'alamat': _addressC.text.trim(),
        if (!widget.isAdmin) ...{
          'nik': _nikC.text.trim(),
          'tanggalLahir': _dob == null ? null : Timestamp.fromDate(_dob!),
        },
      });
      navigator.pop();
      showAppSnackBar(messenger, 'Profil berhasil diperbarui.');
    } catch (_) {
      showAppSnackBar(messenger, 'Gagal menyimpan profil. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomInputField(
                  label: 'Nama lengkap',
                  hintText: 'Nama sesuai identitas',
                  controller: _nameC,
                  enabled: !_loading,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.notEmpty(v, 'Nama lengkap'),
                ),
                gap,
                CustomInputField(
                  label: 'Nomor ponsel',
                  hintText: '0812xxxxxxxx',
                  controller: _phoneC,
                  enabled: !_loading,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                gap,
                CustomInputField(
                  label: 'Alamat domisili',
                  hintText: 'Jalan, kelurahan, dan kecamatan',
                  controller: _addressC,
                  enabled: !_loading,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.notEmpty(v, 'Alamat domisili'),
                ),
                if (!widget.isAdmin) ...[
                  gap,
                  CustomInputField(
                    label: 'NIK (opsional)',
                    hintText: '16 digit sesuai KTP',
                    helperText: 'Hanya dipakai untuk verifikasi dan ditampilkan sebagian.',
                    controller: _nikC,
                    enabled: !_loading,
                    maxLength: 16,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return null;
                      return RegExp(r'^\d{16}$').hasMatch(t) ? null : 'NIK harus 16 digit angka.';
                    },
                  ),
                  gap,
                  CustomInputField(
                    label: 'Tanggal lahir (opsional)',
                    hintText: 'Pilih tanggal',
                    controller: _dobC,
                    readOnly: true,
                    enabled: !_loading,
                    onTap: _pickDob,
                    suffixIcon: const Icon(Icons.calendar_today_outlined,
                        size: 20, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Simpan perubahan',
                  icon: Icons.check_rounded,
                  isLoading: _loading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
