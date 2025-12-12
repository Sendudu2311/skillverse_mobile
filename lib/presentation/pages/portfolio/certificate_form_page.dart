import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';

class CertificateFormPage extends StatefulWidget {
  const CertificateFormPage({super.key});

  @override
  State<CertificateFormPage> createState() => _CertificateFormPageState();
}

class _CertificateFormPageState extends State<CertificateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _issuerController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _credentialIdController = TextEditingController();
  final _credentialUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _credentialIdController.dispose();
    _credentialUrlController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = CreateCertificateRequest(
      title: _titleController.text.trim(),
      issuer: _issuerController.text.trim(),
      issueDate: _issueDateController.text.trim().isEmpty ? null : _issueDateController.text.trim(),
      expiryDate: _expiryDateController.text.trim().isEmpty ? null : _expiryDateController.text.trim(),
      credentialId: _credentialIdController.text.trim().isEmpty ? null : _credentialIdController.text.trim(),
      credentialUrl: _credentialUrlController.text.trim().isEmpty ? null : _credentialUrlController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    final portfolioProvider = context.read<PortfolioProvider>();
    final success = await portfolioProvider.createCertificate(request);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm chứng chỉ thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(portfolioProvider.errorMessage ?? 'Có lỗi xảy ra')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm chứng chỉ'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Lưu'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên chứng chỉ *',
                prefixIcon: Icon(Icons.card_membership),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Vui lòng nhập tên chứng chỉ' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _issuerController,
              decoration: const InputDecoration(
                labelText: 'Tổ chức cấp *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Vui lòng nhập tổ chức cấp' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _issueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày cấp',
                      hintText: '2024-01-01',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày hết hạn',
                      hintText: '2025-01-01',
                      prefixIcon: Icon(Icons.event),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _credentialIdController,
              decoration: const InputDecoration(
                labelText: 'Mã chứng chỉ',
                prefixIcon: Icon(Icons.confirmation_number),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _credentialUrlController,
              decoration: const InputDecoration(
                labelText: 'URL xác thực',
                hintText: 'https://example.com/verify',
                prefixIcon: Icon(Icons.verified),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL hình ảnh',
                hintText: 'https://example.com/cert.png',
                prefixIcon: Icon(Icons.image),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
