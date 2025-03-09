import 'package:flutter/material.dart';
// Import your styles and media files
// Adjust import paths according to your project structure
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onAddPressed;
  final VoidCallback? onBackPressed;
  final bool showAddButton;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onAddPressed,
    this.onBackPressed,
    this.showAddButton = true,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: AppStyles.white,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppStyles.darkPurple,
              AppStyles.lightPurple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: DecorationImage(
            image: AssetImage(AppMedia.pattern3),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppStyles.appBarGrey,
              BlendMode.dstATop,
            ),
          ),
        ),
      ),
      backgroundColor: AppStyles.trans,
      actions: showAddButton
          ? [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: AppStyles.white,
                ),
                onPressed: onAddPressed ??
                    () {
                      // New chat functionality to be implemented later
                    },
              )
            ]
          : [],
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppStyles.white),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
