import 'package:flutter/material.dart';
import '../constrants/colors.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';
import '../widgets/custom_input_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  /// Diisi otomatis jika pengguna sudah mengetik email di halaman Masuk.
  final String? initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailC =
      TextEditingController(text: widget.initialEmail ?? '');

  bool _loading = false;
  String? _sentTo; // terisi setelah tautan berhasil dikirim

  @override
  void dispose() {
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final email = _emailC.text.trim();

    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (mounted) setState(() => _sentTo = email);
    } on AuthException catch (e) {
      showAppSnackBar(messenger, e.message, isError: true);
    } catch (_) {
      showAppSnackBar(messenger, 'Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sentTo != null;

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

                // Ilustrasi kunci
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                          Positioned(
                            right: -8,
                            bottom: -8,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primarySoft,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.key_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Pulihkan akses akun Anda',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Lupa kata sandi?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jangan khawatir. Masukkan email terdaftar untuk menerima tautan reset kata sandi.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                CustomInputField(
                  label: 'Alamat email',
                  hintText: 'Masukkan email terdaftar',
                  controller: _emailC,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.email,
                  suffixIcon: const Icon(
                    Icons.mail_outline,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                AppButton(
                  label: sent ? 'Kirim ulang tautan' : 'Kirim tautan reset',
                  icon: Icons.send_outlined,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                if (sent)
                  InfoBox(
                    icon: Icons.check_circle_outline_rounded,
                    background: AppColors.successSoft,
                    foreground: AppColors.success,
                    message:
                        'Jika $_sentTo terdaftar, tautan reset sudah dikirim. Periksa kotak masuk dan folder spam.',
                  )
                else
                  const InfoBox(
                    message:
                        'Tautan hanya berlaku sementara. Periksa juga folder spam jika email tidak muncul.',
                  ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Masih kesulitan? ',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => showAppSnackBar(
                        ScaffoldMessenger.of(context),
                        'Halaman bantuan belum tersedia.',
                      ),
                      child: const Text(
                        'Hubungi bantuan',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
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
