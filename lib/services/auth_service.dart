import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Error yang pesannya sudah siap ditampilkan ke pengguna.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Semua urusan Firebase Auth + profil pengguna di Firestore ada di sini,
/// supaya halaman (UI) tidak perlu tahu detail Firebase.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Berubah setiap kali pengguna masuk / keluar.
  Stream<User?> get authChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ------------------------------------------------------------------ Masuk
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  // ----------------------------------------------------------------- Daftar
  Future<void> register({
    required String nama,
    required String email,
    required String telepon,
    required String alamat,
    required String password,
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }

    // Akun sudah jadi. Simpan data tambahan ke Firestore: users/{uid}.
    // Jika langkah ini gagal, akun tetap valid; Beranda memakai nama dari Auth.
    final user = cred.user;
    if (user == null) return;
    try {
      await user.updateDisplayName(nama.trim());
      await _db.collection('users').doc(user.uid).set({
        'nama': nama.trim(),
        'email': email.trim(),
        'telepon': telepon.trim(),
        'alamat': alamat.trim(),
        'role': 'warga', // peran lain (petugas/admin) diatur manual oleh admin
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal menyimpan profil pengguna: $e');
    }
  }

  // ------------------------------------------------------------- Lupa sandi
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Sengaja diabaikan: jangan beri tahu apakah suatu email terdaftar atau
      // tidak (mencegah orang lain menebak email milik pengguna).
      if (e.code == 'user-not-found') return;
      throw AuthException(_message(e));
    }
  }

  // ----------------------------------------------------------------- Keluar
  Future<void> signOut() => _auth.signOut();

  // ----------------------------------------------------------------- Profil
  /// Data profil pengguna (users/{uid}), diperbarui otomatis saat berubah.
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((s) => s.data());
  }

  // ------------------------------------------------------- Terjemah error
  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid. Periksa kembali penulisannya.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan. Hubungi admin untuk bantuan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan masuk atau pakai email lain.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter dengan huruf dan angka.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case 'operation-not-allowed':
        return 'Login email belum diaktifkan. Aktifkan Email/Password di Firebase Console > Authentication.';
      default:
        return 'Terjadi kesalahan (${e.code}). Coba lagi.';
    }
  }
}
