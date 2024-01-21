import 'package:flutter/material.dart';
import 'package:frontend/components/BlurOverlay.dart';
import 'package:frontend/components/CollageImage.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: IconButton(
            icon:
                const Icon(Icons.people_rounded, color: Colors.white, size: 28),
            onPressed: () {},
            splashColor: Colors.transparent,
            splashRadius: 0.1,
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('App Title',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 18),
              child: InkWell(
                onTap: () {},
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: const CircleAvatar(
                  backgroundImage:
                      NetworkImage('https://via.placeholder.com/150'),
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
