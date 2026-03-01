import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_checker.dart';
import '../utils/theme.dart';

/// Widget yang di-wrap di HomeShell untuk cek update otomatis
/// dan tampilkan banner jika ada update tersedia.
class UpdateBannerWrapper extends StatefulWidget {
  final Widget child;
  final AppTheme theme;

  const UpdateBannerWrapper({
    super.key,
    required this.child,
    required this.theme,
  });

  @override
  State<UpdateBannerWrapper> createState() => _UpdateBannerWrapperState();
}

class _UpdateBannerWrapperState extends State<UpdateBannerWrapper> {
  UpdateInfo? _updateInfo;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _checkOnStartup();
  }

  Future<void> _checkOnStartup() async {
    // Tunggu sebentar supaya UI sudah render dulu
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final info = await UpdateChecker.check();
    if (mounted && info.hasUpdate) {
      setState(() => _updateInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_updateInfo != null && !_dismissed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _UpdateBanner(
              info: _updateInfo!,
              theme: widget.theme,
              onDismiss: () => setState(() => _dismissed = true),
            )
                .animate()
                .slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(duration: 300.ms),
          ),
      ],
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final UpdateInfo info;
  final AppTheme theme;
  final VoidCallback onDismiss;

  const _UpdateBanner({
    required this.info,
    required this.theme,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.shade700,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.upgrade_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Tersedia!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Versi ${info.latestVersion} sudah rilis. Ketuk untuk unduh.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Download button
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(UpdateChecker.releasesUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Unduh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.orangeAccent.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dismiss
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
