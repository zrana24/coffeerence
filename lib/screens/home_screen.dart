import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'history_screen.dart';
import 'app_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int campaignPage = 0;
  int productPage = 0;
  List<dynamic> products = [];
  List<dynamic> banners = [];
  bool isLoading = true;
  bool isBannerLoading = true;
  String errorMessage = '';
  int coffeeCount = 0;
  bool isTokenValid = false;

  @override
  void initState() {
    super.initState();
    _checkTokenAndInitialize();
  }

  Future<void> _checkTokenAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    setState(() => isTokenValid = true);
    fetchProducts();
    fetchBanners();
    fetchCoffeeCount();
  }

  Future<void> fetchCoffeeCount() async {
    if (!isTokenValid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse(
            'https://mobilapp.coffeerence.com.tr/api/coffeerence/coffe_count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['freecoffe'] != null) {
          int rawCount = data['freecoffe'] is int
              ? data['freecoffe']
              : int.tryParse(data['freecoffe'].toString()) ?? 0;

          int displayCount = rawCount == 10 ? 0 : 10 - rawCount;

          setState(() {
            coffeeCount = displayCount;
          });
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      }
    } catch (e) {
      print('Kahve sayısı alınırken hata: $e');
    }
  }

  Future<void> fetchProducts() async {
    if (!isTokenValid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Oturum açılmamış. Lütfen tekrar giriş yapın.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://mobilapp.coffeerence.com.tr/api/coffeerence/all_products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData is List) {
          setState(() => products = responseData);
        }
        setState(() => isLoading = false);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = responseData['message'] ?? 'Ürünler alınamadı';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Sunucu bağlantı hatası: ${e.toString()}';
      });
    }
  }

  Future<void> fetchBanners() async {
    if (!isTokenValid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => isBannerLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://mobilapp.coffeerence.com.tr/api/coffeerence/all_banners'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            banners = data;
            isBannerLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      }
    } catch (e) {
      setState(() => isBannerLoading = false);
    }
  }

  void _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('isLoggedIn');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildEmptyView(String title, String subtitle, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _responsivePadding(MediaQuery.of(context).size.width),
        vertical: 10,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size:
                _responsiveFontSize(context, small: 20, medium: 30, large: 40),
            color: Colors.brown[300],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: _responsiveFontSize(context,
                    small: 16, medium: 18, large: 20),
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: _responsiveFontSize(context,
                    small: 12, medium: 14, large: 16),
                color: Colors.brown[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isTokenValid) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 375;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final navBarHeight = 60.0;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxHeight: double.infinity,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: isPortrait
                            ? _responsivePadding(screenSize.width) / 2
                            : 8,
                        right: _responsivePadding(screenSize.width),
                        left: _responsivePadding(screenSize.width),
                      ),
                      child: const Align(
                        alignment: Alignment.topRight,
                        child: _HistoryIconButton(),
                      ),
                    ),

                    // Promo card
                    Padding(
                      padding:
                          EdgeInsets.all(_responsivePadding(screenSize.width)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.brown[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.all(
                            _responsivePadding(screenSize.width)),
                        child: _PromoCardContent(coffeeCount: coffeeCount),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.only(
                        left: _responsivePadding(screenSize.width),
                        right: _responsivePadding(screenSize.width),
                        top: 8,
                      ),
                      child: const _SectionTitle('Kampanyalar'),
                    ),
                    SizedBox(
                      height: isPortrait
                          ? screenSize.height * (isSmallScreen ? 0.18 : 0.22)
                          : screenSize.height * 0.3,
                      child: isBannerLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.brown))
                          : banners.isEmpty
                              ? Center(
                                  child: _buildEmptyView(
                                    'Henüz kampanya bulunmamaktadır',
                                    'Yakın zamanda kampanyalarımız sizlerle olacak',
                                    Icons.campaign_outlined,
                                  ),
                                )
                              : PageView.builder(
                                  onPageChanged: (index) =>
                                      setState(() => campaignPage = index),
                                  controller: PageController(
                                    viewportFraction: isPortrait
                                        ? (isSmallScreen ? 0.85 : 0.9)
                                        : 0.7,
                                  ),
                                  itemCount: banners.length,
                                  itemBuilder: (_, index) => _CampaignCard(
                                    banners[index]['image_url']?.toString() ??
                                        'assets/image/kampanya.png',
                                  ),
                                ),
                    ),
                    if (banners.isNotEmpty)
                      _RectangleIndicators(
                          count: banners.length, currentPage: campaignPage),

                    const SizedBox(height: 16),

                    Padding(
                      padding: EdgeInsets.only(
                        left: _responsivePadding(screenSize.width),
                        right: _responsivePadding(screenSize.width),
                      ),
                      child: const _SectionTitle('Ürünler'),
                    ),
                    if (isLoading)
                      SizedBox(
                        height: isPortrait
                            ? screenSize.height * (isSmallScreen ? 0.25 : 0.28)
                            : screenSize.height * 0.35,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.brown),
                        ),
                      )
                    else if (errorMessage.isNotEmpty)
                      SizedBox(
                        height: isPortrait
                            ? screenSize.height * (isSmallScreen ? 0.25 : 0.28)
                            : screenSize.height * 0.35,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _responsivePadding(screenSize.width),
                            ),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else if (products.isEmpty)
                      SizedBox(
                        height: isPortrait
                            ? screenSize.height * (isSmallScreen ? 0.25 : 0.28)
                            : screenSize.height * 0.35,
                        child: _buildEmptyView(
                          'Henüz ürün bulunmamaktadır',
                          'Yakın zamanda lezzetli ürünlerimiz sizlerle olacak',
                          Icons.coffee_outlined,
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: isPortrait
                                ? screenSize.height *
                                    (isSmallScreen ? 0.32 : 0.36)
                                : screenSize.height * 0.45,
                            child: PageView.builder(
                              onPageChanged: (index) =>
                                  setState(() => productPage = index),
                              controller: PageController(
                                viewportFraction: isPortrait
                                    ? (isSmallScreen ? 0.75 : 0.8)
                                    : 0.6,
                              ),
                              itemCount: products.length,
                              itemBuilder: (_, index) => _ProductCard(
                                index: index,
                                title: products[index]['name']?.toString() ??
                                    'Ürün',
                                description: products[index]['description']
                                        ?.toString() ??
                                    'Açıklama metni',
                                imagePath:
                                    products[index]['image_url']?.toString() ??
                                        'assets/image/espresso.jpeg',
                              ),
                            ),
                          ),
                          _RectangleIndicators(
                              count: products.length, currentPage: productPage),
                        ],
                      ),

                    // Add bottom padding for navigation bar
                    SizedBox(height: bottomPadding + navBarHeight + 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  double _responsiveFontSize(BuildContext context,
      {required double small, required double medium, required double large}) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) return small;
    if (screenWidth < 450) return medium;
    return large;
  }

  double _responsivePadding(double screenWidth) {
    if (screenWidth < 350) return 12;
    if (screenWidth < 450) return 14;
    if (screenWidth < 600) return 16;
    return 18;
  }
}

