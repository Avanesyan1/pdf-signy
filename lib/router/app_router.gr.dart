// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [CategoriesScreen]
class CategoriesRoute extends PageRouteInfo<void> {
  const CategoriesRoute({List<PageRouteInfo>? children})
    : super(CategoriesRoute.name, initialChildren: children);

  static const String name = 'CategoriesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CategoriesScreen();
    },
  );
}

/// generated route for
/// [CreateSignatureScreen]
class CreateSignatureRoute extends PageRouteInfo<void> {
  const CreateSignatureRoute({List<PageRouteInfo>? children})
    : super(CreateSignatureRoute.name, initialChildren: children);

  static const String name = 'CreateSignatureRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateSignatureScreen();
    },
  );
}

/// generated route for
/// [CreateStampScreen]
class CreateStampRoute extends PageRouteInfo<void> {
  const CreateStampRoute({List<PageRouteInfo>? children})
    : super(CreateStampRoute.name, initialChildren: children);

  static const String name = 'CreateStampRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateStampScreen();
    },
  );
}

/// generated route for
/// [DocumentsListScreen]
class DocumentsListRoute extends PageRouteInfo<void> {
  const DocumentsListRoute({List<PageRouteInfo>? children})
    : super(DocumentsListRoute.name, initialChildren: children);

  static const String name = 'DocumentsListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DocumentsListScreen();
    },
  );
}

/// generated route for
/// [MainTabScreen]
class MainTabRoute extends PageRouteInfo<void> {
  const MainTabRoute({List<PageRouteInfo>? children})
    : super(MainTabRoute.name, initialChildren: children);

  static const String name = 'MainTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainTabScreen();
    },
  );
}

/// generated route for
/// [OnboardingScreen]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
    : super(OnboardingRoute.name, initialChildren: children);

  static const String name = 'OnboardingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OnboardingScreen();
    },
  );
}

/// generated route for
/// [PaywallScreen]
class PaywallRoute extends PageRouteInfo<void> {
  const PaywallRoute({List<PageRouteInfo>? children})
    : super(PaywallRoute.name, initialChildren: children);

  static const String name = 'PaywallRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PaywallScreen();
    },
  );
}

/// generated route for
/// [SelectSignatureScreen]
class SelectSignatureRoute extends PageRouteInfo<void> {
  const SelectSignatureRoute({List<PageRouteInfo>? children})
    : super(SelectSignatureRoute.name, initialChildren: children);

  static const String name = 'SelectSignatureRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SelectSignatureScreen();
    },
  );
}

/// generated route for
/// [SelectStampScreen]
class SelectStampRoute extends PageRouteInfo<void> {
  const SelectStampRoute({List<PageRouteInfo>? children})
    : super(SelectStampRoute.name, initialChildren: children);

  static const String name = 'SelectStampRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SelectStampScreen();
    },
  );
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsScreen();
    },
  );
}

/// generated route for
/// [SignDocumentScreen]
class SignDocumentRoute extends PageRouteInfo<SignDocumentRouteArgs> {
  SignDocumentRoute({
    Key? key,
    required Document document,
    List<PageRouteInfo>? children,
  }) : super(
         SignDocumentRoute.name,
         args: SignDocumentRouteArgs(key: key, document: document),
         initialChildren: children,
       );

  static const String name = 'SignDocumentRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SignDocumentRouteArgs>();
      return SignDocumentScreen(key: args.key, document: args.document);
    },
  );
}

class SignDocumentRouteArgs {
  const SignDocumentRouteArgs({this.key, required this.document});

  final Key? key;

  final Document document;

  @override
  String toString() {
    return 'SignDocumentRouteArgs{key: $key, document: $document}';
  }
}

/// generated route for
/// [SignaturesListScreen]
class SignaturesListRoute extends PageRouteInfo<void> {
  const SignaturesListRoute({List<PageRouteInfo>? children})
    : super(SignaturesListRoute.name, initialChildren: children);

  static const String name = 'SignaturesListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignaturesListScreen();
    },
  );
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashScreen();
    },
  );
}

/// generated route for
/// [StampsListScreen]
class StampsListRoute extends PageRouteInfo<void> {
  const StampsListRoute({List<PageRouteInfo>? children})
    : super(StampsListRoute.name, initialChildren: children);

  static const String name = 'StampsListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StampsListScreen();
    },
  );
}

/// generated route for
/// [StatisticsScreen]
class StatisticsRoute extends PageRouteInfo<void> {
  const StatisticsRoute({List<PageRouteInfo>? children})
    : super(StatisticsRoute.name, initialChildren: children);

  static const String name = 'StatisticsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StatisticsScreen();
    },
  );
}
