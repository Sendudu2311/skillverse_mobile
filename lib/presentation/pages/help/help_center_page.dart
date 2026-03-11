import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_theme.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String searchQuery = '';
  int? selectedCategory;
  int? selectedFAQ;

  final List<FAQCategory> faqCategories = [
    FAQCategory(
      title: 'Tài Khoản & Bảo Mật',
      icon: Icons.shield_outlined,
      color: AppTheme.primaryBlueDark,
      faqs: [
        FAQItem(
          question: 'Làm thế nào để thay đổi mật khẩu?',
          answer:
              'Để thay đổi mật khẩu, vào Cài đặt > Bảo mật > Đổi mật khẩu. Điền mật khẩu cũ và mật khẩu mới của bạn.',
        ),
        FAQItem(
          question: 'Tôi quên mật khẩu phải làm sao?',
          answer:
              'Bạn có thể sử dụng tính năng "Quên mật khẩu" trên trang đăng nhập. Chúng tôi sẽ gửi email hướng dẫn đặt lại mật khẩu.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Khóa Học & Học Tập',
      icon: Icons.menu_book_outlined,
      color: AppTheme.accentCyan,
      faqs: [
        FAQItem(
          question: 'Làm sao để tìm khóa học phù hợp?',
          answer:
              'Bạn có thể sử dụng công cụ tìm kiếm hoặc bộ lọc theo chủ đề, cấp độ và kỹ năng. AI của chúng tôi cũng sẽ đề xuất các khóa học phù hợp dựa trên sở thích và mục tiêu của bạn.',
        ),
        FAQItem(
          question: 'Tôi có thể học thử không?',
          answer:
              'Có, mỗi khóa học đều có bài học thử miễn phí để bạn trải nghiệm trước khi quyết định đăng ký.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Thanh Toán & Gói Dịch Vụ',
      icon: Icons.account_balance_wallet_outlined,
      color: AppTheme.themeGreenStart,
      faqs: [
        FAQItem(
          question: 'Các phương thức thanh toán được chấp nhận?',
          answer:
              'Chúng tôi chấp nhận thanh toán qua thẻ tín dụng/ghi nợ, ví điện tử (Momo, ZaloPay), và chuyển khoản ngân hàng.',
        ),
        FAQItem(
          question: 'Chính sách hoàn tiền như thế nào?',
          answer:
              'Bạn có thể yêu cầu hoàn tiền trong vòng 7 ngày kể từ ngày mua nếu chưa học quá 30% nội dung khóa học.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Cộng Đồng & Hỗ Trợ',
      icon: Icons.groups_outlined,
      color: AppTheme.themeOrangeStart,
      faqs: [
        FAQItem(
          question: 'Làm sao để kết nối với học viên khác?',
          answer:
              'Bạn có thể tham gia các nhóm học tập, diễn đàn thảo luận và các sự kiện trực tuyến của cộng đồng.',
        ),
        FAQItem(
          question: 'Có hỗ trợ kỹ thuật 24/7 không?',
          answer:
              'Đội ngũ hỗ trợ của chúng tôi làm việc từ 8h-22h hàng ngày. Ngoài giờ làm việc, bạn có thể gửi ticket hỗ trợ.',
        ),
      ],
    ),
  ];

  List<FAQCategory> get filteredFAQs {
    if (searchQuery.isEmpty) return faqCategories;

    return faqCategories
        .map((category) {
          final filteredFaqs = category.faqs.where((faq) {
            final query = searchQuery.toLowerCase();
            return faq.question.toLowerCase().contains(query) ||
                faq.answer.toLowerCase().contains(query);
          }).toList();

          return FAQCategory(
            title: category.title,
            icon: category.icon,
            color: category.color,
            faqs: filteredFaqs,
          );
        })
        .where((category) => category.faqs.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundPrimary : AppTheme.lightBackgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with gradient header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark
                ? AppTheme.darkBackgroundPrimary
                : AppTheme.lightBackgroundPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/profile'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlueDark,
                      AppTheme.accentCyan,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TRUNG TÂM HỖ TRỢ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Chúng tôi luôn sẵn sàng giúp đỡ bạn',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Search Bar
                        TextField(
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm câu hỏi...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkCardBackground
                                : Colors.white,
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // FAQ Categories
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final categories = filteredFAQs;
                  if (index >= categories.length) return null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCategoryCard(categories[index], isDark),
                  );
                },
                childCount: filteredFAQs.length,
              ),
            ),
          ),

          // Contact Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBorderColor
                          : AppTheme.lightBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Vẫn cần hỗ trợ?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Liên hệ với chúng tôi qua các kênh sau:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contact Cards Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
                _buildContactCard(
                  Icons.email_outlined,
                  'Email',
                  'support@skillverse.vn',
                  AppTheme.primaryBlueDark,
                  isDark,
                ),
                _buildContactCard(
                  Icons.phone_outlined,
                  'Hotline',
                  '1800 1234',
                  AppTheme.themeGreenStart,
                  isDark,
                ),
                _buildContactCard(
                  Icons.chat_outlined,
                  'Live Chat',
                  '8:00 - 22:00',
                  AppTheme.accentCyan,
                  isDark,
                ),
                _buildContactCard(
                  Icons.location_on_outlined,
                  'Văn Phòng',
                  'Quận 1, TP.HCM',
                  AppTheme.themeOrangeStart,
                  isDark,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(FAQCategory category, bool isDark) {
    final categoryIndex = faqCategories.indexOf(category);
    final isExpanded = selectedCategory == categoryIndex;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? category.color.withValues(alpha: 0.5)
              : (isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Category Header
          InkWell(
            onTap: () {
              setState(() {
                selectedCategory = isExpanded ? null : categoryIndex;
                selectedFAQ = null;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? category.color.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isExpanded
                          ? category.color
                          : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FAQ Items (animated)
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Divider(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : AppTheme.lightBorderColor,
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  ...category.faqs.asMap().entries.map((entry) {
                    final faqIndex = entry.key;
                    final faq = entry.value;
                    final isFAQExpanded = selectedFAQ == faqIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildFAQItem(
                        faq,
                        category.color,
                        isFAQExpanded,
                        () => setState(() {
                          selectedFAQ = isFAQExpanded ? null : faqIndex;
                        }),
                        isDark,
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
    FAQItem faq,
    Color accentColor,
    bool isExpanded,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded
              ? accentColor.withValues(alpha: 0.08)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(10),
          border: isExpanded
              ? Border.all(color: accentColor.withValues(alpha: 0.2))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.help
                      : Icons.help_outline,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    faq.question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.remove : Icons.add,
                  size: 18,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  faq.answer,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    IconData icon,
    String title,
    String detail,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FAQCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<FAQItem> faqs;

  const FAQCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.faqs,
  });
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({
    required this.question,
    required this.answer,
  });
}