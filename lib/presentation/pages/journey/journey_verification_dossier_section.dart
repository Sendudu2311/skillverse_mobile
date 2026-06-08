import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/node_mentoring_models.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';

/// Collapsible dossier section showing all node evidence statuses
/// for a journey in one view — mirrors Web's JourneyVerificationDossier.
class JourneyVerificationDossierSection extends StatefulWidget {
  final Map<String, NodeEvidenceRecordResponse?> nodeEvidences;
  final Map<String, String> nodeTitles; // nodeId → human-readable title
  final bool isLoading;
  final String? learnerName;
  final String? learnerAvatarUrl;

  const JourneyVerificationDossierSection({
    super.key,
    required this.nodeEvidences,
    required this.nodeTitles,
    this.isLoading = false,
    this.learnerName,
    this.learnerAvatarUrl,
  });

  @override
  State<JourneyVerificationDossierSection> createState() =>
      _JourneyVerificationDossierSectionState();
}

class _JourneyVerificationDossierSectionState
    extends State<JourneyVerificationDossierSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;

  List<MapEntry<String, NodeEvidenceRecordResponse>> get _submitted =>
      widget.nodeEvidences.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!))
          .toList();

  int get _totalNodes => widget.nodeEvidences.length;

  int get _verifiedCount => _submitted
      .where((e) =>
          e.value.verificationStatus == NodeVerificationStatus.verified)
      .length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isLoading) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 16),
            CommonLoading.small(),
            const SizedBox(height: 8),
            Text(
              'Đang tải dossier node...',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_totalNodes == 0) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 12),
                _buildProgressBar(isDark),
                const SizedBox(height: 12),
                if (_submitted.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ..._buildNodeCards(isDark),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Personalized learner row ──
        if (widget.learnerName != null) ...[
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? AppTheme.accentCyan.withValues(alpha: 0.2)
                    : AppTheme.primaryBlue.withValues(alpha: 0.1),
                backgroundImage: widget.learnerAvatarUrl != null
                    ? NetworkImage(widget.learnerAvatarUrl!)
                    : null,
                child: widget.learnerAvatarUrl == null
                    ? Text(
                        widget.learnerName!.isNotEmpty
                            ? widget.learnerName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.accentCyan
                              : AppTheme.primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dossier của ${widget.learnerName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        // ── Collapse header ──
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(
            Icons.folder_shared_outlined,
            size: 20,
            color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dossier Minh chứng Node',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.accentCyan : AppTheme.primaryBlue)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_submitted.length}/$_totalNodes',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.expand_more,
              size: 20,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            ),
          ],
        ),
        ),
      ],
    );
  }

  // ─── Progress Bar ──────────────────────────────────────────────────────

  Widget _buildProgressBar(bool isDark) {
    final ratio = _totalNodes > 0 ? _verifiedCount / _totalNodes : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đã xác thực',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            Text(
              '$_verifiedCount / $_totalNodes node',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio >= 1.0 ? AppTheme.successColor : AppTheme.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 32,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có minh chứng nào được nộp.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Node Cards ────────────────────────────────────────────────────────

  List<Widget> _buildNodeCards(bool isDark) {
    return _submitted.asMap().entries.map((indexed) {
      final index = indexed.key;
      final entry = indexed.value;
      final nodeId = entry.key;
      final evidence = entry.value;
      final title = widget.nodeTitles[nodeId] ?? 'Node $nodeId';

      return TweenAnimationBuilder<double>(
        key: ValueKey(nodeId),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 200 + (index * 60)),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _NodeEvidenceCard(
            nodeId: nodeId,
            title: title,
            evidence: evidence,
            isDark: isDark,
          ),
        ),
      );
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Individual Node Evidence Card
// ═══════════════════════════════════════════════════════════════════════════

class _NodeEvidenceCard extends StatefulWidget {
  final String nodeId;
  final String title;
  final NodeEvidenceRecordResponse evidence;
  final bool isDark;

  const _NodeEvidenceCard({
    required this.nodeId,
    required this.title,
    required this.evidence,
    required this.isDark,
  });

  @override
  State<_NodeEvidenceCard> createState() => _NodeEvidenceCardState();
}

class _NodeEvidenceCardState extends State<_NodeEvidenceCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.evidence.verificationStatus) {
      case NodeVerificationStatus.verified:
        return AppTheme.successColor;
      case NodeVerificationStatus.approved:
        return const Color(0xFF4CAF50);
      case NodeVerificationStatus.rejected:
        return AppTheme.errorColor;
      case NodeVerificationStatus.underReview:
        return AppTheme.warningColor;
      case NodeVerificationStatus.pending:
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel =>
      widget.evidence.verificationStatus?.displayName ?? 'Chờ xử lý';

  IconData get _statusIcon {
    switch (widget.evidence.verificationStatus) {
      case NodeVerificationStatus.verified:
      case NodeVerificationStatus.approved:
        return Icons.check_circle;
      case NodeVerificationStatus.rejected:
        return Icons.cancel;
      case NodeVerificationStatus.underReview:
        return Icons.hourglass_top;
      case NodeVerificationStatus.pending:
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: _statusColor, width: 3),
        ),
      ),
      child: Column(
        children: [
          // ── Summary row ──────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(_statusIcon, size: 18, color: _statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.evidence.latestReview?.score != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.evidence.latestReview!.score}/100',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: widget.isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable detail ──────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded ? _buildDetail() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail() {
    final ev = widget.evidence;
    final textColor = widget.isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final subColor = widget.isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Submission text
          if (ev.submissionText != null && ev.submissionText!.isNotEmpty) ...[
            _fieldLabel('Bài nộp', subColor),
            const SizedBox(height: 4),
            Text(
              ev.submissionText!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.4),
            ),
            const SizedBox(height: 10),
          ],

          // Evidence URL
          if (ev.evidenceUrl != null && ev.evidenceUrl!.isNotEmpty)
            _buildUrlRow('Evidence URL', ev.evidenceUrl!, subColor),

          // Attachment URL
          if (ev.attachmentUrl != null && ev.attachmentUrl!.isNotEmpty)
            _buildUrlRow('Tệp đính kèm', ev.attachmentUrl!, subColor),

          // Mentor feedback (from latestReview)
          if (ev.latestReview?.feedback != null) ...[
            _fieldLabel('Nhận xét Mentor', subColor),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppTheme.primaryBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ev.latestReview!.feedback!,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Verification note
          if (ev.latestVerification?.verificationNote != null) ...[
            _fieldLabel('Ghi chú xác thực', subColor),
            const SizedBox(height: 4),
            Text(
              ev.latestVerification!.verificationNote!,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.4),
            ),
            const SizedBox(height: 10),
          ],

          // Date row
          Row(
            children: [
              if (ev.submittedAt != null)
                _buildDateChip('Nộp', ev.submittedAt!, subColor),
              if (ev.latestVerification?.verifiedAt != null) ...[
                const SizedBox(width: 8),
                _buildDateChip(
                    'Xác thực', ev.latestVerification!.verifiedAt!, subColor),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildUrlRow(String label, String url, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openUrl(url),
        child: Row(
          children: [
            Icon(Icons.link, size: 14, color: AppTheme.primaryBlue),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$label: $url',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date, Color color) {
    final formatted =
        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $formatted',
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
