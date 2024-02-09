import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/Notifiers/GroupNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/UserProfileSetup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/UserContextNotifier.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final userAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userContextProvider = StateNotifierProvider<UserContextNotifier, UserContext?>((ref) {
  return UserContextNotifier();
});



class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  String _verificationId = '';
  CountryCode? _selectedCountryCode;
  String _phoneNumber = ''; // To store actual phone number

  @override
  void dispose() {
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }


  void _clearPhoneNumber() {
    setState(() {
      _phoneController.clear();
      _phoneNumber = '';
      _selectedCountryCode = null;
    });
  }

  void _updatePhoneNumber() {
    // Update phone number from the text field
    _phoneNumber = _phoneController.text;
  }

  Future<void> _verifyPhoneNumber() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    // Sanitize input and concatenate with country code
    String fullPhoneNumber = (_selectedCountryCode?.dialCode ?? '+1') + _phoneNumber.replaceAll(RegExp(r'\D'), '');

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // This callback would get called when verification is done automatically
          await auth.signInWithCredential(credential);
          // Perform further actions if required like navigating to another screen
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle the error scenario
          print('Verification Failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // This callback would get called when the code is sent to the user
          setState(() {
            _verificationId = verificationId;
          });
          // You may navigate the user to a screen where they can enter the OTP
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // This callback gets called when the auto retrieval times out
          setState(() {
            _verificationId = verificationId;
          });
          // You may handle this timeout scenario according to your requirement
        },
      );
    } catch (e) {
      // Handle any other exceptions
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<void> _signInWithVerificationCode() async {
    try {
      String smsCode = _verificationCodeController.text;
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;

      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        final userDoc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final newUserContext = UserContext(
            uid: user.uid,
            username: userData['username'] ?? '',
            phone: userData['phone'] ?? '',
            groups: List<String>.from(userData['groups'] ?? []),
            box: List<dynamic>.from(userData['box'] ?? []),
            image_text: userData['image_text'] ?? '',
          );

          // Update user context
          ref.read(userContextProvider.notifier).setUserContext(newUserContext);

          // Fetch and update group data if the user belongs to any groups
          if (userData['groups'] != null && userData['groups'].isNotEmpty) {
            await fetchAndUpdateGroupData(userData['groups'][0], ref); // Assuming the first group is used for demonstration
          }

          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UserProfileSetupPage()));
        }
      }
    } catch (e) {
      print("Error during sign in: $e");
    }
  }

  Future<void> fetchAndUpdateGroupData(String groupId, WidgetRef ref) async {
    final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    if (groupDoc.exists) {
      String groupName = groupDoc.data()?['group_name'] ?? '';
      List<dynamic> groupMembers = groupDoc.data()?['members'] ?? [];

      // Assuming you have a method in GroupNotifier to update group data
      ref.read(groupNotifierProvider.notifier).setGroupData(
        groupName: groupName,
        groupCode: groupId,
        groupMembers: List<String>.from(groupMembers),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('SyncInk', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "What's your phone number?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => _updatePhoneNumber(),
              decoration: InputDecoration(
                prefixIcon: IconButton(
                  icon: _selectedCountryCode != null
                      ? Image.asset(_selectedCountryCode!.flagUri, package: 'fl_country_code_picker')
                      : const Icon(Icons.flag, color: Colors.white),
                  onPressed: () async {
                    final countryCode = await const FlCountryCodePicker().showPicker(
                      context: context,
                    );

                    if (countryCode != null) {
                      setState(() {
                        _selectedCountryCode = countryCode;
                      });
                    }
                  },
                ),
                suffixIcon: _phoneController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: _clearPhoneNumber,
                )
                    : null,
                hintText: 'Enter Phone Number',
                hintStyle: const TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'By continuing, you agree to our Privacy Policy and Terms of Service.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _verifyPhoneNumber,
              style: ElevatedButton.styleFrom(primary: Colors.grey[800]),
              child: const Text('Send Verification Text'),
            ),
            TextFormField(
              controller: _verificationCodeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Verification Code',
                labelStyle: const TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _signInWithVerificationCode,
              style: ElevatedButton.styleFrom(primary: Colors.grey[800]),
              child: const Text('Verify Code'),
            ),
          ],
        ),
      ),
    );
  }
}