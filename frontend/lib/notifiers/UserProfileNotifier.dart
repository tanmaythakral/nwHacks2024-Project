import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  UserProfileNotifier() : super(const AsyncValue.loading());

  Future<void> saveUserProfile(String username) async {
    state = const AsyncValue.loading();
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || username.isEmpty) {
        state = AsyncValue.error("User is not signed in or username is empty.", StackTrace.current);
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'phone': user.phoneNumber,
        'groups': [],
      });
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final userProfileNotifierProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  return UserProfileNotifier();
});
