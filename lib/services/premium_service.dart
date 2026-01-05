import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:pdf_signy/config/app_links.dart';
import 'package:pdf_signy/services/app_logger.dart';
import 'package:pdf_signy/services/analytics_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  List<String> productIds = ['com.pdfSigny532.week', 'com.pdfSigny532.month'];

  final ValueNotifier<bool> havePremium = ValueNotifier(false);
  final ValueNotifier<List<StoreProduct>> products = ValueNotifier([]);

  Future<void> init() async {
    try {
      await Purchases.configure(PurchasesConfiguration(AppLinks.purchasesKey));

      await loadProducts();

      await checkPremiumStatus();

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        checkPremiumStatus();
      });
    } catch (e) {
      AppLogger().error('Error initializing Purchases: $e');
    }
  }

  Future<void> loadProducts({int attempt = 1}) async {
    products.value = await Purchases.getProducts(productIds);

    if (products.value.isEmpty && attempt < 2) {
      await loadProducts(attempt: attempt + 1);
    }

    AppLogger().info('Products: $products');
  }

  Future<void> checkPremiumStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      log('Active entitlements: $customerInfo');

      bool hasActivePremium = false;

      // Iterate over known productIds to check if any of them are in active subscriptions or entitlements
      final activeEntitlements = customerInfo.entitlements.active;
      final activeSubscriptions = customerInfo.activeSubscriptions;

      // Check for entitlement by known entitlement key ('Premium'), then fallback to matching product identifier
      if (activeEntitlements.containsKey('Premium')) {
        hasActivePremium = true;
      } else {
        // Check if any active subscription matches our known productIds
        for (final id in productIds) {
          if (activeEntitlements.containsKey(id) || activeSubscriptions.contains(id)) {
            hasActivePremium = true;
            break;
          }
        }
      }

      havePremium.value = hasActivePremium;
      AppLogger().info('Premium status: $hasActivePremium');
    } catch (e) {
      AppLogger().error('Error checking premium status: $e');
    }
  }

  Future<bool> buyTrialProduct() async {
    try {
      await Purchases.purchase(
        PurchaseParams.storeProduct(
          products.value.where((i) => i.identifier == productIds.first).first,
        ),
      );

      await checkPremiumStatus();

      return havePremium.value;
    } catch (e) {
      AppLogger().error('Error buying trial product: $e');
      return false;
    }
  }

  Future<bool> buyProduct(StoreProduct product) async {
    try {
      await Purchases.purchase(PurchaseParams.storeProduct(product));
      await checkPremiumStatus();
      return havePremium.value;
    } catch (e) {
      AppLogger().error('Error buying product: $e');
      return false;
    }
  }

  String getSubscriptionPeriod(StoreProduct product) {
    final periodISO = product.subscriptionPeriod;
    if (periodISO == null || periodISO.isEmpty) return '';

    if (periodISO.contains('Y')) {
      final years = _extractNumber(periodISO);
      return years == 1 ? 'year' : '$years years';
    } else if (periodISO.contains('M')) {
      final months = _extractNumber(periodISO);
      return months == 1 ? 'month' : '$months months';
    } else if (periodISO.contains('W')) {
      final weeks = _extractNumber(periodISO);
      return weeks == 1 ? 'week' : '$weeks weeks';
    } else if (periodISO.contains('D')) {
      final days = _extractNumber(periodISO);
      return days == 1 ? 'day' : '$days days';
    }

    return periodISO;
  }

  int _extractNumber(String periodISO) {
    final match = RegExp(r'(\d+)').firstMatch(periodISO);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  String getWeeklyPrice(StoreProduct product) {
    final price = product.price;
    final currencySymbol = product.currencyCode == 'USD' ? '\$' : product.currencyCode;
    final periodISO = product.subscriptionPeriod;

    if (periodISO == null || periodISO.isEmpty) {
      return product.priceString;
    }

    double weeklyPrice = 0.0;

    if (periodISO.contains('Y')) {
      final years = _extractNumber(periodISO);
      weeklyPrice = (price / years) / 52.143;
    } else if (periodISO.contains('M')) {
      final months = _extractNumber(periodISO);
      weeklyPrice = (price / months) / 4.345;
    } else if (periodISO.contains('W')) {
      final weeks = _extractNumber(periodISO);
      weeklyPrice = price / weeks;
    } else if (periodISO.contains('D')) {
      final days = _extractNumber(periodISO);
      weeklyPrice = (price / days) * 7;
    }

    return '$currencySymbol${weeklyPrice.toStringAsFixed(2)}/week';
  }

  bool hasTrialPeriod(StoreProduct product) {
    final introductoryPrice = product.introductoryPrice;
    if (introductoryPrice == null) return false;

    return introductoryPrice.period.isNotEmpty;
  }

  String? getTrialPeriodInfo(StoreProduct product) {
    final introductoryPrice = product.introductoryPrice;
    if (introductoryPrice == null) return null;

    final periodISO = introductoryPrice.period;
    if (periodISO.isEmpty) return null;

    int numberOfUnits = _extractNumber(periodISO);
    String unit = '';

    if (periodISO.contains('Y')) {
      unit = numberOfUnits == 1 ? 'year' : 'years';
    } else if (periodISO.contains('M')) {
      unit = numberOfUnits == 1 ? 'month' : 'months';
    } else if (periodISO.contains('W')) {
      unit = numberOfUnits == 1 ? 'week' : 'weeks';
    } else if (periodISO.contains('D')) {
      unit = numberOfUnits == 1 ? 'day' : 'days';
    }

    return '${numberOfUnits == 1 ? '' : '$numberOfUnits '}$unit free trial';
  }

  Map<String, dynamic> getProductInfo(StoreProduct product) {
    return {
      'id': product.identifier,
      'title': product.title,
      'description': product.description,
      'price': product.priceString,
      'weeklyPrice': getWeeklyPrice(product),
      'subscriptionPeriod': getSubscriptionPeriod(product),
      'hasTrial': hasTrialPeriod(product),
      'trialInfo': getTrialPeriodInfo(product),
    };
  }

  Future restorePurchase(BuildContext context) async {
    AnalyticsService.instance.logPremiumRestoreAttempted();
    try {
      await Purchases.restorePurchases();
      await checkPremiumStatus();

      if (havePremium.value) {
        AnalyticsService.instance.logPremiumRestored();
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext ctx) {
              return CupertinoAlertDialog(
                title: Text('Purchases Restored'),
                content: Text('Your purchases have been restored successfully.'),
                actions: [
                  CupertinoDialogAction(
                    child: Text('OK', style: TextStyle(color: CupertinoColors.black)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext ctx) {
              return CupertinoAlertDialog(
                title: Text('No Purchases Found'),
                content: Text('No previous purchases were found to restore.'),
                actions: [
                  CupertinoDialogAction(
                    child: Text("OK", style: TextStyle(color: CupertinoColors.black)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext ctx) {
            return CupertinoAlertDialog(
              title: Text('Error'),
              content: Text('An error occurred while restoring purchases: $e'),
              actions: [
                CupertinoDialogAction(
                  child: Text("OK", style: TextStyle(color: CupertinoColors.black)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }
}
