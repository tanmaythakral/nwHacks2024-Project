import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


const String url = 'http://127.0.0.1:5000/api';
class ApiHandler {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<UserInformation> fetchUserData(String userId) async {
    try {
      final DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return UserInformation.fromJson(data);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<bool> joinGroup(String groupCode, String username) async {
    final Uri apiUrl = Uri.parse('$url/groups/join');
    try {
      final response = await http.post(
        apiUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'group_code': groupCode,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        print('Joined group successfully');
        return true;
      } else {
        // Handle the case when the server response is not 200
        print('Failed to join group: ${response.body}');
        return false;
      }
    } catch (e) {
      // Handle any errors that occur during the request
      print('Error occurred while joining the group: $e');
      return false;
    }
  }


  Future<Map<String, dynamic>> fetchUnleashData() async {
    final Uri apiUrl = Uri.parse('$url/unleash');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load unleash data');
    }
  }
  Future<String> createGroup(String groupName, String username, String userid) async {
    final Uri apiUrl = Uri.parse('$url/groups/create');

    try {
      final response = await http.post(
        apiUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'group_name': groupName,
          'username': username,
          'userid': userid,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Handle the response data as needed
        print('Group created successfully: ${responseData['group_code']}');
        return responseData['group_code'];
      } else {
        // Handle the case when the server response is not 200
        print('Failed to create group: ${response.body}');
        return "";
      }
    } catch (e) {
      // Handle any errors that occur during the request
      print('Error occurred while creating group: $e');
      return "";
    }
  }

  Future<List<String>> getGroupMembers(String groupCode) async {
    final Uri apiUrl = Uri.parse('$url/groups/members/$groupCode');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<String> members = List<String>.from(data['members']);
      print('Group members: $members');
      return members;
    } else {
      throw Exception('Failed to load group members');
    }
  }



  Future<bool> leaveGroup(String groupCode, String username) async {
    final Uri apiUrl = Uri.parse('$url/groups/leave');

    try {
      final response = await http.post(
        apiUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'group_code': groupCode,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        print('Successfully left the group');
        return true;
      } else {
        print('Failed to leave group: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error occurred while leaving the group: $e');
      return false;
    }
  }
}



class UserInformation {
  final String username;
  final String phone;
  final List<String> groups;

  UserInformation({
    required this.username,
    required this.phone,
    required this.groups,
  });

  factory UserInformation.fromJson(Map<String, dynamic> json) {
    return UserInformation(
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      groups: (json['groups'] as List<dynamic>).cast<String>(),
    );
  }
}
