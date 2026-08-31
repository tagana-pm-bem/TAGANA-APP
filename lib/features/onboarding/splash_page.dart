import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/user_repository.dart';
import '../../core/widgets/app_version_footer.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future<void>.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final isLoggedIn = UserRepository.currentUser != null;

    context.go(isLoggedIn ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/icons/logo.jpg',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) =>
                  const FlutterLogo(size: 120),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: AppVersionFooter(),
          ),
        ],
      ),
    );
  }
}