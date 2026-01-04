import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/app_router.dart';

@RoutePage()
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    if (hasSeenOnboarding && mounted) {
      context.router.replace(const MainTabRoute());
    }
  }
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showCloseButton = false;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Sign PDF Documents',
      description: 'Easily sign your PDF documents with digital signatures. Quick, simple, and secure.',
      imagePath: 'assets/o1.jpeg',
    ),
    _OnboardingPage(
      title: 'Create & Manage Signatures',
      description: 'Draw, save, and reuse your signatures. Organize them for easy access.',
      imagePath: 'assets/o2.jpeg',
    ),
    _OnboardingPage(
      title: 'Organize Your Documents',
      description: 'Keep your documents organized in folders. Find what you need instantly.',
      imagePath: 'assets/o3.jpeg',
    ),
    _OnboardingPage(
      title: 'Unlimited Access',
      description: 'Open unlimited access to all features. Sign as many documents as you need.',
      imagePath: 'assets/o4.jpeg',
      isPremium: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCloseButtonWithDelay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentPage == _pages.length - 1) {
        setState(() {
          _showCloseButton = true;
        });
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.router.replace(const MainTabRoute());
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _handleClose() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _showCloseButton = false;
                      });
                      if (index == _pages.length - 1) {
                        _showCloseButtonWithDelay();
                      }
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPageWidget(page: _pages[index]);
                    },
                  ),
                  if (_currentPage == _pages.length - 1 && _showCloseButton)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: SafeArea(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _handleClose,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: CupertinoColors.black.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: CupertinoColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _PageIndicator(isActive: index == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.systemRed,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _nextPage,
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
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
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Image.asset(
            page.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: CupertinoColors.systemGrey5,
                child: const Center(
                  child: Icon(
                    CupertinoIcons.photo,
                    size: 100,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  page.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? CupertinoColors.systemRed : CupertinoColors.systemGrey3,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final bool isPremium;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isPremium = false,
  });
}

