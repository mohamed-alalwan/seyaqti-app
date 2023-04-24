import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seyaqti_app/auth/change_password_page.dart';
import 'package:seyaqti_app/shared_import.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final auth = FirebaseAuth.instance.currentUser!;
  AppUser user = AppUser();

  @override
  void initState() {
    super.initState();
    if (!auth.isAnonymous) {
      user = AppUser.currentUser!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Material(
            elevation: 3,
            child: UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              accountName: Text(user.fullName() ?? 'Guest User'),
              accountEmail: auth.email != null ? Text(auth.email!) : null,
              currentAccountPicture: CircleAvatar(
                child: ClipOval(
                  child: user.imageURL != null
                      ? Image.network(
                          user.imageURL!,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/guest.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text(
              'Policies (Coming Soon)',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text(
              'Settings (Coming Soon)',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text(
              'Change Address (Coming Soon)',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            onTap: () {
              if (FirebaseAuth.instance.currentUser!.isAnonymous) {
                Utils.ShowErrorBar(
                    'You need to register to use this functionality.');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
