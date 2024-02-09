import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:frontend/pages/DrawingPage.dart';

class BlurOverlay extends StatelessWidget {
  const BlurOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final width = screenSize.width;
    final height = screenSize.height * 0.7;

    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_off, color: Colors.black, size: 50),
                const Text("Draw to reveal",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Text(
                        "To view your group's collage, complete your drawing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                            fontSize: 14))),
                TextButton(
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DrawingPage()),
                      );
                    },
                    child: const Text(
                      "Start drawing.",
                      style: TextStyle(
                          color: Color.fromARGB(255, 250, 250, 250),
                          fontWeight: FontWeight.normal,
                          fontSize: 14),
                    ))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
