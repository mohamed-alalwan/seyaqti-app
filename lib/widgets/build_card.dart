import 'package:flutter/material.dart';

class BuildCard extends StatefulWidget {
  const BuildCard({
    super.key,
    required this.header,
    required this.color,
    this.customContent,
    this.content,
    this.footer,
  });
  final String header;
  final Color color;
  final Widget? customContent;
  final String? content;
  final String? footer;

  @override
  State<BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<BuildCard> {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: widget.color,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(widget.header, style: TextStyle(color: widget.color)),
              if (widget.content != null)
                Text(widget.content!,
                    style: TextStyle(color: widget.color, fontSize: 40)),
              if (widget.customContent != null) widget.customContent!,
              if (widget.footer != null) Text(widget.footer!),
            ],
          ),
        ),
      ),
    );
  }
}
