import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi Register
  Future<String?> registerUser({
    required String email,
    required String password,
    required String nama,
  }) async {
    try {
      // 1. Buat Akun di Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Ambil UID pengguna yang baru dibuat
      String uid = credential.user!.uid;

      // 3. Simpan data tambahan ke Firestore di collection 'users'
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nama': nama,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Karena Firebase otomatis melogin-kan user setelah register,
      // kita sign out agar user harus login ulang secara manual.
      await _auth.signOut();

      return "Sukses";
    } on FirebaseAuthException catch (e) {
      return e.message; // Kembalikan pesan error jika gagal
    } catch (e) {
      return e.toString();
    }
  }

  // Fungsi Login
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Sukses";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
