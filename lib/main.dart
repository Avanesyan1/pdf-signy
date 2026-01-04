import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database.dart';
import 'router/app_router.dart';

final appRouter = AppRouter();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем базу данных
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
