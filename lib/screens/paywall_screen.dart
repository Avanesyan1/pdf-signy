import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_links.dart';
import '../router/app_router.dart';
import '../services/premium_service.dart';
import '../services/analytics_service.dart';

@RoutePage()
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  StoreProduct? _selectedProduct;
  bool _showCloseButton = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logPaywallScreen();
    _showCloseButtonWithDelay();
  }

  void _showCloseButtonWithDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showCloseButton = true;
        });
      }
    });
  }

  Future<void> _handlePurchase(StoreProduct product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await PremiumService.instance.buyProduct(product);
      if (success && mounted) {
        await PremiumService.instance.checkPremiumStatus();
        if (PremiumService.instance.havePremium.value && mounted) {
          AnalyticsService.instance.logPremiumPurchased(productId: product.identifier);
          if (context.router.canPop()) {
            context.router.maybePop();
          } else {
            context.router.replace(const MainTabRoute());
          }
        }
      } else {
        AnalyticsService.instance.logPremiumPurchaseFailed();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleClose() async {
    if (context.router.canPop()) {
      context.router.maybePop();
    } else {
      context.router.replace(const MainTabRoute());
    }
  }

  void _handleProductSelection(StoreProduct product) {
    setState(() {
      _selectedProduct = product;
    });
    _handlePurchase(product);
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not open the link: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StoreProduct>>(
      valueListenable: PremiumService.instance.products,
      builder: (context, products, child) {
        // Set default selected product to the second one (usually monthly) if available
        final defaultSelectedProduct = products.isNotEmpty
            ? (products.length > 1 ? products[1] : products.first)
            : null;
        final selectedProduct = _selectedProduct ?? defaultSelectedProduct;

        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.white,
          child: SafeArea(
            top: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/o4.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: CupertinoColors.systemRed);
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    CupertinoColors.white.withOpacity(0.0),
                                    CupertinoColors.white.withOpacity(0.0),
                                    CupertinoColors.white,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(flex: 5, child: Container()),
                  ],
                ),
                // Content overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Unlock Premium',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Get unlimited access to all premium features',
                          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Subscription options
                        if (products.isNotEmpty)
                          Column(
                            children: [
                              _buildSubscriptionCard(
                                context,
                                products.first,
                                () => _handleProductSelection(products.first),
                                selectedProduct?.identifier == products.first.identifier,
                              ),
                              const SizedBox(height: 16),
                              _buildSubscriptionCard(
                                context,
                                products.length > 1 ? products[1] : products.first,
                                () => _handleProductSelection(
                                  products.length > 1 ? products[1] : products.first,
                                ),
                                selectedProduct?.identifier ==
                                    (products.length > 1 ? products[1] : products.first).identifier,
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        // Subscribe button
                        if (products.isNotEmpty && selectedProduct != null)
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: CupertinoColors.systemRed,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _isLoading ? null : () => _handlePurchase(selectedProduct),
                              child: _isLoading
                                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _openUrl(AppLinks.termsOfUse),
                              child: Text(
                                'Terms of Use',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _openUrl(AppLinks.privacyPolicy),
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      PremiumService.instance.restorePurchase(context);
                                    },
                              child: Text(
                                'Restore',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Close button
                if (_showCloseButton)
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
                            color: CupertinoColors.black.withOpacity(0.0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.black.withOpacity(0.3),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    StoreProduct product,
    VoidCallback onPressed,
    bool isSelected,
  ) {
    final premiumService = PremiumService.instance;
    final hasTrial = premiumService.hasTrialPeriod(product);
    final trialInfo = premiumService.getTrialPeriodInfo(product);
    final weeklyPrice = premiumService.getWeeklyPrice(product);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? CupertinoColors.systemRed : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: CupertinoColors.systemRed, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weeklyPrice,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? CupertinoColors.white.withOpacity(0.7)
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
                Text(
                  product.priceString,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ],
            ),
            if (hasTrial && trialInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                trialInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? CupertinoColors.white.withOpacity(0.8)
                      : CupertinoColors.systemGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
