import 'dart:async';
import 'package:flutter/material.dart';
import 'common_loading.dart';

class MeowlMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  MeowlMessage({required this.id, required this.role, required this.content, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();
}

class GuardResult {
  final bool allow;
  final String? reason;
  GuardResult(this.allow, {this.reason});
}

GuardResult guardUserInput(String input) {
  final lower = input.toLowerCase();
  // Very simple guard: block requests that ask to reveal system prompts or jailbreak patterns
  final blocked = ['ignore previous', 'show system', 'bypass', 'jailbreak'];
  for (final b in blocked) {
    if (lower.contains(b)) return GuardResult(false, reason: 'prompt_injection');
  }
  if (input.trim().isEmpty) return GuardResult(false, reason: 'empty');
  return GuardResult(true);
}

bool guardModelOutput(String output) {
  // Simple output guard: ensure length and not containing banned phrases
  if (output.trim().isEmpty) return false;
  final banned = ['api_key', 'secret', 'password'];
  for (final b in banned) {
    if (output.toLowerCase().contains(b)) return false;
  }
  return true;
}

String pickFallback(String kind, String locale) {
  if (locale == 'vi') {
    return kind == 'output' ? 'Xin lỗi, tôi không thể trả lời yêu cầu này.' : 'Yêu cầu không hợp lệ.';
  }
  return kind == 'output' ? 'Sorry, I cannot answer that.' : 'Invalid request.';
}

class MeowlChatWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String locale; // 'en' or 'vi'

  const MeowlChatWidget({super.key, required this.isOpen, required this.onClose, this.locale = 'vi'});

  @override
  State<MeowlChatWidget> createState() => _MeowlChatWidgetState();
}

class _MeowlChatWidgetState extends State<MeowlChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<MeowlMessage> _messages = [];
  bool _isLoading = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.isOpen && _messages.isEmpty) {
      _messages.add(MeowlMessage(id: 'welcome', role: 'assistant', content: widget.locale == 'vi' ? 'Xin chào! Tôi là Meowl, trợ lý học tập của bạn. Tôi có thể giúp gì?' : "Hi! I'm Meowl, your learning assistant."));
    }
  }

  @override
  void didUpdateWidget(covariant MeowlChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && _messages.isEmpty) {
      _messages.add(MeowlMessage(id: 'welcome', role: 'assistant', content: widget.locale == 'vi' ? 'Xin chào! Tôi là Meowl, trợ lý học tập của bạn. Tôi có thể giúp gì?' : "Hi! I'm Meowl, your learning assistant."));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final guard = guardUserInput(text);
    if (!guard.allow) {
      final fallback = pickFallback(guard.reason ?? 'input', widget.locale);
      setState(() {
        _messages.add(MeowlMessage(id: DateTime.now().toString(), role: 'user', content: text));
        _messages.add(MeowlMessage(id: '${DateTime.now().millisecondsSinceEpoch}-bot', role: 'assistant', content: fallback));
        _controller.clear();
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add(MeowlMessage(id: DateTime.now().toString(), role: 'user', content: text));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    // Simulate AI response with delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    String ai = _mockAiResponse(text);
    if (!guardModelOutput(ai)) ai = pickFallback('output', widget.locale);

    setState(() {
      _messages.add(MeowlMessage(id: '${DateTime.now().millisecondsSinceEpoch}-bot', role: 'assistant', content: ai));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  String _mockAiResponse(String input) {
    // Very simple canned answers based on keywords
    final lower = input.toLowerCase();
    if (lower.contains('khóa') || lower.contains('course')) {
      return widget.locale == 'vi' ? 'Bạn có thể tìm khóa học theo chủ đề hoặc kỹ năng. Tôi gợi ý bắt đầu với khóa cơ bản.' : 'You can search courses by topic or skill. I recommend starting with a beginner course.';
    }
    if (lower.contains('làm sao') || lower.contains('how')) {
      return widget.locale == 'vi' ? 'Bạn có thể bắt đầu bằng cách truy cập trang khóa học và chọn "Bắt đầu".' : 'You can start by visiting the course page and pressing "Start".';
    }
    return widget.locale == 'vi' ? 'Mình thấy bạn quan tâm. Bạn muốn mình gợi ý khóa học hay lộ trình học?' : 'I see. Would you like course suggestions or a learning path?';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {},
      child: Stack(
        children: [
          // dim background
          Positioned.fill(child: GestureDetector(onTap: widget.onClose, child: Container(color: Colors.black54))),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // header
                    Container(
                      color: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Text(widget.locale == 'vi' ? 'Meowl trợ lý' : 'Meowl Assistant', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, color: Colors.white))
                        ],
                      ),
                    ),

                    // messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _messages.length) return _buildLoadingBubble();
                          final m = _messages[index];
                          final isAssistant = m.role == 'assistant';
                          return Align(
                            alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 520),
                              decoration: BoxDecoration(
                                color: isAssistant
                                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                                    : Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(m.content, style: TextStyle(color: isAssistant ? Theme.of(context).colorScheme.onSurface : Colors.white)),
                            ),
                          );
                        },
                      ),
                    ),

                    // input
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(hintText: widget.locale == 'vi' ? 'Hỏi tôi về học tập...' : 'Ask me about learning...'),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _isLoading
                                ? Padding(padding: const EdgeInsets.all(8.0), child: CommonLoading.small())
                                : IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [CommonLoading.small()]),
        ),
      );
}
