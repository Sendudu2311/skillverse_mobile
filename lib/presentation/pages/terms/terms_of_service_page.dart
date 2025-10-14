import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều Khoản Sử Dụng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shield,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Điều Khoản Sử Dụng',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật lần cuối: 18/06/2025',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content Sections
            _buildSection(
              '1. Giới thiệu',
              'Chào mừng bạn đến với Skillverse – nền tảng học tập kỹ năng cá nhân và nghề nghiệp thông qua AI, chuyên gia và các khoá học tùy chỉnh. Bằng việc truy cập hoặc sử dụng dịch vụ của chúng tôi, bạn đồng ý với các điều khoản dưới đây.',
            ),

            _buildSectionWithCards(
              '2. Dịch vụ cung cấp',
              [
                _ServiceCard(
                  icon: Icons.book,
                  title: '2.1. Học tập kỹ năng',
                  items: [
                    'Các khóa học về kỹ năng mềm, kỹ năng chuyên môn',
                    'Tư duy logic, sáng tạo, quản lý thời gian',
                    'Tùy chỉnh lộ trình học dựa trên bài kiểm tra đầu vào',
                  ],
                ),
                _ServiceCard(
                  icon: Icons.psychology,
                  title: '2.2. AI phản hồi và đánh giá',
                  description: 'Phân tích bài làm, bài viết, tương tác để đưa ra phản hồi tự động về tiến độ và đề xuất học tập.',
                ),
                _ServiceCard(
                  icon: Icons.people,
                  title: '2.3. Kết nối với chuyên gia',
                  description: 'Người dùng có thể đặt lịch tư vấn 1-1 hoặc tham gia hội thảo do chuyên gia giảng dạy.',
                ),
                _ServiceCard(
                  icon: Icons.credit_card,
                  title: '2.4. Cộng đồng người học',
                  description: 'Diễn đàn chia sẻ, thảo luận, hỏi – đáp giữa người học và giảng viên.',
                ),
              ],
            ),

            _buildSectionWithRequirements(
              '3. Tài khoản người dùng',
              [
                _RequirementItem(
                  title: '3.1. Điều kiện đăng ký',
                  items: [
                    'Người dùng cá nhân phải từ 13 tuổi trở lên',
                    'Người dùng dưới 18 tuổi phải có sự đồng ý từ phụ huynh/người giám hộ',
                  ],
                ),
                _RequirementItem(
                  title: '3.2. Trách nhiệm của bạn',
                  items: [
                    'Bảo mật thông tin đăng nhập',
                    'Không chia sẻ tài khoản cho người khác',
                    'Cập nhật thông tin chính xác, trung thực',
                  ],
                ),
              ],
            ),

            _buildSectionWithBehavior(
              '4. Hành vi người dùng được chấp nhận',
              accepted: [
                'Tôn trọng người khác khi tham gia cộng đồng',
                'Chỉ tải lên nội dung do chính bạn tạo ra hoặc được quyền sử dụng',
                'Sử dụng dịch vụ đúng mục đích học tập',
              ],
              prohibited: [
                'Sử dụng AI để gian lận hoặc lách luật kiểm tra',
                'Tạo tài khoản giả hoặc sử dụng danh tính giả mạo',
                'Tải lên hoặc chia sẻ nội dung phản cảm, vi phạm pháp luật',
              ],
            ),

            _buildSectionWithOwnership(
              '5. Nội dung và quyền sở hữu',
              [
                _OwnershipCard(
                  title: '5.1. Nội dung của Skillverse',
                  items: [
                    'Bao gồm video học, bài giảng, AI engine, giao diện người dùng',
                    'Thuộc bản quyền Skillverse hoặc đối tác cấp phép',
                  ],
                ),
                _OwnershipCard(
                  title: '5.2. Nội dung bạn tạo ra',
                  items: [
                    'Bạn giữ quyền sở hữu đối với nội dung do bạn tạo',
                    'Cấp quyền sử dụng cho Skillverse để cải thiện sản phẩm',
                  ],
                ),
              ],
            ),

            _buildSectionWithPayment(
              '6. Thanh toán và hoàn tiền',
              [
                _PaymentCard(
                  title: '6.1. Dịch vụ miễn phí',
                  description: 'Truy cập cơ bản, bài học thử, bài kiểm tra trình độ',
                ),
                _PaymentCard(
                  title: '6.2. Dịch vụ trả phí (Pro/Plus)',
                  items: [
                    'Khoá học nâng cao, AI feedback chi tiết, lịch học 1-1',
                    'Thanh toán qua thẻ tín dụng, Momo, ZaloPay, VNPay…',
                  ],
                ),
                _PaymentCard(
                  title: '6.3. Chính sách hoàn tiền',
                  items: [
                    'Hoàn tiền 100% trong vòng 7 ngày nếu chưa học quá 30% nội dung',
                    'Sau thời gian/giới hạn trên, không hoàn lại',
                  ],
                ),
              ],
            ),

            _buildSection(
              '7. Tạm ngưng hoặc chấm dứt dịch vụ',
              'Skillverse có quyền cảnh báo, khoá hoặc xoá vĩnh viễn tài khoản nếu người dùng:\n\n• Vi phạm các điều khoản nêu trên\n• Có hành vi gian lận hoặc gây tổn hại đến hệ thống hoặc người khác\n• Sử dụng dịch vụ sai mục đích',
            ),

            _buildSection(
              '8. Trách nhiệm pháp lý',
              'Skillverse KHÔNG chịu trách nhiệm nếu:\n\n• Dữ liệu bị mất do sự cố ngoài ý muốn\n• Nội dung do người dùng đăng tải gây tranh cãi\n• Áp dụng sai kiến thức dẫn đến thiệt hại',
            ),

            _buildSection(
              '9. Cập nhật điều khoản',
              'Skillverse có quyền thay đổi điều khoản vào bất cứ thời điểm nào. Chúng tôi sẽ thông báo qua email hoặc popup trong tài khoản.',
            ),

            _buildSection(
              '10. Luật áp dụng và giải quyết tranh chấp',
              'Mọi tranh chấp liên quan sẽ được xử lý theo pháp luật Việt Nam. Trong trường hợp hai bên không tự thoả thuận được, vụ việc sẽ được chuyển đến Toà án Nhân dân có thẩm quyền tại TP. Hồ Chí Minh.',
            ),

            _buildContactSection('11. Liên hệ'),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                '© 2025 Skillverse. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionWithCards(String title, List<_ServiceCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildServiceCard(card),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildServiceCard(_ServiceCard card) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(card.icon, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (card.description != null) ...[
              const SizedBox(height: 8),
              Text(
                card.description!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
            if (card.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...card.items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithRequirements(String title, List<_RequirementItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRequirementCard(item),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRequirementCard(_RequirementItem item) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...item.items.map((requirement) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      requirement,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithBehavior(String title, {required List<String> accepted, required List<String> prohibited}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Người dùng PHẢI:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...accepted.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 2,
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Người dùng KHÔNG ĐƯỢC:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...prohibited.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionWithOwnership(String title, List<_OwnershipCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildOwnershipCard(card),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOwnershipCard(_OwnershipCard card) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...card.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithPayment(String title, List<_PaymentCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPaymentCard(card),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaymentCard(_PaymentCard card) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (card.description != null) ...[
              const SizedBox(height: 8),
              Text(
                card.description!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
            if (card.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...card.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildContactCard(
                Icons.email,
                'Email',
                'support@skillverse.com',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildContactCard(
                Icons.phone,
                'Hotline',
                '(+84) XXX XXX XXX',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          Icons.location_on,
          'Trụ sở',
          'Quận 7, TP.HCM',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContactCard(IconData icon, String title, String detail) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard {
  final IconData icon;
  final String title;
  final String? description;
  final List<String> items;

  const _ServiceCard({
    required this.icon,
    required this.title,
    this.description,
    this.items = const [],
  });
}

class _RequirementItem {
  final String title;
  final List<String> items;

  const _RequirementItem({
    required this.title,
    required this.items,
  });
}

class _OwnershipCard {
  final String title;
  final List<String> items;

  const _OwnershipCard({
    required this.title,
    required this.items,
  });
}

class _PaymentCard {
  final String title;
  final String? description;
  final List<String> items;

  const _PaymentCard({
    required this.title,
    this.description,
    this.items = const [],
  });
}