import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_bottom_nav_bar.dart';
import 'account_screen.dart';
import 'password_screen.dart';
import 'login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _launchSocial(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Uygulama dışı açma başarısız: $url');
      }
    } catch (e) {
      debugPrint('URL açılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFBF8),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: 12,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 24 : 32,
                        20,
                        isSmallScreen ? 24 : 32,
                        16,
                      ),
                      child: Text(
                        'Profilim',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 26 : 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.person_outlined,
                      title: 'Hesap Bilgileri',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AccountScreen()),
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _buildProfileMenuItem(
                      icon: Icons.lock_outlined,
                      title: 'Şifre Değiştir',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PasswordScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 24 : 32,
                0,
                isSmallScreen ? 24 : 32,
                8,
              ),
              child: const Text(
                'Bizi Takip Edin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(
                      iconPath: 'assets/icon/WhatsApp.png',
                      onTap: () => _launchSocial('https://wa.me/905532218602'),
                    ),
                    const SizedBox(width: 24),
                    _buildSocialIcon(
                      iconPath: 'assets/icon/Instagram.png',
                      onTap: () => _launchSocial(
                          'https://www.instagram.com/coffeerence.co/'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: 8,
              ),
              child: const Center(
                child: Text(
                  'Uzunsoft.com tarafından geliştirilmiştir.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _logout(context),
                  child: Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.brown[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 55,
        height: 55,
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 50,
            height: 50,
          ),
        ),
      ),
    );
  }
}
