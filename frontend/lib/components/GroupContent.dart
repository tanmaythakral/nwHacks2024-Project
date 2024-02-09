import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore if needed for `fetchUsernameFromUID`

class GroupContentWidget extends StatefulWidget {
  final String? groupCode;
  final List<String> groupMembers; // Assuming UIDs are passed here
  final VoidCallback onLeaveGroup;
  final String groupName;

  GroupContentWidget({
    Key? key,
    required this.groupCode,
    required this.groupName,
    required this.groupMembers,
    required this.onLeaveGroup,
  }) : super(key: key);

  @override
  _GroupContentWidgetState createState() => _GroupContentWidgetState();
}

class _GroupContentWidgetState extends State<GroupContentWidget> {
  Future<List<String>> fetchUsernames() async {
    List<Future<String>> futures = [];
    for (String uid in widget.groupMembers) {
      futures.add(fetchUsernameFromUID(uid));
    }
    return Future.wait(futures);
  }

  Future<String> fetchUsernameFromUID(String uid) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      var userDocument = await firestore.collection('users').doc(uid).get();
      if (userDocument.exists) {
        return userDocument.data()?['username'] ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      print('Error fetching username: $e');
      return 'Error';
    }
  }

  final List<Color> avatarColors = [
    Colors.green, Colors.blue, Colors.red, Colors.orange, Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
      CrossAxisAlignment.center, // Ensure full-width elements
      children: [Text(widget.groupName,
            style: const TextStyle(
                color: Color.fromARGB(255, 250, 250, 250),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 15.0),
          child: RichText(
            text: TextSpan(
              children: <TextSpan>[
                const TextSpan(
                  text: 'Group code: ',
                  style: TextStyle(
                      color: Color.fromARGB(255, 250, 250, 250),
                      fontWeight: FontWeight.normal,
                      fontSize: 14),
                ),
                TextSpan(
                  text: widget.groupCode,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 250, 250, 250),
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        if (widget.groupCode != null)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 15, 42, 16),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundImage:
                      NetworkImage('https://via.placeholder.com/150'),
                    ),
                    const SizedBox(width: 7.5),
                    Expanded(
                        child: Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text('Invite friends to ${widget.groupName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(
                                              255, 250, 250, 250),
                                          fontSize: 14)),
                                  Text('app.title/${widget.groupCode}',
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal)),
                                ]))),
                    const Icon(
                      Icons.ios_share,
                      color: Color.fromARGB(255, 250, 250, 250),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Padding(
          padding:
          EdgeInsetsDirectional.only(start: 10, end: 10, top: 5, bottom: 5),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MEMBERS",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 250, 250, 250),
                        fontSize: 12)),
              ]),
        ),
        // Dynamically built list of members
        Expanded(
          child: FutureBuilder<List<String>>(
            future: fetchUsernames(),
            builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      String username = snapshot.data![index];
                      Color avatarColor = avatarColors[index % avatarColors.length];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: avatarColor,
                          child: Text(
                            username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  );
                } else {
                  return const Text('No data', style: TextStyle(color: Colors.white));
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: TextButton(
              onPressed: widget.onLeaveGroup,
              style: TextButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Leave Group', style: TextStyle(color: Colors.black)),
            )),
      ],
    );
  }
}
