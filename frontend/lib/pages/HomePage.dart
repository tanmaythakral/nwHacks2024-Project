import 'package:flutter/material.dart';
import 'package:frontend/components/BlurOverlay.dart';
import 'package:frontend/components/CollageImage.dart';
import 'package:frontend/pages/GroupPage.dart';
import 'package:frontend/pages/ProfilePage.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String username = "lancetan02";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: IconButton(
            icon: const Icon(Icons.people_rounded,
                color: Color.fromARGB(255, 250, 250, 250), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const GroupPage(),
                  transitionDuration: Duration.zero,
                ),
              );
            },
            splashColor: Colors.transparent,
            splashRadius: 0.1,
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('SyncInk',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 250, 250, 250))),
        ),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 18),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const ProfilePage(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green,
                  child: Text(
                    username.substring(0, 2).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
        centerTitle: true,
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
