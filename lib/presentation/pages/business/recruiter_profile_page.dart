import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../data/services/user_service.dart';
import '../../../data/models/recruiter_profile_models.dart';

/// Recruiter Public Profile Page — Read-only view for learners.
/// Shows company logo, name, verified badge, info grid, status, and contact.
class RecruiterProfilePage extends StatefulWidget {
  final int recruiterId;

  const RecruiterProfilePage({super.key, required this.recruiterId});

  @override
  State<RecruiterProfilePage> createState() => _RecruiterProfilePageState();
}

class _RecruiterProfilePageState extends State<RecruiterProfilePage> {
  final UserService _userService = UserService();
  RecruiterProfileResponse? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _userService.getRecruiterProfile(
        widget.recruiterId,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải hồ sơ nhà tuyển dụng.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundPrimary
          : AppTheme.lightBackgroundPrimary,
      appBar: AppBar(
        title: const Text('Hồ sơ doanh nghiệp'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(top: false, bottom: true, child: _buildBody(isDark)),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _profile == null) {
      return _buildErrorState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(isDark),
            const SizedBox(height: 16),
            _buildCompanyInfoGrid(isDark),
            const SizedBox(height: 16),
            _buildVerificationStatus(isDark),
            const SizedBox(height: 16),
            _buildContactSection(isDark),
            if (_profile!.companyWebsite != null &&
                _profile!.companyWebsite!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWebsiteCTA(isDark),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ──────────────── Error state ────────────────
  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy hồ sơ công ty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Có thể doanh nghiệp chưa hoàn thành hồ sơ.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────── Hero Section ────────────────
  Widget _buildHeroSection(bool isDark) {
    final profile = _profile!;
    final companyName = profile.companyName ?? 'Doanh nghiệp';
    final logoUrl = profile.companyLogoUrl;
    final isVerified = profile.isVerified;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company logo / fallback
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF0F4F8),
              border: Border.all(
                color: isDark
                    ? const Color(0x30FFFFFF)
                    : const Color(0x20000000),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildLogoFallback(companyName, isDark),
                    )
                  : _buildLogoFallback(companyName, isDark),
            ),
          ),
          const SizedBox(width: 14),
          // Company name + verified badge + joined date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        size: 18,
                        color: Color(0xFF22C55E),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.companyIdDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontFamily: 'monospace',
                  ),
                ),
                if (profile.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tham gia ${_formatDate(profile.createdAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoFallback(String companyName, bool isDark) {
    final initials = companyName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Center(
      child: Text(
        initials.isEmpty ? 'DN' : initials,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF6366F1),
        ),
      ),
    );
  }

  // ──────────────── Company Info Grid ────────────────
  Widget _buildCompanyInfoGrid(bool isDark) {
    final profile = _profile!;

    final infoItems = <_InfoItem>[
      _InfoItem(
        icon: Icons.business,
        label: 'Tên doanh nghiệp',
        value: profile.companyName ?? 'Chưa cập nhật',
      ),
      _InfoItem(
        icon: Icons.shield_outlined,
        label: 'Mã số thuế / ĐKKD',
        value: profile.taxCodeOrBusinessRegistrationNumber ?? 'Chưa cập nhật',
        isMono: true,
      ),
      _InfoItem(
        icon: Icons.location_on_outlined,
        label: 'Địa chỉ',
        value: profile.companyAddress ?? 'Chưa cập nhật',
      ),
      _InfoItem(
        icon: Icons.email_outlined,
        label: 'Email liên hệ',
        value: profile.email ?? 'Chưa cập nhật',
        isMono: true,
      ),
    ];

    // Add optional fields only if present
    if (profile.industry != null && profile.industry!.isNotEmpty) {
      infoItems.add(
        _InfoItem(
          icon: Icons.category_outlined,
          label: 'Ngành nghề',
          value: profile.industry!,
        ),
      );
    }
    if (profile.companySize != null && profile.companySize!.isNotEmpty) {
      infoItems.add(
        _InfoItem(
          icon: Icons.groups_outlined,
          label: 'Quy mô',
          value: profile.companySize!,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Thông tin doanh nghiệp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        ...infoItems.map((item) => _buildInfoCard(item, isDark)),
      ],
    );
  }

  Widget _buildInfoCard(_InfoItem item, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 18,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black45,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: item.isMono ? 'monospace' : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────── Verification Status ────────────────
  Widget _buildVerificationStatus(bool isDark) {
    final profile = _profile!;
    final status = profile.applicationStatus ?? 'PENDING';

    late Color statusColor;
    late IconData statusIcon;
    late String statusLabel;
    late String statusDescription;

    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle;
        statusLabel = 'Đã xác minh';
        statusDescription = 'Hồ sơ doanh nghiệp đã được xác minh thành công.';
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error;
        statusLabel = 'Bị từ chối';
        statusDescription = 'Hồ sơ cần cập nhật lại theo yêu cầu kiểm duyệt.';
        break;
      case 'UNDER_REVIEW':
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.policy;
        statusLabel = 'Đang thẩm định';
        statusDescription = 'Thông tin đang được rà soát bởi đội vận hành.';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule;
        statusLabel = 'Đang chờ xác minh';
        statusDescription = 'Hồ sơ đã gửi và đang chờ bộ phận kiểm duyệt.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Trạng thái hồ sơ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                statusDescription,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              if (status == 'REJECTED' &&
                  profile.rejectionReason != null &&
                  profile.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    profile.rejectionReason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
              if (profile.approvalDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Cập nhật: ${_formatDate(profile.approvalDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────── Contact Section ────────────────
  Widget _buildContactSection(bool isDark) {
    final profile = _profile!;
    final hasContact =
        (profile.contactPersonPosition != null &&
            profile.contactPersonPosition!.isNotEmpty) ||
        (profile.contactPersonPhone != null &&
            profile.contactPersonPhone!.isNotEmpty) ||
        (profile.companyPhone != null && profile.companyPhone!.isNotEmpty);

    if (!hasContact && (profile.email == null || profile.email!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Đầu mối liên hệ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              if (profile.contactPersonPosition != null &&
                  profile.contactPersonPosition!.isNotEmpty)
                _buildContactRow(
                  Icons.person_outline,
                  profile.contactPersonPosition!,
                  isDark,
                ),
              if (profile.email != null && profile.email!.isNotEmpty)
                _buildContactRow(Icons.email_outlined, profile.email!, isDark),
              if (profile.companyPhone != null &&
                  profile.companyPhone!.isNotEmpty)
                _buildContactRow(
                  Icons.phone_outlined,
                  profile.companyPhone!,
                  isDark,
                ),
              if (profile.contactPersonPhone != null &&
                  profile.contactPersonPhone!.isNotEmpty &&
                  profile.contactPersonPhone != profile.companyPhone)
                _buildContactRow(
                  Icons.phone_android,
                  profile.contactPersonPhone!,
                  isDark,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────── Website CTA ────────────────
  Widget _buildWebsiteCTA(bool isDark) {
    final rawUrl = _profile!.companyWebsite!;
    final normalizedUrl = rawUrl.startsWith('http')
        ? rawUrl
        : 'https://$rawUrl';
    final displayLabel = normalizedUrl.replaceFirst(RegExp(r'^https?://'), '');

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(normalizedUrl);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.public, size: 18),
        label: Text(displayLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: isDark ? const Color(0x40FFFFFF) : const Color(0x30000000),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ──────────────── Helpers ────────────────
  String _formatDate(String dateString) {
    try {
      final dt = DateTime.parse(dateString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return 'Chưa cập nhật';
    }
  }
}

/// Simple data class for info card items
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isMono;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMono = false,
  });
}
