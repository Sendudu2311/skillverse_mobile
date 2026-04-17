import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/booking_dispute_models.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_dispute_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';

/// Bottom sheet for submitting new evidence to an open dispute.
/// Must be wrapped with a [BookingDisputeProvider] in the widget tree.
class SubmitEvidenceSheet extends StatefulWidget {
  const SubmitEvidenceSheet({super.key});

  @override
  State<SubmitEvidenceSheet> createState() => _SubmitEvidenceSheetState();
}

class _SubmitEvidenceSheetState extends State<SubmitEvidenceSheet> {
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  EvidenceType _selectedType = EvidenceType.text;
  String? _pickedImagePath;
  String? _pickedImageName;

  @override
  void dispose() {
    _contentController.dispose();
    _linkController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedImagePath = result.files.single.path;
        _pickedImageName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedType == EvidenceType.image && _pickedImagePath == null) {
      ErrorHandler.showErrorSnackBar(context, 'Vui lòng chọn ảnh để gửi.');
      return;
    }

    final provider = context.read<BookingDisputeProvider>();

    String? imageUrl;
    if (_selectedType == EvidenceType.image) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) {
        ErrorHandler.showErrorSnackBar(context, 'Không xác định được người dùng.');
        return;
      }
      try {
        imageUrl = await provider.uploadEvidenceFile(
          _pickedImagePath!,
          _pickedImageName!,
          actorId: userId,
        );
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
        }
        return;
      }
    }

    try {
      await provider.submitEvidence(
        type: _selectedType,
        content: _selectedType == EvidenceType.text
            ? _contentController.text.trim()
            : null,
        fileUrl: _selectedType == EvidenceType.link
            ? _linkController.text.trim()
            : _selectedType == EvidenceType.image
                ? imageUrl
                : null,
        fileName: _selectedType == EvidenceType.image ? _pickedImageName : null,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ErrorHandler.showSuccessSnackBar(
          context,
          'Đã gửi bằng chứng thành công.',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : AppTheme.lightBackgroundSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    color: AppTheme.primaryBlueDark,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Gửi bằng chứng',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Evidence type selector
              Text(
                'Loại bằng chứng',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EvidenceType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: EvidenceType.text,
                    child: Text('Văn bản'),
                  ),
                  DropdownMenuItem(
                    value: EvidenceType.link,
                    child: Text('Liên kết'),
                  ),
                  DropdownMenuItem(
                    value: EvidenceType.image,
                    child: Text('Hình ảnh'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedType = v;
                      _pickedImagePath = null;
                      _pickedImageName = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Content / Link / Image field
              if (_selectedType == EvidenceType.text)
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung *',
                    hintText: 'Mô tả bằng chứng của bạn...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập nội dung bằng chứng.';
                    }
                    return null;
                  },
                )
              else if (_selectedType == EvidenceType.link)
                TextFormField(
                  controller: _linkController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Đường dẫn *',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập đường dẫn.';
                    }
                    return null;
                  },
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Chọn ảnh'),
                ),
                if (_pickedImageName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _pickedImageName!,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 14),

              // Optional description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  hintText: 'Ghi chú thêm về bằng chứng này...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              Consumer<BookingDisputeProvider>(
                builder: (ctx, provider, child) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isBusy ? null : _submit,
                    icon: provider.isBusy
                        ? CommonLoading.button()
                        : const Icon(Icons.send),
                    label: Text(
                      provider.isBusy ? 'Đang gửi...' : 'Gửi bằng chứng',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlueDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
