import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupContentWidget extends StatelessWidget {
  final String? groupCode;
  final List<Map<String, dynamic>> groupMembers;
  final VoidCallback onLeaveGroup;

  final List<Color> avatarColors = [
    Colors.green, // Color for the first member
    Colors.blue, // Additional colors for other members
    Colors.red,
    Colors.orange,
    Colors.purple,
    // Add as many colors as you like
  ];

  GroupContentWidget({
    Key? key,
    required this.groupCode,
    required this.groupMembers,
    required this.onLeaveGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    groupMembers.clear();
    groupMembers.add({'username': 'lancetan02'});
    groupMembers.add({'username': 'kwong'});

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          CrossAxisAlignment.center, // Ensure full-width elements
      children: [
        const Text("Group Name",
            style: TextStyle(
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
                  text: groupCode,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 250, 250, 250),
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        if (groupCode != null)
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
                                  const Text('Invite friends to Group Name',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(
                                              255, 250, 250, 250),
                                          fontSize: 14)),
                                  Text('app.title/$groupCode',
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
        Expanded(
          child: ListView.builder(
            itemCount: groupMembers.length,
            itemBuilder: (context, index) {
              Color avatarColor = index == 0
                  ? avatarColors[0]
                  : avatarColors[(index % avatarColors.length) + 1];

              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColor,
                  child: Text(
                    groupMembers[index]['username']
                        .substring(0, 2)
                        .toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  groupMembers[index]['username'],
                  style: const TextStyle(
                      color: Color.fromARGB(255, 250, 250, 250)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: TextButton(
              onPressed: onLeaveGroup,
              style: TextButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                backgroundColor: const Color.fromARGB(
                    255, 250, 250, 250), // Button color for leaving group
              ),
              child: const Text('Leave Group',
                  style: TextStyle(color: Colors.black)),
            )),
      ],
    );
  }
}
