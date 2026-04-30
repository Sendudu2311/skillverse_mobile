import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../providers/post_provider.dart';
import '../../widgets/glass_card.dart';
import '../../../data/models/post_models.dart';
import '../../../core/utils/error_handler.dart';

import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';

class PostFormPage extends StatefulWidget {
  final int? postId; // null for create, id for edit

  const PostFormPage({super.key, this.postId});

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _quillController = quill.QuillController.basic();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _loadPost();
    }
  }

  Future<void> _loadPost() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<PostProvider>();
      final post = provider.posts.firstWhere(
        (p) => p.id == widget.postId,
        orElse: () => throw Exception('Bài viết không tồn tại'),
      );

      _titleController.text = post.title ?? '';
      _quillController.document = quill.Document()..insert(0, post.content);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        context.pop();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: widget.postId == null ? 'Tạo bài viết' : 'Chỉnh sửa bài viết',
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _saveDraft, child: const Text('Lưu nháp')),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? CommonLoading.center()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'Nhập tiêu đề bài viết...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLength: 200,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Rich text editor
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            // Toolbar
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: quill.QuillSimpleToolbar(
                                controller: _quillController,
                              ),
                            ),

                            // Editor
                            Container(
                              height: 400,
                              padding: const EdgeInsets.all(16),
                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Publish button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _publishPost,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppTheme.themeOrangeStart,
                        ),
                        child: _isLoading
                            ? CommonLoading.small()
                            : const Text(
                                'Đăng bài',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    await _savePost(isDraft: true);
  }

  Future<void> _publishPost() async {
    await _savePost(isDraft: false);
  }

  Future<void> _savePost({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) return;

    // Get plain text from quill document
    final content = _quillController.document.toPlainText().trim();
    if (content.isEmpty) {
      if (mounted) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Vui lòng nhập nội dung bài viết',
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<PostProvider>();
    final targetStatus = isDraft ? PostStatus.draft : PostStatus.published;

    try {
      if (widget.postId == null) {
        // Create new post
        final post = await provider.createPost(
          content,
          title: _titleController.text.trim(),
          status: targetStatus,
        );

        if (mounted) {
          if (post != null) {
            ErrorHandler.showSuccessSnackBar(
              context,
              isDraft
                  ? 'Đã lưu nháp thành công'
                  : 'Đã đăng bài viết thành công',
            );
            context.pop();
          } else {
            // provider.executeAsync caught the error → show from provider.errorMessage
            ErrorHandler.showErrorSnackBar(
              context,
              provider.errorMessage ?? 'Tạo bài viết thất bại',
            );
          }
        }
      } else {
        // Update existing post
        final updated = await provider.updatePost(
          widget.postId!,
          title: _titleController.text.trim(),
          content: content,
          status: targetStatus,
        );

        if (mounted) {
          if (updated != null) {
            ErrorHandler.showSuccessSnackBar(context, 'Đã cập nhật bài viết');
            context.pop();
          } else {
            ErrorHandler.showErrorSnackBar(
              context,
              provider.errorMessage ?? 'Cập nhật bài viết thất bại',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
