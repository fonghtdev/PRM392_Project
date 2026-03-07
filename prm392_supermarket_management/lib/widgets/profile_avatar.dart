import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 128,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                width: 4,
              )
            : null,
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: imageUrl != null && 
            imageUrl!.isNotEmpty && 
            (imageUrl!.startsWith('http') || imageUrl!.startsWith('https'))
            ? NetworkImage(imageUrl!)
            : null,
        child: imageUrl == null || 
            imageUrl!.isEmpty || 
            (!imageUrl!.startsWith('http') && !imageUrl!.startsWith('https'))
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : null,
      ),
    );
  }
}