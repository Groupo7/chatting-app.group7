import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTER
  Future<void> register(String email, String password) async {
    UserCredential userCredential =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User user = userCredential.user!;

    UserModel newUser = UserModel(
      uid: user.uid,
      email: email,
    );

    await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
  }

  // LOGIN
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
