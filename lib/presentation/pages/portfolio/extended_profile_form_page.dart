import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../../data/models/portfolio_models.dart';

class ExtendedProfileFormPage extends StatefulWidget {
  final ExtendedProfileDto? profile;

  const ExtendedProfileFormPage({super.key, this.profile});

  @override
  State<ExtendedProfileFormPage> createState() => _ExtendedProfileFormPageState();
}

class _ExtendedProfileFormPageState extends State<ExtendedProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _slugController;
  late TextEditingController _bioController;
  late TextEditingController _headlineController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _twitterController;
  late TextEditingController _expertiseController;

  List<String> _expertiseAreas = [];
  bool _isPublic = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _slugController = TextEditingController(text: profile?.slug);
    _bioController = TextEditingController(text: profile?.bio);
    _headlineController = TextEditingController(text: profile?.headline);
    _locationController = TextEditingController(text: profile?.location);
    _websiteController = TextEditingController(text: profile?.website);
    _githubController = TextEditingController(text: profile?.githubUrl);
    _linkedinController = TextEditingController(text: profile?.linkedinUrl);
    _twitterController = TextEditingController(text: profile?.twitterUrl);
    _expertiseController = TextEditingController();
    _expertiseAreas = profile?.expertiseAreas ?? [];
    _isPublic = profile?.isPublic ?? true;
  }

  @override
  void dispose() {
    _slugController.dispose();
    _bioController.dispose();
    _headlineController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = CreateExtendedProfileRequest(
      slug: _slugController.text.trim().isEmpty ? null : _slugController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      headline: _headlineController.text.trim().isEmpty ? null : _headlineController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      githubUrl: _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
      linkedinUrl: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
      twitterUrl: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
      expertiseAreas: _expertiseAreas.isEmpty ? null : _expertiseAreas,
      isPublic: _isPublic,
    );

    final portfolioProvider = context.read<PortfolioProvider>();
    final bool success;

    if (widget.profile == null) {
      success = await portfolioProvider.createExtendedProfile(request);
    } else {
      success = await portfolioProvider.updateExtendedProfile(request);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.profile == null ? 'Tạo profile thành công!' : 'Cập nhật profile thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(portfolioProvider.errorMessage ?? 'Có lỗi xảy ra')),
        );
      }
    }
  }

  void _addExpertise() {
    final text = _expertiseController.text.trim();
    if (text.isNotEmpty && !_expertiseAreas.contains(text)) {
      setState(() {
        _expertiseAreas.add(text);
        _expertiseController.clear();
      });
    }
  }

  void _removeExpertise(String area) {
    setState(() => _expertiseAreas.remove(area));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Tạo Portfolio' : 'Chỉnh sửa Portfolio'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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
            // Slug
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug (URL tùy chỉnh)',
                hintText: 'vd: nguyen-van-a',
                prefixIcon: Icon(Icons.link),
                helperText: 'URL công khai cho portfolio của bạn',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                    return 'Chỉ chữ thường, số và dấu gạch ngang';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Headline
            TextFormField(
              controller: _headlineController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'vd: Full-stack Developer | AI Enthusiast',
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Giới thiệu',
                hintText: 'Viết vài dòng giới thiệu về bản thân...',
                prefixIcon: Icon(Icons.person),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                hintText: 'vd: Hà Nội, Việt Nam',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 24),

            // Social Links Section
            const Text(
              'Liên kết mạng xã hội',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _githubController,
              decoration: const InputDecoration(
                labelText: 'GitHub',
                hintText: 'https://github.com/username',
                prefixIcon: Icon(Icons.code),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _linkedinController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn',
                hintText: 'https://linkedin.com/in/username',
                prefixIcon: Icon(Icons.business),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _twitterController,
              decoration: const InputDecoration(
                labelText: 'Twitter/X',
                hintText: 'https://twitter.com/username',
                prefixIcon: Icon(Icons.chat),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Expertise Areas
            const Text(
              'Lĩnh vực chuyên môn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expertiseController,
                    decoration: const InputDecoration(
                      hintText: 'vd: Flutter, React, Python',
                      prefixIcon: Icon(Icons.work),
                    ),
                    onFieldSubmitted: (_) => _addExpertise(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addExpertise,
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_expertiseAreas.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _expertiseAreas
                    .map((area) => Chip(
                          label: Text(area),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeExpertise(area),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 24),

            // Public/Private Toggle
            SwitchListTile(
              title: const Text('Portfolio công khai'),
              subtitle: const Text('Cho phép mọi người xem portfolio của bạn'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
