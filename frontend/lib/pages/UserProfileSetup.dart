import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/HomePage.dart';

import '../Notifiers/UserProfileNotifier.dart';

class UserProfileSetupPage extends ConsumerStatefulWidget {
  const UserProfileSetupPage({Key? key}) : super(key: key);

  @override
  ConsumerState<UserProfileSetupPage> createState() => _UserProfileSetupPageState();
}

class _UserProfileSetupPageState extends ConsumerState<UserProfileSetupPage> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the userProfileNotifierProvider to react to state changes
    ref.listen<AsyncValue<void>>(userProfileNotifierProvider, (_, state) {
      state.when(
        data: (_) {
          // On successful profile setup, navigate to the HomePage
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        },
        loading: () {
          // Loading state, could potentially show a loading indicator
        },
        error: (error, _) {
          // On error, show a Snackbar with the error message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Set Up Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter your username',
                hintStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_usernameController.text.isNotEmpty) {
                  // Trigger the profile save operation
                  ref.read(userProfileNotifierProvider.notifier).saveUserProfile(_usernameController.text.trim());
                } else {
                  // Show a message if the username field is empty
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a username.')));
                }
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
