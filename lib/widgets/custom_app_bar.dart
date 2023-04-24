import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;

  const CustomAppBar({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      centerTitle: true,
      actions: [
        IconButton(
          //TODO: notifications button here
          onPressed: () {},
          icon: const Icon(
            Icons.notifications,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
