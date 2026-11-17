import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi Register
  Future<String?> registerUser({
    required String email,
    required String password,
    required String nama,
    String phone = '',
  }) async {
    try {
      // 1. Buat Akun di Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user == null) {
        return "Gagal membuat akun pengguna.";
      }

      // 2. Simpan display name di Firebase Auth
      try {
        await user.updateDisplayName(nama);
      } catch (_) {}

      // 3. Simpan profil secara lokal di SharedPreferences agar langsung sinkron
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nama);
      await prefs.setString('userEmail', email);
      if (phone.isNotEmpty) {
        await prefs.setString('userPhone', phone);
      }

      // 4. Simpan data tambahan ke Firestore di collection 'users'
      // Dibungkus try-catch & timeout agar jika Firestore belum di-enable atau
      // terhalang rules di Firebase Console, registrasi Auth tetap berhasil dan tidak macet.
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'nama': nama,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Abaikan error Firestore agar tidak menggagalkan akun Auth yang sudah terbuat
      }

      // 5. Sign out agar user login secara manual setelah registrasi
      await _auth.signOut();

      return "Sukses";
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (e) {
      return "Terjadi kesalahan: ${e.toString()}";
    }
  }

  // Fungsi Login
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        String nama = user.displayName ?? prefs.getString('userName') ?? email.split('@').first;
        String phone = prefs.getString('userPhone') ?? '+62 812-3456-7890';

        // Coba ambil data profil dari Firestore dengan timeout singkat
        try {
          final doc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 3));
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data['nama'] != null && data['nama'].toString().isNotEmpty) {
              nama = data['nama'].toString();
            }
            if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
              phone = data['phone'].toString();
            }
          }
        } catch (_) {}

        await prefs.setString('userName', nama);
        await prefs.setString('userEmail', user.email ?? email);
        await prefs.setString('userPhone', phone);
      }

      return "Sukses";
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (e) {
      return "Terjadi kesalahan: ${e.toString()}";
    }
  }

  // Fungsi Reset Password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Sukses";
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (e) {
      return "Terjadi kesalahan: ${e.toString()}";
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'email-already-in-use':
        return 'Alamat email ini sudah terdaftar. Silakan masuk.';
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi yang Anda masukkan salah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'Layanan autentikasi Email/Password belum diaktifkan di Firebase Console.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan coba lagi nanti.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi (${e.code}).';
    }
  }
}
