import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/GroupContent.dart';
import 'package:frontend/components/JoinOrCreateGroup.dart';

import '../Notifiers/GroupNotifier.dart';
import '../main.dart';

class GroupPage extends ConsumerWidget {
  const GroupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupNotifier = ref.watch(groupNotifierProvider.notifier);
    final userContext  = ref.watch(userContextProvider);

    // Async loader to fetch and set group state if not already set or needs update
    Future<void> checkAndUpdateGroupState() async {
      if (userContext.value!.groups.isNotEmpty) {
        String groupId = userContext.value!.groups.first; 
        // Check if group details need to be fetched or updated
        if (groupNotifier.groupCode != groupId) {
          // Fetch group details from Firestore and update GroupNotifier
          final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
          if (groupDoc.exists) {
            groupNotifier.setGroupData(
              groupName: groupDoc.data()?['name'] ?? '',
              groupCode: groupId,
              groupMembers: List<String>.from(groupDoc.data()?['members'] ?? []),
            );
          }
        }
      }
    }

    return FutureBuilder(
      future: checkAndUpdateGroupState(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 250, 250, 250), size: 28),
              onPressed: () => Navigator.pop(context),
              splashColor: Colors.transparent,
              splashRadius: 0.1,
            ),
          ),
          body: groupNotifier.isInGroup
              ? GroupContentWidget(
            groupCode: groupNotifier.groupCode ?? '',
            groupName: groupNotifier.groupName ?? '',
            groupMembers: groupNotifier.groupMembers ?? [],
            onLeaveGroup: () async {
              final userId = userContext.value?.uid ?? '';
              await ref.read(groupNotifierProvider.notifier).leaveGroup(groupNotifier.groupCode!, userId);
            },
          )
              : JoinOrCreateGroupWidget(
            onCreateGroup: (String groupName) async {
              final userId = userContext.value?.uid ?? '';
              final username = userContext.value?.username ?? '';
              await ref.read(groupNotifierProvider.notifier).createGroup(groupName, userId, username);
            },
            onJoinGroup: (String groupCode) async {
              final userId = userContext.value?.uid ?? '';
              ref.read(groupNotifierProvider.notifier).joinGroup(groupCode , userId);
            },
          ),
        );
      },
    );
  }

}
