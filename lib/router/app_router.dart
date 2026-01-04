import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf_signy/database/database.dart';
import '../screens/create_signature_screen.dart';
import '../screens/signatures_list_screen.dart';
import '../screens/documents_list_screen.dart';
import '../screens/main_tab_screen.dart';
import '../screens/sign_document_screen.dart';
import '../screens/select_signature_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/create_stamp_screen.dart';
import '../screens/stamps_list_screen.dart';
import '../screens/select_stamp_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    CupertinoRoute(page: OnboardingRoute.page, initial: true),
    AutoRoute(
      page: MainTabRoute.page,
      children: [
        CupertinoRoute(page: DocumentsListRoute.page),
        CupertinoRoute(page: SignaturesListRoute.page),
        CupertinoRoute(page: StampsListRoute.page),
        CupertinoRoute(page: SettingsRoute.page),
      ],
    ),
    CupertinoRoute(page: CreateSignatureRoute.page),
    CupertinoRoute(page: SignDocumentRoute.page),
    CupertinoRoute(page: SelectSignatureRoute.page),
    CupertinoRoute(page: CategoriesRoute.page),
    CupertinoRoute(page: StatisticsRoute.page),
    CupertinoRoute(page: CreateStampRoute.page),
    CupertinoRoute(page: SelectStampRoute.page),
  ];
}
