import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../global/common/toast.dart';
import '../user/sharedpreferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _firebaseMessaging = FirebaseMessaging.instance;
  SharedPrefService sharedPrefService = SharedPrefService();

  Future<String> getUserRole(User user) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      Map<String, dynamic>? userData = userDoc.data();

      if (userData != null) {
        return userData['role'] as String? ?? 'USER';
      }
      return 'USER';
    } catch (e) {
      print("Error fetching user role: $e");
      return 'USER';
    }
  }

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = credential.user;

      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({'role': 'USER', 'email': email});
        return user;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    } catch (e) {
      showToast(message: 'An unexpected error occurred. Please try again.');
      print('General Exception: $e');
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print('Trying to sign in with email: $email and password: $password');
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("Credentials obtained: $credential");
      User? user = credential.user;
      if (user != null) {
        String role = await getUserRole(user);

        print("User role is: $role");
        print(user.uid);
        print(_firebaseMessaging.getToken());
        sharedPrefService.writeCache(key: "userId", value: user.uid);
        sharedPrefService.writeCache(key: "email", value: user.email!);
        sharedPrefService.writeCache(key: "role", value: role);

        String? token = await _firebaseMessaging.getToken();
        print("Firebase Messaging Token: $token");
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'token': token}, SetOptions(merge: true));
          print("Token updated in Firestore for user with UID: ${user.uid}");
        }
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code}, ${e.message}');
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    } catch (e) {
      print('General Exception: $e');
      showToast(message: 'An unexpected error occurred. Please try again.');
    }
    return null;
  }
}