class _HistoryIconButton extends StatelessWidget {
  const _HistoryIconButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.brown, width: 0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.receipt_long, color: Colors.brown, size: 28),
      ),
    );
  }
}

class _PromoCardContent extends StatelessWidget {
  final int coffeeCount;

  const _PromoCardContent({required this.coffeeCount});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 375;
    final isPortrait = screenSize.height > screenSize.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '10 Kahve Senden 1 Kahve Bizden!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isPortrait
                ? (isSmallScreen ? 16 : 18)
                : (isSmallScreen ? 14 : 16),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: isPortrait
                      ? (isSmallScreen ? 70 : 80)
                      : (isSmallScreen ? 60 : 70),
                  height: isPortrait
                      ? (isSmallScreen ? 70 : 80)
                      : (isSmallScreen ? 60 : 70),
                  child: CircularProgressIndicator(
                    value: coffeeCount / 10,
                    strokeWidth: 7,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.orange),
                    backgroundColor: Colors.white,
                  ),
                ),
                Image.asset(
                  'assets/image/beans.png',
                  width: isPortrait
                      ? (isSmallScreen ? 26 : 30)
                      : (isSmallScreen ? 22 : 26),
                  height: isPortrait
                      ? (isSmallScreen ? 26 : 30)
                      : (isSmallScreen ? 22 : 26),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.brown[700],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$coffeeCount/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isPortrait ? 18 : 14,
                vertical: isPortrait ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.brown[500],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'İkram\nİçecek',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  double _responsiveFontSize(BuildContext context,
      {required double small, required double medium, required double large}) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) return small;
    if (screenWidth < 450) return medium;
    return large;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize:
              _responsiveFontSize(context, small: 18, medium: 20, large: 22),
          color: Colors.brown[800],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final String imagePath;

  const _CampaignCard(this.imagePath);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imagePath.startsWith('http')
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/image/kampanya.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final String imagePath;

  const _ProductCard({
    required this.index,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final colors = [Colors.brown[700], Colors.brown[300], Colors.brown[700]];
    final backgroundColor = colors[index % colors.length]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: imagePath.startsWith('http')
                  ? Image.network(
                      imagePath,
                      height: isPortrait
                          ? screenSize.height * 0.18
                          : screenSize.height * 0.25,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildFallbackImage(isPortrait, screenSize),
                    )
                  : Image.asset(
                      imagePath,
                      height: isPortrait
                          ? screenSize.height * 0.18
                          : screenSize.height * 0.25,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(bool isPortrait, Size screenSize) {
    return Image.asset(
      'assets/image/coffee.jpeg',
      height: isPortrait ? screenSize.height * 0.18 : screenSize.height * 0.25,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _RectangleIndicators extends StatelessWidget {
  final int count;
  final int currentPage;

  const _RectangleIndicators({
    required this.count,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          width: isActive ? 24 : 16,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.deepOrange : Colors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
