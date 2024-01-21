import 'package:flutter/material.dart';

class CollageImage extends StatelessWidget {
  const CollageImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final width = screenSize.width;
    final height = screenSize.height * 0.7;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
