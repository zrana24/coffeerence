import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // Make sure to import LoginScreen

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String result = 'QR kodunu taratmak için kamerayı hedefe yöneltin';
  bool isLoading = false;
  bool isSuccess = false;
  bool? freeCoffee;
  String? freeCoffeeCount;
  bool _isProcessing = false;
  bool _isCheckingLogin = true;

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
        _isCheckingLogin = false;
      });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _sendToApi(String qrData) async {
    if (_isProcessing) return;
    _isProcessing = true;

    setState(() {
      isLoading = true;
      isSuccess = false;
      freeCoffee = null;
      freeCoffeeCount = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          result = 'Oturum bulunamadı. Lütfen tekrar giriş yapın.';
          isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.post(
        Uri.parse(
            'https://mobilapp.coffeerence.com.tr/api/coffeerence/add_coffee'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'qrcode': qrData}),
      );

      final responseData = json.decode(response.body);

      setState(() {
        isSuccess = responseData['success'] ?? false;
        freeCoffee = responseData['freecoffe'] ?? false;
        freeCoffeeCount = responseData['free_coffe_count']?.toString() ?? '';

        if (isSuccess) {
          result = responseData['message'] ?? 'QR kodu başarıyla işlendi';
        } else {
          result = responseData['message'] ?? 'QR kodu işlenirken hata oluştu';
        }
      });

      if (isSuccess && freeCoffee == true) {
        _showSuccessDialog(responseData['message']);
      }
    } catch (e) {
      setState(() {
        result = 'Sunucu hatası: Lütfen tekrar deneyin';
      });
    } finally {
      setState(() {
        isLoading = false;
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başarılı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (freeCoffee == true)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Ücretsiz kahve hakkınız: $freeCoffeeCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Okuyucu"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.white);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null &&
                      !isLoading &&
                      !_isProcessing) {
                    setState(() {
                      result = 'İşleniyor: ${barcode.rawValue}';
                    });
                    _sendToApi(barcode.rawValue!);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: isSuccess
                  ? Colors.green.withOpacity(0.1)
                  : (isLoading ? Colors.grey.withOpacity(0.1) : Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    Text(
                      result,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSuccess ? Colors.green : Colors.black,
                        fontWeight:
                            isSuccess ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  if (freeCoffeeCount != null && freeCoffeeCount!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ücretsiz kahve için son $freeCoffeeCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
