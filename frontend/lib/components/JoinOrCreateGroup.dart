import 'package:flutter/material.dart';

class JoinOrCreateGroupWidget extends StatefulWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;

  const JoinOrCreateGroupWidget({
    Key? key,
    required this.onCreateGroup,
    required this.onJoinGroup,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _JoinOrCreateGroupWidgetState createState() =>
      _JoinOrCreateGroupWidgetState();
}

class _JoinOrCreateGroupWidgetState extends State<JoinOrCreateGroupWidget> {
  bool isJoinMode = true; // Start in 'join group' mode
  final TextEditingController textEditingController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the context is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  @override
  void dispose() {
    focusNode.dispose(); // Don't forget to dispose of the focus node
    textEditingController.dispose();
    super.dispose();
  }

  void toggleMode() {
    setState(() {
      isJoinMode = !isJoinMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              isJoinMode ? 'Join a group' : 'Create a group',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color.fromARGB(255, 250, 250, 250),
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
            const SizedBox(height: 20),
            SizedBox(
              child: TextField(
                autofocus: true,
                controller: textEditingController,
                style: TextStyle(color: Colors.grey[300]),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 30, 30, 30),
                  hintText: isJoinMode ? 'Group code' : 'Group name',
                  hintStyle: TextStyle(
                      color: Colors
                          .grey[300]), // Light shade of grey for hint text
                  prefixIcon: Icon(isJoinMode ? Icons.group_add : Icons.create,
                      color: Colors.grey[300]), // Icon color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        15), // Set the desired border radius
                    borderSide: BorderSide.none, // Remove the border
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: isJoinMode ? widget.onJoinGroup : widget.onCreateGroup,
              style: ButtonStyle(
                alignment: Alignment.center,
                backgroundColor: MaterialStateProperty.all<Color>(
                  const Color.fromARGB(255, 250, 250, 250),
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
              child: Text(isJoinMode ? 'Join' : 'Create',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            TextButton(
                onPressed: toggleMode,
                style: const ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Text(
                    isJoinMode
                        ? 'Press here to create a group'
                        : 'Press here to join a group',
                    style: const TextStyle(
                        color: Color.fromARGB(255, 250, 250, 250),
                        fontWeight: FontWeight.normal,
                        fontSize: 14))),
          ],
        ));
  }
}
