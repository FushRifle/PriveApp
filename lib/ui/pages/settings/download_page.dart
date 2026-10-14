import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  bool _wifiOnly = true;
  bool _saveToGallery = false;
  String _quality = 'Original';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Downloads',
            subtitle: 'Control saved media and data usage',
            leadingIcon: Icons.arrow_back_rounded,
            onLeadingTap: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 32),
              children: [
                _DownloadSummary(quality: _quality),
                const SizedBox(height: 12),
                _SettingsCard(
                  title: 'Download preferences',
                  children: [
                    SwitchListTile.adaptive(
                      value: _wifiOnly,
                      activeColor: AppColors.secondary,
                      onChanged: (value) => setState(() => _wifiOnly = value),
                      secondary: const _TileIcon(Icons.wifi_rounded),
                      title: const _TileTitle('Wi-Fi only'),
                      subtitle: const _TileSubtitle(
                        'Avoid using mobile data for downloads',
                      ),
                    ),
                    const _Divider(),
                    SwitchListTile.adaptive(
                      value: _saveToGallery,
                      activeColor: AppColors.secondary,
                      onChanged: (value) =>
                          setState(() => _saveToGallery = value),
                      secondary: const _TileIcon(Icons.photo_library_outlined),
                      title: const _TileTitle('Save to gallery'),
                      subtitle: const _TileSubtitle(
                        'Keep downloaded media in your device gallery',
                      ),
                    ),
                    const _Divider(),
                    ListTile(
                      leading: const _TileIcon(Icons.high_quality_rounded),
                      title: const _TileTitle('Media quality'),
                      subtitle: _TileSubtitle(_quality),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _chooseQuality,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  title: 'Storage',
                  children: [
                    ListTile(
                      leading:
                          const _TileIcon(Icons.cleaning_services_outlined),
                      title: const _TileTitle('Clear downloaded media'),
                      subtitle: const _TileSubtitle(
                        'Remove local copies without deleting your posts',
                      ),
                      trailing: Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.redColor,
                      ),
                      onTap: _confirmClear,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseQuality() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),
              for (final quality in ['Original', 'High', 'Data saver'])
                RadioListTile<String>(
                  value: quality,
                  groupValue: _quality,
                  activeColor: AppColors.secondary,
                  title: _TileTitle(quality),
                  onChanged: (value) => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _quality = selected);
  }

  void _confirmClear() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Clear downloaded media?'),
        content: const Text(
          'Local media copies will be removed. Your posts and cloud media stay available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Downloaded media cleared')),
              );
            },
            child: Text('Clear', style: TextStyle(color: AppColors.redColor)),
          ),
        ],
      ),
    );
  }
}

class _DownloadSummary extends StatelessWidget {
  final String quality;

  const _DownloadSummary({required this.quality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const _TileIcon(Icons.download_done_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media downloads',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$quality quality · managed on this device',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
          child: Text(
            title,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 10.5,
              fontWeight: AppTheme.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  const _TileIcon(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.secondary, size: 18),
      );
}

class _TileTitle extends StatelessWidget {
  final String text;
  const _TileTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 13,
          fontWeight: AppTheme.semiBold,
        ),
      );
}

class _TileSubtitle extends StatelessWidget {
  final String text;
  const _TileSubtitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 58,
        color: AppColors.border.withOpacity(0.45),
      );
}
