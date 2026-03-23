import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/journey_provider.dart';
import '../themes/app_theme.dart';
import '../../data/models/journey_models.dart';
import 'glass_card.dart';

/// Onboarding Prompt for new users (shown on Dashboard after first login)
class OnboardingPrompt extends StatefulWidget {
  final VoidCallback onDismiss;

  const OnboardingPrompt({
    super.key,
    required this.onDismiss,
  });

  /// Static helper to show as a modal bottom sheet
  static void show(BuildContext context, {required VoidCallback onDismiss}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OnboardingPrompt(onDismiss: onDismiss),
    ).then((_) {
      // Trigger onDismiss if user closed sheet by tapping outside or dragging down
      onDismiss();
    });
  }

  @override
  State<OnboardingPrompt> createState() => _OnboardingPromptState();
}

class _OnboardingPromptState extends State<OnboardingPrompt> {
  bool _isLoading = true;
  List<JourneySummaryDto> _journeys = [];

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    try {
      final provider = context.read<JourneyProvider>();
      // Use existing method to load page 0
      await provider.loadJourneys(page: 0, size: 5);
      if (mounted) {
        setState(() {
          _journeys = provider.journeys;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.galaxyDark : AppTheme.lightBackgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(isDark),
              const SizedBox(height: 24),

              // Content
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_journeys.isNotEmpty)
                _buildJourneyList(isDark)
              else
                _buildNewUserGuide(isDark),
              
              const SizedBox(height: 32),

              // Actions
              _buildActions(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _journeys.isNotEmpty
                    ? 'Tiếp tục hành trình'
                    : 'Chào mừng đến với Skillverse!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _journeys.isNotEmpty
                    ? 'Chọn một hành trình để tiếp tục ngay.'
                    : 'Đây là 3 bước đơn giản để bắt đầu:',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDismiss();
          },
        ),
      ],
    );
  }

  Widget _buildJourneyList(bool isDark) {
    return Column(
      children: _journeys.take(3).map((journey) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.domain,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journey.jobRole ?? journey.goal,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (journey.progressPercentage) / 100,
                          minHeight: 6,
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(AppTheme.accentCyan),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDismiss();
                    context.push('/journey');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: AppTheme.primaryBlueDark,
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewUserGuide(bool isDark) {
    final steps = [
      {
        'icon': Icons.map_outlined,
        'title': 'Đánh giá năng lực đầu vào',
        'desc': 'Quiz theo ngành và vai trò để xác định level chính xác.',
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'AI phân tích kỹ năng',
        'desc': 'Kết quả chi tiết, nhận diện điểm mạnh và lỗ hổng.',
      },
      {
        'icon': Icons.route_outlined,
        'title': 'Roadmap học cá nhân hóa',
        'desc': 'Lộ trình tối ưu được tạo riêng dựa trên kết quả của bạn.',
      },
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  step['icon'] as IconData,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bước ${index + 1}: ${step['title']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['desc'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActions(bool isDark) {
    if (_journeys.isNotEmpty) {
      return OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onDismiss();
          context.push('/journey');
        },
        child: const Text('Xem tất cả hành trình'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDismiss();
            // Điều hướng tới trang tạo journey
            context.push('/journey/create');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.primaryBlueDark,
          ),
          child: const Text(
            'Bắt đầu Journey đầu tiên',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDismiss();
          },
          child: Text(
            'Khám phá sau',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
