import 'package:flutter/material.dart';

class MapTutorialDialog extends StatefulWidget {
  const MapTutorialDialog({super.key});

  @override
  State<MapTutorialDialog> createState() => _MapTutorialDialogState();
}

class _MapTutorialDialogState extends State<MapTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // The actual content for your tutorial
  final List<_TutorialStep> _steps = [
    _TutorialStep(
      icon: Icons.map_outlined,
      title: "Map Overview",
      description:
          "See active evacuation centers, command posts, and safe zones around you in real-time.",
    ),
    _TutorialStep(
      icon: Icons.my_location_rounded,
      title: "Set Home Location",
      description:
          "Long-press the map to set your current coordinates (You need internet connection for this action).",
    ),
    _TutorialStep(
      icon: Icons.add_home_work_rounded,
      title: "Establish Centers",
      description:
          "Authorized staff can tap the map to deploy new evacuation centers and update capacities.",
    ),
    _TutorialStep(
      icon: Icons.wifi_off_rounded,
      title: "Offline Ready",
      description:
          "No signal? Keep working. Kalig-onan automatically syncs your data once the connection returns.",
    ),
  ];

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop(); // Close tutorial on the last step
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _steps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.scaffoldBackgroundColor,
      // Keeping it compact so they can still see the map edges
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Row: Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quick Guide",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey.shade600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Middle: The Swipable Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(
                            50,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Bottom: Dot Indicators & Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Button (Hidden on page 1)
                Opacity(
                  opacity: _currentPage == 0 ? 0.0 : 1.0,
                  child: TextButton(
                    onPressed: _currentPage == 0 ? null : _previousPage,
                    child: const Text("Back"),
                  ),
                ),

                // Dot Indicators
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next / Finish Button
                FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isLastPage ? "Got it" : "Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Simple data class for the tutorial steps
class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;

  _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
