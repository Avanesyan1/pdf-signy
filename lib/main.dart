import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pdf_signy/firebase_options.dart';
import 'package:pdf_signy/services/notification_service.dart';
import 'package:pdf_signy/services/premium_service.dart';
import 'package:pdf_signy/services/analytics_service.dart';
import 'database/database.dart';
import 'router/app_router.dart';

final appRouter = AppRouter();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AnalyticsService.instance.init();

  PremiumService.instance.init();
  NotificationService.instance.init();
  AppDatabase.instance;

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      title: 'PDF Signy',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemRed,
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.white,
        barBackgroundColor: CupertinoColors.white,
      ),
      routerDelegate: appRouter.delegate(),
      routeInformationParser: appRouter.defaultRouteParser(),
    );
  }
}
