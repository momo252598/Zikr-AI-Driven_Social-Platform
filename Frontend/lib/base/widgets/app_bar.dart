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
  final List<Widget>? actions; // Add this parameter for custom actions

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onAddPressed,
    this.onBackPressed,
    this.showAddButton = true,
    this.showBackButton = true,
    this.actions, // Add this parameter to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a list for actions
    List<Widget> appBarActions = [];

    // Add custom actions if provided
    if (actions != null) {
      appBarActions.addAll(actions!);
    }

    // Add the default add button if required
    if (showAddButton) {
      appBarActions.add(
        IconButton(
          icon: Icon(
            Icons.add,
            color: AppStyles.white,
          ),
          onPressed: onAddPressed ??
              () {
                // New chat functionality to be implemented later
              },
        ),
      );
    }
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
      actions: appBarActions,
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
