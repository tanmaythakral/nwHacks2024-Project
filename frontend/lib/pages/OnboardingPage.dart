import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  String _verificationId = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.verifyPhoneNumber(
        phoneNumber:
            '+1${_phoneController.text}', // Include the country code if needed
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatically sign in when verification is completed
          await auth.signInWithCredential(credential);
          // Navigate to the next screen or perform desired actions
          // You can use Navigator to navigate to the next screen.
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle verification failure, e.g., invalid phone number format
          print('Verification Failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Save the verification ID to be used later
          setState(() {
            _verificationId = verificationId;
          });
          // Navigate to the verification code input screen
          // You can use Navigator to navigate to the next screen.
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle code auto-retrieval timeout
          print('Auto-Retrieval Timeout');
        },
      );
    } catch (e) {
      // Handle exceptions
      print('Error: $e');
    }
  }

  Future<void> _signInWithVerificationCode() async {
    try {
      // Get the verification code from the text field
      String smsCode = _verificationCodeController.text;

      // Create a PhoneAuthCredential with the code and verification ID
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: smsCode);

      // Sign in with the credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to the next screen or perform desired actions after successful sign-in
      // You can use Navigator to navigate to the next screen.
    } catch (e) {
      // Handle exceptions
      print('Error: $e');
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
              decoration: InputDecoration(
                prefixIcon: IconButton(
                  icon: const Icon(Icons.flag, color: Colors.white),
                  onPressed: () {
                    // Handle country code selection
                  },
                ),
                hintText: '+1',
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

            // Add a text field for entering verification code
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
