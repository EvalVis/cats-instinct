import 'package:flutter/material.dart';

class SpeedMeter extends StatelessWidget {
  final double currentDelay;
  final double maxDelay;
  final double minDelay;

  const SpeedMeter({
    super.key,
    required this.currentDelay,
    this.maxDelay = 1000.0,
    this.minDelay = 0.0,
  });

  List<int> _generateLabels() {
    final labels = <int>[];
    final range = maxDelay - minDelay;
    for (int i = 0; i <= 10; i++) {
      final labelValue = (minDelay + (i / 10.0) * range).round();
      labels.add(labelValue);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final labels = _generateLabels();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double barWidth = constraints.maxWidth;
          double normalizedDelay =
              ((currentDelay - minDelay) / (maxDelay - minDelay)) * 1000.0;
          double fillPercentage = (1000 - normalizedDelay) / 1000.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: barWidth,
                height: 20,
                child: Stack(
                  children: labels
                      .asMap()
                      .entries
                      .map((entry) {
                        int index = entry.key;
                        int label = entry.value;
                        double availableWidth = barWidth - 36;
                        double position = (index / 10.0) * availableWidth;
                        return Positioned(
                          left: position,
                          top: 0,
                          child: Text(
                            label.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: barWidth,
                height: 40,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: fillPercentage * (barWidth - 4),
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: fillPercentage * (barWidth - 4) > (barWidth - 8)
                              ? BorderRadius.circular(18)
                              : const BorderRadius.horizontal(
                                  left: Radius.circular(18),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

