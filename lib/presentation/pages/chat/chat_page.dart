import 'package:flutter/material.dart';

/// ChatPage now contains the integrated Meowl chat UI (quick prompts, roadmap, prompts categories)
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Xin chào! Tôi là Meowl, trợ lý AI của SkillVerse. Tôi có thể giúp bạn tìm khóa học, trả lời câu hỏi về lập trình, hoặc hỗ trợ học tập. Bạn cần giúp gì hôm nay? 🐱',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.add(ChatMessage(
          text: _getAIResponse(message),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    });
  }

  String _getAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('flutter') || message.contains('mobile')) {
      return 'Flutter là framework tuyệt vời để phát triển ứng dụng di động! Khóa học "Mobile App Development với Flutter" sẽ giúp bạn xây dựng ứng dụng cross-platform chuyên nghiệp. 📱';
    } else if (message.contains('javascript') || message.contains('js') || message.contains('web')) {
      return 'JavaScript là ngôn ngữ không thể thiếu trong web development! Tôi khuyên bạn nên bắt đầu với khóa "Full Stack Web Development" để nắm vững cả frontend và backend. 🌐';
    } else if (message.contains('python') || message.contains('ai') || message.contains('machine learning')) {
      return 'Python là ngôn ngữ tuyệt vời cho AI và Data Science! Khóa học "Python for Data Science & AI" sẽ đưa bạn từ cơ bản đến ứng dụng thực tế. 🐍';
    } else if (message.contains('react') || message.contains('frontend')) {
      return 'React.js là thư viện phổ biến nhất để xây dựng giao diện người dùng! Khóa học "Full Stack Web Development với React & Node.js" sẽ giúp bạn nắm vững từ cơ bản đến nâng cao. 💻';
    } else if (message.contains('cảm ơn') || message.contains('thank')) {
      return 'Không có gì! Tôi luôn sẵn sàng hỗ trợ bạn trong hành trình học tập. Chúc bạn học tập hiệu quả! 😊';
    } else if (message.contains('giá') || message.contains('price') || message.contains('cost')) {
      return 'Các khóa học trên SkillVerse có mức giá từ 1,499,000 VNĐ đến 3,499,000 VNĐ tùy theo độ phức tạp và thời lượng. Chúng tôi cũng thường có các chương trình ưu đãi cho học viên mới! 💰';
    } else {
      return 'Tôi hiểu bạn đang tìm hiểu về "$userMessage". Hãy cho tôi biết cụ thể hơn bạn muốn học gì, tôi sẽ tư vấn khóa học phù hợp nhất! Hoặc bạn có thể xem danh sách khóa học trong tab "Khóa học" nhé! 🎯';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
              children: [
                // Avatar: prefer asset if available
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/meowl/avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Text('🐱', style: TextStyle(fontSize: 20))),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meowl Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('AI Assistant', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Messages List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),

        // Quick prompts row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _QuickChip(label: 'Roadmap JS', onTap: () => _showRoadmap('javascript')),
              const SizedBox(width: 8),
              _QuickChip(label: 'Roadmap Python', onTap: () => _showRoadmap('python')),
              const SizedBox(width: 8),
              _QuickChip(label: 'Xu hướng 2025', onTap: () => _sendQuick('Xu hướng công nghệ 2025')),
            ]),
          ),
        ),

          // Prompt categories (expandable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: promptCategories.entries.map((entry) {
                final title = entry.key;
                final cat = entry.value;
                return ExpansionTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (cat['prompts'] as List<String>).map((p) => ActionChip(label: Text(p), onPressed: () => _handlePrompt(p))).toList(),
                      ),
                    )
                  ],
                );
              }).toList(),
            ),
          ),

        // Input Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: _sendMessage,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendQuick(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });

    // simulate response
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _messages.add(ChatMessage(text: 'Gợi ý cho: $text', isUser: false, timestamp: DateTime.now()));
      });
    });
  }

  final Map<String, Map<String, dynamic>> roadmapTemplates = {
    'javascript': {
      'title': 'JavaScript Developer Roadmap',
      'duration': '3-6 months',
      'steps': [
        {'title': 'HTML & CSS Basics', 'duration': '2 weeks'},
        {'title': 'JavaScript Fundamentals', 'duration': '1 month'},
        {'title': 'Frontend Framework (React)', 'duration': '1 month'},
        {'title': 'Build Projects', 'duration': '4 weeks'},
      ],
    },
    'python': {
      'title': 'Python Developer Roadmap',
      'duration': '3-6 months',
      'steps': [
        {'title': 'Python Basics', 'duration': '3 weeks'},
        {'title': 'OOP & Modules', 'duration': '2 weeks'},
        {'title': 'Data Libraries (pandas, numpy)', 'duration': '1 month'},
        {'title': 'Projects / ML Intro', 'duration': '4 weeks'},
      ],
    },
  };

  void _showRoadmap(String key) {
    final data = roadmapTemplates[key]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title']),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thời lượng: ${data['duration']}'),
              const SizedBox(height: 8),
              ...((data['steps'] as List).map((s) => ListTile(title: Text(s['title']), subtitle: Text(s['duration']))).toList()),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng'))],
      ),
    );
  }

  final Map<String, Map<String, dynamic>> promptCategories = {
    'Lộ Trình Học Tập': {
      'color': 'blue',
      'prompts': [
        'Tạo lộ trình học JavaScript',
        'Lộ trình học Python từ cơ bản',
        'Roadmap học React.js',
        'Lộ trình trở thành Full-stack Developer',
        'Kế hoạch học AI/Machine Learning'
      ]
    },
    'Phát Triển Kỹ Năng': {
      'color': 'green',
      'prompts': [
        'Nên học ngôn ngữ lập trình nào?',
        'Cân bằng kỹ năng cứng và mềm?',
        'Lộ trình học cloud computing?',
        'Học UI/UX design từ đâu?',
        'Kỹ năng thiết yếu cho data scientist?'
      ]
    },
    'Tư Vấn Nghề Nghiệp': {
      'color': 'purple',
      'prompts': [
        'Xu hướng nghề nghiệp công nghệ 2024?',
        'Mẹo xây dựng portfolio mạnh',
        'CV developer nên có gì?',
        'Thương lượng lương trong công nghệ?',
        'Ứng tuyển việc làm từ xa hiệu quả?'
      ]
    },
    'Thông Tin Thị Trường': {
      'color': 'orange',
      'prompts': [
        'Cơ hội việc làm phù hợp với tôi',
        'Tương lai của AI và machine learning?',
        'Ngành công nghiệp đang phát triển?',
        'Tác động blockchain đến việc làm?',
        'Vai trò mới trong cybersecurity?'
      ]
    }
  };

  void _handlePrompt(String prompt) {
    // Recognize roadmap prompts
    final lower = prompt.toLowerCase();
    if (lower.contains('javascript') || lower.contains('js')) {
      _showRoadmap('javascript');
      return;
    }
    if (lower.contains('python')) {
      _showRoadmap('python');
      return;
    }

    // Otherwise send as user message
    _sendFromText(prompt);
  }

  void _sendFromText(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });
    // simulate response
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _messages.add(ChatMessage(text: 'Meowl trả lời về: $text', isUser: false, timestamp: DateTime.now()));
      });
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🐱', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}