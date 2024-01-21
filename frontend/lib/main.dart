import 'package:flutter/material.dart';
import 'package:frontend/pages/HomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'SFPro',
      ),
<<<<<<< HEAD
      home: const HomePage(),
    );
=======
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return const MaterialApp(
                home: OnboardingPage(),
              );
            } else {
              // Fetch user data and pass it to HomePage
              return FutureBuilder<UserInformation>(
                future: apiHandler.fetchUserData(user.uid),
                builder: (context, userDataSnapshot) {
                  if (userDataSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const MaterialApp(
                      home: Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  } else if (userDataSnapshot.hasError) {
                    // Handle error if the API call fails
                    return const MaterialApp(
                      home: Scaffold(
                        body: Center(child: Text('Error fetching user data')),
                      ),
                    );
                  } else {
                    // Store user data in a context provider
                    return FutureBuilder<Map<String, dynamic>>(
                      future: apiHandler.fetchUnleashData(),
                      builder: (context, unleashDataSnapshot) {
                        if (unleashDataSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const MaterialApp(
                            home: Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        } else if (unleashDataSnapshot.hasError) {
                          return const MaterialApp(
                            home: Scaffold(
                              body: Center(
                                  child: Text('Error fetching unleash data')),
                            ),
                          );
                        } else {
                          return MyDataProvider(
                              userData: UserContext(
                                  uid: user.uid,
                                  username: userDataSnapshot.data!.username,
                                  phone: userDataSnapshot.data!.phone,
                                  groups: userDataSnapshot.data!.groups,
                                  box: unleashDataSnapshot.data!['payload']
                                                  [userDataSnapshot.data!.groups[0]]
                                              ['images']
                                          [userDataSnapshot.data!.username]
                                      ['coordinates'],
                                  image_text: unleashDataSnapshot
                                                      .data!['payload']
                                                  [userDataSnapshot.data!.groups[0]]
                                              ['images']
                                          [userDataSnapshot.data!.username]
                                      ['image_text']),
                              child: MaterialApp(
                                home: HomePage(),
                              ));
                        }
                      },
                    );
                  }
                },
              );
            }
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    ),
  );
}

class MyDataProvider extends InheritedWidget {
  final UserContext userData;

  const MyDataProvider({
    required this.userData,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  static MyDataProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyDataProvider>()!;
  }

  @override
  bool updateShouldNotify(MyDataProvider oldWidget) {
    return userData != oldWidget.userData;
>>>>>>> b46880a (Most)
  }
}
