import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/HomePage.dart';
import 'pages/OnboardingPage.dart';
import 'components/ApiHandler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final userContextProvider = FutureProvider<UserContext?>((ref) async {
  final FirebaseAuth auth = ref.watch(firebaseAuthProvider);
  final User? user = auth.currentUser;
  if (user == null) return null; // User not logged in

  try {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!snapshot.exists) return null; // User document not found

    final userData = snapshot.data()!;
    return UserContext(
      uid: user.uid,
      username: userData['username'] ?? '',
      phone: userData['phone'] ?? '',
      groups: List<String>.from(userData['groups'] ?? []),
      box: List<dynamic>.from(userData['box'] ?? []),
      image_text: userData['image_text'] ?? '',
    );
  } catch (e) {
    print("Error fetching user data: $e");
    return null; // Error fetching user data
  }
});

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userContextAsyncValue = ref.watch(userContextProvider);

    return MaterialApp(
      title: 'IncSync',
      theme: ThemeData(fontFamily: 'SFPro'),
      home: userContextAsyncValue.when(
        data: (userContext) => userContext != null ? const HomePage() : const OnboardingPage(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(body: Center(child: Text('Error loading user data'))),
      ),
    );
  }
}

class UserContext {
  final String uid;
  final String username;
  final String phone;
  final List<String> groups;
  final List<dynamic> box;
  final String image_text;

  UserContext({
    required this.uid,
    required this.username,
    required this.phone,
    required this.groups,
    required this.box,
    required this.image_text,
  });
}
