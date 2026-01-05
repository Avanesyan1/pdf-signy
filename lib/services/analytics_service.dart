import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();

  factory AnalyticsService() => instance;

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _isInitialized = true;
      AppLogger().info('Analytics service initialized');
    } catch (e) {
      AppLogger().error('Error initializing analytics: $e');
    }
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (!_isInitialized || _analytics == null) {
      if (kDebugMode) {
        AppLogger().debug('Analytics not initialized, event: $name');
      }
      return;
    }

    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        AppLogger().debug('Analytics event: $name, params: $parameters');
      }
    } catch (e) {
      AppLogger().error('Error logging analytics event: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {'screen_name': screenName});
  }

  // Screen events
  Future<void> logSplashScreen() => logScreenView('splash');
  Future<void> logOnboardingScreen() => logScreenView('onboarding');
  Future<void> logPaywallScreen() => logScreenView('paywall');
  Future<void> logDocumentsListScreen() => logScreenView('documents_list');
  Future<void> logSignDocumentScreen() => logScreenView('sign_document');
  Future<void> logSignaturesListScreen() => logScreenView('signatures_list');
  Future<void> logCreateSignatureScreen() => logScreenView('create_signature');
  Future<void> logStampsListScreen() => logScreenView('stamps_list');
  Future<void> logCreateStampScreen() => logScreenView('create_stamp');
  Future<void> logSettingsScreen() => logScreenView('settings');
  Future<void> logStatisticsScreen() => logScreenView('statistics');
  Future<void> logCategoriesScreen() => logScreenView('categories');

  // Document events
  Future<void> logDocumentAdded(String source) =>
      logEvent('document_added', {'source': source}); // 'scan', 'file_picker', 'image'

  Future<void> logDocumentSigned({required bool isFree, required int documentId}) =>
      logEvent('document_signed', {
        'is_free': isFree,
        'document_id': documentId,
      });

  Future<void> logDocumentDeleted() => logEvent('document_deleted');
  Future<void> logDocumentShared() => logEvent('document_shared');
  Future<void> logDocumentPrinted() => logEvent('document_printed');
  Future<void> logDocumentRenamed() => logEvent('document_renamed');
  Future<void> logDocumentDuplicated() => logEvent('document_duplicated');
  Future<void> logDocumentFavoriteToggled({required bool isFavorite}) =>
      logEvent('document_favorite_toggled', {'is_favorite': isFavorite});

  // Signature events
  Future<void> logSignatureCreated() => logEvent('signature_created');
  Future<void> logSignatureDeleted() => logEvent('signature_deleted');
  Future<void> logSignatureSelected() => logEvent('signature_selected');

  // Stamp events
  Future<void> logStampCreated() => logEvent('stamp_created');
  Future<void> logStampDeleted() => logEvent('stamp_deleted');
  Future<void> logStampSelected() => logEvent('stamp_selected');

  // Premium events
  Future<void> logPaywallShown({String? source}) =>
      logEvent('paywall_shown', source != null ? {'source': source} : null);

  Future<void> logPremiumPurchased({required String productId}) =>
      logEvent('premium_purchased', {'product_id': productId});

  Future<void> logPremiumRestoreAttempted() => logEvent('premium_restore_attempted');
  Future<void> logPremiumRestored() => logEvent('premium_restored');
  Future<void> logPremiumPurchaseCancelled() => logEvent('premium_purchase_cancelled');
  Future<void> logPremiumPurchaseFailed({String? error}) =>
      logEvent('premium_purchase_failed', error != null ? {'error': error} : null);

  // Onboarding events
  Future<void> logOnboardingCompleted() => logEvent('onboarding_completed');
  Future<void> logOnboardingSkipped() => logEvent('onboarding_skipped');

  // Free signature limit
  Future<void> logFreeSignatureLimitReached() => logEvent('free_signature_limit_reached');
  Future<void> logFreeSignatureUsed({required int documentId}) =>
      logEvent('free_signature_used', {'document_id': documentId});

  // Settings events
  Future<void> logPrivacyPolicyOpened() => logEvent('privacy_policy_opened');
  Future<void> logTermsOfUseOpened() => logEvent('terms_of_use_opened');
  Future<void> logSupportOpened() => logEvent('support_opened');
  Future<void> logAppRated() => logEvent('app_rated');

  // Category events
  Future<void> logCategoryCreated() => logEvent('category_created');
  Future<void> logCategoryDeleted() => logEvent('category_deleted');
  Future<void> logCategorySelected({required int categoryId}) =>
      logEvent('category_selected', {'category_id': categoryId});

  // Error events
  Future<void> logError(String error, {String? screen}) =>
      logEvent('error_occurred', {
        'error': error,
        if (screen != null) 'screen': screen,
      });
}


