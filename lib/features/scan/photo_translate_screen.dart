import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../data/services/text_ocr_service.dart';
import 'scan_strings.dart';

/// Picks or captures a photo, reads the text on it on-device, and pops the
/// recognised text back to the caller so the normal translation flow takes
/// over from there.
class PhotoTranslateScreen extends StatefulWidget {
  const PhotoTranslateScreen({super.key});

  @override
  State<PhotoTranslateScreen> createState() => _PhotoTranslateScreenState();
}

class _PhotoTranslateScreenState extends State<PhotoTranslateScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextOcr _ocr = TextOcr();

  Uint8List? _preview;
  bool _busy = false;
  bool _empty = false;
  bool _failed = false;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _empty = false;
      _failed = false;
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 90,
      );
      if (picked == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _preview = bytes);

      final text = await _ocr.recognizeText(picked.path);
      if (!mounted) return;
      if (text.trim().isEmpty) {
        setState(() {
          _busy = false;
          _empty = true;
        });
        return;
      }
      Navigator.of(context).pop(text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ScanStrings.of(context);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.hint,
                style: TextStyle(
                  color: palette.textSoft,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_camera_rounded,
                      label: strings.camera,
                      onTap:
                          _busy ? null : () => _capture(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: strings.gallery,
                      onTap:
                          _busy ? null : () => _capture(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (_preview != null) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: AppRadius.lg,
                  child: Image.memory(
                    _preview!,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 22),
                const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    strings.reading,
                    style: TextStyle(
                      color: palette.textSoft,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              if (_empty || _failed) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.10),
                    borderRadius: AppRadius.md,
                  ),
                  child: Text(
                    _empty ? strings.empty : strings.failed,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.surfaceAlt,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, size: 26, color: palette.primary),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
