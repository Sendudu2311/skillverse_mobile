import 'package:flutter/material.dart';
import '../../widgets/skillverse_app_bar.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SkillVerseAppBar(title: 'Điều Khoản Dịch Vụ'),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '1. Chấp Nhận Điều Khoản',
                'Bằng việc truy cập và sử dụng SkillVerse, bạn đồng ý tuân thủ các điều khoản và điều kiện được nêu trong tài liệu này.',
              ),
              _buildSection(
                '2. Mô Tả Dịch Vụ',
                'SkillVerse là nền tảng học tập trực tuyến cung cấp các khóa học, tài liệu và công cụ hỗ trợ phát triển kỹ năng lập trình và công nghệ.',
              ),
              _buildSection(
                '3. Tài Khoản Người Dùng',
                'Để sử dụng một số tính năng, bạn cần tạo tài khoản. Bạn chịu trách nhiệm bảo mật thông tin đăng nhập và tất cả hoạt động diễn ra dưới tài khoản của bạn.',
              ),
              _buildSection(
                '4. Quyền Sở Hữu Trí Tuệ',
                'Tất cả nội dung trên SkillVerse, bao gồm văn bản, hình ảnh, video và mã nguồn, đều thuộc sở hữu trí tuệ của chúng tôi hoặc được cấp phép sử dụng.',
              ),
              _buildSection(
                '5. Quy Tắc Sử Dụng',
                'Bạn đồng ý không sử dụng dịch vụ cho các mục đích bất hợp pháp, phân biệt đối xử, hoặc vi phạm quyền của người khác.',
              ),
              _buildSection(
                '6. Thanh Toán và Hoàn Tiền',
                'Các gói premium có thể yêu cầu thanh toán. Chính sách hoàn tiền áp dụng theo từng trường hợp cụ thể.',
              ),
              _buildSection(
                '7. Chấm Dứt Dịch Vụ',
                'Chúng tôi có quyền tạm ngừng hoặc chấm dứt tài khoản của bạn nếu vi phạm điều khoản này.',
              ),
              _buildSection(
                '8. Thay Đổi Điều Khoản',
                'Chúng tôi có quyền sửa đổi điều khoản này bất cứ lúc nào. Việc tiếp tục sử dụng dịch vụ sau khi có thay đổi đồng nghĩa với việc chấp nhận điều khoản mới.',
              ),
              _buildSection(
                '9. Liên Hệ',
                'Nếu bạn có câu hỏi về điều khoản này, vui lòng liên hệ với chúng tôi qua email: support@skillverse.com',
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Cập nhật lần cuối: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}