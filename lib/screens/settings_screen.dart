import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_links.dart';
import '../router/app_router.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.white,
        middle: const Text(
          'Settings',
          style: TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w600),
        ),
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SettingsSection(
              title: 'Information',
              children: [
                _SettingsItem(
                  icon: CupertinoIcons.lock_shield,
                  iconColor: CupertinoColors.systemGrey,
                  title: 'Privacy Policy',
                  onTap: () => _openUrl(context, AppLinks.privacyPolicy),
                  isLast: false,
                ),
                _SettingsItem(
                  icon: CupertinoIcons.doc_text,
                  iconColor: CupertinoColors.systemGrey,
                  title: 'Terms of Use',
                  onTap: () => _openUrl(context, AppLinks.termsOfUse),
                  isLast: false,
                ),
                _SettingsItem(
                  icon: CupertinoIcons.star,
                  iconColor: CupertinoColors.systemGrey,
                  title: 'Rate App',
                  onTap: () => _rateApp(context),
                  isLast: false,
                ),
                _SettingsItem(
                  icon: CupertinoIcons.envelope,
                  iconColor: CupertinoColors.systemGrey,
                  title: 'Support',
                  onTap: () => _openUrl(context, AppLinks.support),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'Data & Management',
              children: [
                _SettingsItem(
                  icon: CupertinoIcons.chart_bar,
                  iconColor: CupertinoColors.systemGrey,
                  title: 'Statistics',
                  onTap: () => context.router.push(const StatisticsRoute()),
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: const Text('Could not open the link.'),
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
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to open link: $e'),
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

  Future<void> _rateApp(BuildContext context) async {
    if (await InAppReview.instance.isAvailable()) {
      InAppReview.instance.requestReview();
    }
  }

}

class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CupertinoColors.separator.withOpacity(0.3), width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: CupertinoColors.separator.withOpacity(0.3), width: 0.5),
              ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey2,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
