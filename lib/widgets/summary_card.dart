import 'package:flutter/material.dart';

class SummaryCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(_isHovered ? 0.18 : 0.10),
                  color.withOpacity(_isHovered ? 0.08 : 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: color.withOpacity(_isHovered ? 0.45 : 0.22),
                width: _isHovered ? 1.8 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(_isHovered ? 0.24 : 0.08),
                  blurRadius: _isHovered ? 20.0 : 10.0,
                  offset: Offset(0, _isHovered ? 8.0 : 4.0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Stack(
                children: [
                  // Decorative background subtle icon watermark
                  Positioned(
                    right: -12,
                    bottom: -12,
                    child: Icon(
                      widget.icon,
                      size: 76,
                      color: color.withOpacity(0.06),
                    ),
                  ),
                  // Content padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with floating icon badge and arrow indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(color: color.withOpacity(0.3), width: 1.2),
                              ),
                              child: Icon(
                                widget.icon,
                                color: color,
                                size: 20,
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(_isHovered ? 0.18 : 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: color.withOpacity(_isHovered ? 1.0 : 0.7),
                              ),
                            ),
                          ],
                        ),
                        // Bottom Value and Title
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.value,
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: color.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
