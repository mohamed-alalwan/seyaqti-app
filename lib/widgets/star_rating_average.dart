import 'package:flutter/material.dart';

class StarRatingAverage extends StatelessWidget {
  const StarRatingAverage({super.key, required this.avg});
  final double avg;

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 12),
          children: [
            WidgetSpan(
              child: Stack(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.grey,
                    size: 14,
                  ),
                  if (avg >= 0.5)
                    Icon(
                      (avg >= 0.75) ? Icons.star : Icons.star_half,
                      color: Colors.yellow[700],
                      size: 14,
                    ),
                ],
              ),
            ),
            WidgetSpan(
              child: Stack(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.grey,
                    size: 14,
                  ),
                  if (avg >= 1.5)
                    Icon(
                      (avg >= 1.75) ? Icons.star : Icons.star_half,
                      color: Colors.yellow[700],
                      size: 14,
                    ),
                ],
              ),
            ),
            WidgetSpan(
              child: Stack(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.grey,
                    size: 14,
                  ),
                  if (avg >= 2.5)
                    Icon(
                      (avg >= 2.75) ? Icons.star : Icons.star_half,
                      color: Colors.yellow[700],
                      size: 14,
                    ),
                ],
              ),
            ),
            WidgetSpan(
              child: Stack(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.grey,
                    size: 14,
                  ),
                  if (avg >= 3.5)
                    Icon(
                      (avg >= 3.75) ? Icons.star : Icons.star_half,
                      color: Colors.yellow[700],
                      size: 14,
                    ),
                ],
              ),
            ),
            WidgetSpan(
              child: Stack(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.grey,
                    size: 14,
                  ),
                  if (avg >= 4.5)
                    Icon(
                      (avg >= 4.75) ? Icons.star : Icons.star_half,
                      color: Colors.yellow[700],
                      size: 14,
                    ),
                ],
              ),
            ),
            TextSpan(
              text: ' (${num.parse(avg.toStringAsFixed(2))})',
              style: TextStyle(color: Colors.yellow[700]),
            ),
          ],
        ),
      );
}
