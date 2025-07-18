import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profil_screen.dart';
import 'qr_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 350;
    final isLargeScreen = screenWidth > 600;

    final barHeight = screenHeight * 0.12;
    final iconSize = isSmallScreen ? 22.0 : isLargeScreen ? 30.0 : 26.0;
    final horizontalPadding = screenWidth * 0.05;
    final qrButtonSize = barHeight * 0.6;

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: Container(
            height: barHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: barHeight * 0.12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    icon: Icons.storefront,
                    index: 0,
                    context: context,
                    isSelected: currentIndex == 0,
                    destination: const HomeScreen(),
                    iconSize: iconSize,
                    padding: horizontalPadding,
                  ),
                  _buildQrButton(
                    context,
                    size: qrButtonSize,
                    iconSize: iconSize * 1.1,
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    index: 2,
                    context: context,
                    isSelected: currentIndex == 2,
                    destination: const ProfilScreen(),
                    iconSize: iconSize,
                    padding: horizontalPadding,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required BuildContext context,
    required bool isSelected,
    required Widget destination,
    required double iconSize,
    required double padding,
  }) {
    return SizedBox(
      height: iconSize * 1.7,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => destination,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: iconSize * 0.3,
          ),
          decoration: isSelected
              ? BoxDecoration(
            color: Colors.brown,
            borderRadius: BorderRadius.circular(iconSize * 0.4),
          )
              : null,
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.brown[200],
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildQrButton(
      BuildContext context, {
        required double size,
        required double iconSize,
      }) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const QrScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD1B1A1),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.qr_code_scanner,
            size: iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}