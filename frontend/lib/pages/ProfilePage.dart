import 'package:flutter/material.dart';
import 'package:frontend/pages/HomePage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String username = "lancetan02";
    String phoneNumber = "1234567890";

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 18),
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Color.fromARGB(255, 250, 250, 250), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        const HomePage(),
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
            child: Text('Settings',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 250, 250, 250))),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(context, username, phoneNumber),
                _buildSectionTitle("SETTINGS"),
                _buildSettingsOption(
                    Icons.notifications, "Notifications", () {},
                    isFirst: true),
                _buildSettingsOption(Icons.lock, "Privacy", () {}),
                _buildSettingsOption(
                    Icons.public, "Time Zone: Americas", () {}),
                _buildSettingsOption(Icons.more_horiz, "Other", () {},
                    isLast: true),
                _buildSectionTitle("ABOUT"),
                _buildSettingsOption(Icons.share, "Share App Title", () {},
                    isFirst: true),
                _buildSettingsOption(Icons.star, "Rate App Title", () {}),
                _buildSettingsOption(Icons.help_outline, "Help", () {}),
                _buildSettingsOption(Icons.info_outline, "About", () {},
                    isLast: true),
                const SizedBox(height: 20),
                _buildLogOutButton(),
              ],
            ),
          ),
        ));
  }

  Widget _buildProfileHeader(
      BuildContext context, String username, String phoneNumber) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 21, 21, 23), // Darker grey background
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green,
            child: Text(
              username.substring(0, 2).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 250, 250, 250),
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  phoneNumber,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 250, 250, 250),
                      fontWeight: FontWeight.normal,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.chevron_right,
              color: Color.fromARGB(255, 85, 84, 89),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, VoidCallback onTap,
      {bool isLast = false, bool isFirst = false}) {
    BorderRadius borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(10) : Radius.zero,
      bottom: isLast ? const Radius.circular(10) : Radius.zero,
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 21, 21, 23),
            borderRadius: borderRadius,
          ),
          child: ListTile(
            leading:
                Icon(icon, color: const Color.fromARGB(255, 250, 250, 250)),
            title: Text(title,
                style: const TextStyle(
                    color: Color.fromARGB(255, 250, 250, 250),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color.fromARGB(255, 85, 84, 89),
            ),
            onTap: onTap,
          ),
        ),
        // Add a Divider if it's not the last item and not the first item to avoid double border
        if (!isLast)
          Divider(
            color: const Color.fromARGB(255, 250, 250, 250).withOpacity(0.3),
            height: 1, // White line as a divider
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              color: Color.fromARGB(255, 85, 85, 87),
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildLogOutButton() {
    return ElevatedButton(
      onPressed: () {
        // Add your log out logic here
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            const Color.fromARGB(255, 21, 21, 23), // Background color
        minimumSize:
            const Size(double.infinity, 50), // Full width and fixed height
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        elevation: 0, // Removes the shadow
      ),
      child: const Text(
        'Log Out',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color.fromARGB(255, 254, 61, 48),
        ),
      ),
    );
  }
}
