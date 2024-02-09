import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../components/ApiHandler.dart';

class GroupNotifier extends ChangeNotifier {
  bool isInGroup = false;
  String groupName = '';
  String? groupCode;
  List<String> groupMembers = [];

  final ApiHandler apiHandler;

  GroupNotifier(this.apiHandler) {
    checkGroupMembership();
  }

  Future<void> checkGroupMembership() async {

    if (isInGroup && groupCode != null) {
      groupMembers = await apiHandler.getGroupMembers(groupCode!);
      notifyListeners();
    }
  }

  void setGroupData({required String groupName, required String? groupCode, required List<String> groupMembers}) {
    isInGroup = true;
    this.groupName = groupName;
    this.groupCode = groupCode;
    this.groupMembers = groupMembers;
    notifyListeners();
  }

  void clearGroupData() {
    isInGroup = false;
    groupName = '';
    groupCode = null;
    groupMembers = [];
    notifyListeners();
  }


  Future<void> createGroup(String groupName, String userId, String username) async {
    String generatedGroupCode = await apiHandler.createGroup(groupName, userId, username);
    if (generatedGroupCode.isNotEmpty) {
      isInGroup = true;
      this.groupName  = groupName;
      groupCode = generatedGroupCode;
      groupMembers = await apiHandler.getGroupMembers(groupCode!);
      notifyListeners();
    }
  }


  Future<bool> joinGroup(String groupCode, String uid) async {
    // Implement joining a group using apiHandler
    bool joined = await apiHandler.joinGroup(groupCode, uid);
    if (!joined) {
      print("Failed to join group");
      return false;
    }
    isInGroup = true;
    groupMembers = await apiHandler.getGroupMembers(groupCode);
    this.groupCode = groupCode;
    notifyListeners();
    return true;
  }

  Future<void> leaveGroup(String groupCode, String username) async {
    await apiHandler.leaveGroup(groupCode, username);
    isInGroup = false;
    this.groupCode = null;
    groupMembers.clear();
    notifyListeners();
  }
}

final groupNotifierProvider = ChangeNotifierProvider<GroupNotifier>((ref) {
  // Assuming ApiHandler is available as a provider or can be instantiated here
  final apiHandler = ApiHandler();
  return GroupNotifier(apiHandler);
});
