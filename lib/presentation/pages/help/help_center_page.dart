import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String searchQuery = '';
  int? selectedCategory;

  final List<FAQCategory> faqCategories = [
    FAQCategory(
      title: 'Tài Khoản & Bảo Mật',
      icon: Icons.shield,
      faqs: [
        FAQItem(
          question: 'Làm thế nào để thay đổi mật khẩu?',
          answer: 'Để thay đổi mật khẩu, vào Cài đặt > Bảo mật > Đổi mật khẩu. Điền mật khẩu cũ và mật khẩu mới của bạn.'
        ),
        FAQItem(
          question: 'Tôi quên mật khẩu phải làm sao?',
          answer: 'Bạn có thể sử dụng tính năng "Quên mật khẩu" trên trang đăng nhập. Chúng tôi sẽ gửi email hướng dẫn đặt lại mật khẩu.'
        ),
      ],
    ),
    FAQCategory(
      title: 'Khóa Học & Học Tập',
      icon: Icons.book,
      faqs: [
        FAQItem(
          question: 'Làm sao để tìm khóa học phù hợp?',
          answer: 'Bạn có thể sử dụng công cụ tìm kiếm hoặc bộ lọc theo chủ đề, cấp độ và kỹ năng. AI của chúng tôi cũng sẽ đề xuất các khóa học phù hợp dựa trên sở thích và mục tiêu của bạn.'
        ),
        FAQItem(
          question: 'Tôi có thể học thử không?',
          answer: 'Có, mỗi khóa học đều có bài học thử miễn phí để bạn trải nghiệm trước khi quyết định đăng ký.'
        ),
      ],
    ),
    FAQCategory(
      title: 'Thanh Toán & Gói Dịch Vụ',
      icon: Icons.credit_card,
      faqs: [
        FAQItem(
          question: 'Các phương thức thanh toán được chấp nhận?',
          answer: 'Chúng tôi chấp nhận thanh toán qua thẻ tín dụng/ghi nợ, ví điện tử (Momo, ZaloPay), và chuyển khoản ngân hàng.'
        ),
        FAQItem(
          question: 'Chính sách hoàn tiền như thế nào?',
          answer: 'Bạn có thể yêu cầu hoàn tiền trong vòng 7 ngày kể từ ngày mua nếu chưa học quá 30% nội dung khóa học.'
        ),
      ],
    ),
    FAQCategory(
      title: 'Cộng Đồng & Hỗ Trợ',
      icon: Icons.people,
      faqs: [
        FAQItem(
          question: 'Làm sao để kết nối với học viên khác?',
          answer: 'Bạn có thể tham gia các nhóm học tập, diễn đàn thảo luận và các sự kiện trực tuyến của cộng đồng.'
        ),
        FAQItem(
          question: 'Có hỗ trợ kỹ thuật 24/7 không?',
          answer: 'Đội ngũ hỗ trợ của chúng tôi làm việc từ 8h-22h hàng ngày. Ngoài giờ làm việc, bạn có thể gửi ticket hỗ trợ.'
        ),
      ],
    ),
  ];

  List<FAQCategory> get filteredFAQs {
    if (searchQuery.isEmpty) return faqCategories;

    return faqCategories.map((category) {
      final filteredFaqs = category.faqs.where((faq) {
        final query = searchQuery.toLowerCase();
        return faq.question.toLowerCase().contains(query) ||
               faq.answer.toLowerCase().contains(query);
      }).toList();

      return FAQCategory(
        title: category.title,
        icon: category.icon,
        faqs: filteredFaqs,
      );
    }).where((category) => category.faqs.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung Tâm Hỗ Trợ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Trung Tâm Hỗ Trợ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúng tôi luôn sẵn sàng giúp đỡ bạn',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm câu hỏi...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: filteredFAQs.map((category) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCategoryCard(category),
                )).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Section
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey[50],
              child: Column(
                children: [
                  const Text(
                    'Vẫn cần hỗ trợ?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Liên hệ với chúng tôi qua các kênh sau:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildContactCard(
                        Icons.email,
                        'Email',
                        'support@skillverse.com',
                      ),
                      _buildContactCard(
                        Icons.phone,
                        'Hotline',
                        '1800 1234',
                      ),
                      _buildContactCard(
                        Icons.message,
                        'Live Chat',
                        '8:00 - 22:00',
                      ),
                      _buildContactCard(
                        Icons.location_on,
                        'Văn Phòng',
                        'Quận 1, TP.HCM',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(FAQCategory category) {
    final isExpanded = selectedCategory == faqCategories.indexOf(category);

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Category Header
          InkWell(
            onTap: () {
              setState(() {
                selectedCategory = isExpanded ? null : faqCategories.indexOf(category);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(category.icon, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // FAQ Items
          if (isExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.grey[50],
              child: Column(
                children: category.faqs.map((faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildFAQItem(faq),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          faq.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          faq.answer,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(IconData icon, String title, String detail) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FAQCategory {
  final String title;
  final IconData icon;
  final List<FAQItem> faqs;

  const FAQCategory({
    required this.title,
    required this.icon,
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