import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DoctorAvatar extends StatelessWidget {
  final Map<String, dynamic>? doctor;
  final String? avatarUrl;
  final double size;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const DoctorAvatar({
    super.key,
    this.doctor,
    this.avatarUrl,
    this.size = 48,
    this.border,
    this.borderRadius,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    String? rawAvatar = avatarUrl;
    if (rawAvatar == null || rawAvatar.isEmpty) {
      if (doctor != null) {
        rawAvatar = (doctor!['avatar'] ??
                doctor!['avatar_url'] ??
                doctor!['image_url'] ??
                doctor!['image'] ??
                doctor!['photo_url'] ??
                doctor!['photo'])
            ?.toString();
      }
    }

    final double effectiveRadius = isCircle ? size / 2 : (borderRadius?.topLeft.x ?? 16);
    final clipRadius = BorderRadius.circular(effectiveRadius);

    // Placeholder kosong ala WhatsApp (lingkaran abu-abu dengan siluet kepala & pundak)
    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : borderRadius ?? BorderRadius.circular(16),
        border: border,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: const Color(0xFF94A3B8),
          size: size * 0.62,
        ),
      ),
    );

    if (rawAvatar == null || rawAvatar.trim().isEmpty) {
      return placeholder;
    }

    final avatar = rawAvatar.trim();

    Widget imageWidget;
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      imageWidget = Image.network(
        avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (avatar.startsWith('/uploads/')) {
      final fullUrl = '${ApiService.baseUrl}$avatar';
      imageWidget = Image.network(
        fullUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (avatar.startsWith('data:image/') || avatar.contains(';base64,')) {
      try {
        final base64Str = avatar.contains(';base64,') ? avatar.split(';base64,').last : avatar;
        final bytes = base64Decode(base64Str.trim());
        imageWidget = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (_) {
        return placeholder;
      }
    } else if (avatar.startsWith('file:')) {
      final path = avatar.replaceFirst('file:', '');
      imageWidget = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (avatar.startsWith('asset:') || avatar.startsWith('assets/')) {
      final path = avatar.startsWith('asset:') ? avatar.replaceFirst('asset:', '') : avatar;
      imageWidget = Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (avatar.startsWith('emoji:')) {
      final emoji = avatar.replaceFirst('emoji:', '');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : borderRadius ?? BorderRadius.circular(16),
          border: border,
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      );
    } else if (avatar.startsWith('/')) {
      imageWidget = Image.file(
        File(avatar),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      return placeholder;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : borderRadius ?? BorderRadius.circular(16),
        border: border,
      ),
      child: ClipRRect(
        borderRadius: clipRadius,
        child: imageWidget,
      ),
    );
  }
}
