import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

class UserContextNotifier extends StateNotifier<UserContext?> {
  UserContextNotifier() : super(null);

  void setUserContext(UserContext newUserContext) {
    state = newUserContext;
  }

  void clearUserContext() {
    state = null;
  }
}
