import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/BlurOverlay.dart';
import 'package:frontend/components/CollageImage.dart';
import 'package:frontend/pages/GroupPage.dart';
import 'package:frontend/pages/ProfilePage.dart';
import '../main.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use ref.watch to listen to the userContextProvider
    final userContext = ref.watch(userContextProvider);

    // Define the username initialsD
    final usernameInitials = userContext.value!.username.isNotEmpty == true
        ? userContext.value!.username.substring(0, 2).toUpperCase()
        : '??'; // Default initials if username is null or empty

    // Build the HomePage content
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('IncSync', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupPage()),
              );
            },
            child: const Icon(Icons.group, color: Colors.white),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              highlightColor: Colors.transparent,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green,
                child: Text(
                  usernameInitials,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: [
                CollageImage(),
                BlurOverlay(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
