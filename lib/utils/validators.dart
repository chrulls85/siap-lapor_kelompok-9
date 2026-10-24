class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  // Nomor Indonesia: 08xx..., 628xx..., atau +628xx... (10-13 digit)
  static final RegExp _phone = RegExp(r'^(\+62|62|0)8[1-9][0-9]{7,10}$');

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  static String? notEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi.';
    }
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email wajib diisi.';
    if (!_email.hasMatch(v)) {
      return 'Format email tidak valid. Contoh: nama@email.com';
    }
    return null;
  }

  static String? phone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'Nomor ponsel wajib diisi.';
    if (!_phone.hasMatch(v)) {
      return 'Gunakan nomor Indonesia, contoh: 081234567890';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi.';
    if (v.length < 8) return 'Minimal 8 karakter.';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasDigit = RegExp(r'[0-9]').hasMatch(v);
    if (!hasLetter || !hasDigit) return 'Gunakan kombinasi huruf dan angka.';
    return null;
  }
}
