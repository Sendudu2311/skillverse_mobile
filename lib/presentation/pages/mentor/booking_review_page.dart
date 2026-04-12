import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/glass_card.dart';
import '../../../data/services/booking_review_service.dart';
import '../../../data/models/booking_review_model.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/skillverse_app_bar.dart';

class BookingReviewPage extends StatefulWidget {
  final int bookingId;
  final String? mentorName;

  const BookingReviewPage({
    super.key,
    required this.bookingId,
    this.mentorName,
  });

  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage> {
  final BookingReviewService _reviewService = BookingReviewService();
  final TextEditingController _commentController = TextEditingController();

  int _selectedRating = 5;
  bool _isAnonymous = false;
  bool _isLoading = false;
  bool _isCheckingExisting = true;
  BookingReview? _existingReview;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReview() async {
    try {
      _existingReview = await _reviewService.getReviewByBookingId(
        widget.bookingId,
      );
    } catch (_) {
      // No existing review
    } finally {
      if (mounted) {
        setState(() => _isCheckingExisting = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Vui lòng nhập nhận xét');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final review = await _reviewService.createReview(
        widget.bookingId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        isAnonymous: _isAnonymous,
      );
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Đã gửi đánh giá!');
        Navigator.of(context).pop(review);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Lỗi gửi đánh giá: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: _existingReview != null ? 'Đánh giá của bạn' : 'Đánh giá mentor',
      ),
      body: _isCheckingExisting
          ? CommonLoading.center()
          : _existingReview != null
          ? _buildExistingReview(isDark)
          : _buildReviewForm(isDark),
    );
  }

  // ==================== Existing Review ====================

  Widget _buildExistingReview(bool isDark) {
    final review = _existingReview!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: AppTheme.accentGold,
                        size: 36,
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Comment
                  if (review.comment != null && review.comment!.isNotEmpty)
                    Text(
                      review.comment!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 12),

                  // Created at
                  if (review.createdAt != null)
                    Text(
                      'Đã đánh giá lúc ${_formatDateTime(review.createdAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),

                  // Mentor reply
                  if (review.hasReply) ...[
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueDark.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 16,
                                color: AppTheme.primaryBlueDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Phản hồi từ Mentor',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlueDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.reply!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Review Form ====================

  Widget _buildReviewForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    size: 40,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.mentorName != null
                      ? 'Đánh giá ${widget.mentorName}'
                      : 'Đánh giá buổi học',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chia sẻ trải nghiệm của bạn để giúp mentor cải thiện',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Star Rating ─────────────────────────────
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Đánh giá sao',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starValue <= _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppTheme.accentGold,
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingLabel(_selectedRating),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Comment ─────────────────────────────────
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhận xét',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Mô tả trải nghiệm của bạn với mentor (bắt buộc)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Anonymous switch ────────────────────────
          GlassCard(
            child: SwitchListTile(
              title: Text(
                'Đánh giá ẩn danh',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                'Mentor sẽ không biết ai đánh giá',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
              activeTrackColor: AppTheme.primaryBlueDark,
            ),
          ),
          const SizedBox(height: 28),

          // ── Submit button ───────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CommonLoading.button(
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gửi đánh giá',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Helpers ====================

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Rất kém';
      case 2:
        return 'Kém';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tốt';
      case 5:
        return 'Xuất sắc';
      default:
        return '';
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}
