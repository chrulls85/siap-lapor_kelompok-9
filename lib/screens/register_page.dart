import 'package:flutter/material.dart';
import '../constrants/colors.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';
import '../widgets/custom_input_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _showAgreeError = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _showAgreeError = !_agreed);
    if (!valid || !_agreed) return;

    // Ambil sebelum await agar aman dipakai setelahnya.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        nama: _nameC.text,
        email: _emailC.text,
        telepon: _phoneC.text,
        alamat: _addressC.text,
        password: _passC.text,
      );
      // Pengguna sudah otomatis masuk; AuthGate menampilkan Beranda di bawah
      // halaman ini. Tutup halaman Daftar agar Beranda terlihat.
      navigator.popUntil((route) => route.isFirst);
      showAppSnackBar(messenger, 'Akun berhasil dibuat. Selamat datang di Siap Lapor!');
    } on AuthException catch (e) {
      showAppSnackBar(messenger, e.message, isError: true);
    } catch (_) {
      showAppSnackBar(messenger, 'Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _eye(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textMuted,
      ),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    const iconColor = AppColors.textMuted;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(),
                const SizedBox(height: 16),
                BackLink(onTap: () => Navigator.of(context).pop()),
                const SizedBox(height: 12),

                const Text(
                  'Daftar akun baru',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lengkapi data diri Anda untuk mulai melapor dan memantau perubahan.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                CustomInputField(
                  label: 'Nama lengkap',
                  hintText: 'Nama sesuai identitas',
                  controller: _nameC,
                  enabled: !_loading,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => Validators.notEmpty(v, 'Nama lengkap'),
                  suffixIcon: const Icon(Icons.person_outline, color: iconColor),
                ),
                gap,
                CustomInputField(
                  label: 'Alamat email',
                  hintText: 'contoh@email.com',
                  controller: _emailC,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  suffixIcon: const Icon(Icons.mail_outline, color: iconColor),
                ),
                gap,
                CustomInputField(
                  label: 'Nomor ponsel',
                  hintText: '0812xxxxxxxx',
                  controller: _phoneC,
                  enabled: !_loading,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: Validators.phone,
                  suffixIcon: const Icon(Icons.phone_outlined, color: iconColor),
                ),
                gap,
                CustomInputField(
                  label: 'Alamat domisili',
                  hintText: 'Jalan, kelurahan, dan kecamatan',
                  controller: _addressC,
                  enabled: !_loading,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.notEmpty(v, 'Alamat domisili'),
                  suffixIcon:
                      const Icon(Icons.location_on_outlined, color: iconColor),
                ),
                gap,
                CustomInputField(
                  label: 'Kata sandi',
                  hintText: 'Buat kata sandi',
                  helperText: 'Minimal 8 karakter, gunakan huruf dan angka.',
                  controller: _passC,
                  enabled: !_loading,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  suffixIcon: _eye(
                    _obscurePass,
                    () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                gap,
                CustomInputField(
                  label: 'Konfirmasi kata sandi',
                  hintText: 'Ulangi kata sandi',
                  controller: _confirmC,
                  enabled: !_loading,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
                    if (v != _passC.text) return 'Kata sandi tidak sama.';
                    return null;
                  },
                  suffixIcon: _eye(
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 16),

                // Persetujuan
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: _showAgreeError
                                ? AppColors.danger
                                : AppColors.textMuted,
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
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppColors.textMuted,
                            ),
                            children: [
                              TextSpan(text: 'Saya menyetujui '),
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: ' serta '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: ' Siap Lapor.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showAgreeError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 34),
                    child: Text(
                      'Centang persetujuan untuk melanjutkan.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: 20),

                AppButton(
                  label: 'Daftar sekarang',
                  icon: Icons.arrow_forward,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: _loading ? null : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SecureFooter(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
