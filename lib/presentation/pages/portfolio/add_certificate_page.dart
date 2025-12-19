import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../core/utils/error_handler.dart';

class AddCertificatePage extends StatefulWidget {
  const AddCertificatePage({super.key});

  @override
  State<AddCertificatePage> createState() => _AddCertificatePageState();
}

class _AddCertificatePageState extends State<AddCertificatePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _titleController = TextEditingController();
  final _issuerController = TextEditingController();
  final _credentialIdController = TextEditingController();
  final _credentialUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _issuerController.dispose();
    _credentialIdController.dispose();
    _credentialUrlController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isIssueDate ? _issueDate : _expiryDate) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.themeOrangeStart,
              surface: AppTheme.darkCardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _saveCertificate() async {
    if (!_formKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Vui lòng kiểm tra lại thông tin đã nhập',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateCertificateRequest(
        title: _titleController.text.trim(),
        issuer: _issuerController.text.trim(),
        issueDate: _issueDate != null ? _dateFormat.format(_issueDate!) : null,
        expiryDate: _expiryDate != null ? _dateFormat.format(_expiryDate!) : null,
        credentialId: _credentialIdController.text.trim().isEmpty
            ? null
            : _credentialIdController.text.trim(),
        credentialUrl: _credentialUrlController.text.trim().isEmpty
            ? null
            : _credentialUrlController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      final portfolioProvider = context.read<PortfolioProvider>();
      final success = await portfolioProvider.createCertificate(request);

      if (!mounted) return;

      if (success) {
        ErrorHandler.showSuccessSnackBar(context, 'Thêm chứng chỉ thành công!');
        Navigator.pop(context, true);
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          portfolioProvider.errorMessage ?? 'Có lỗi xảy ra, vui lòng thử lại',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Galaxy Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.galaxyDarkest, AppTheme.galaxyDark],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Custom AppBar
                  _buildCustomAppBar(),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildSectionHeader(
                              icon: Icons.card_membership,
                              title: 'Thêm chứng chỉ mới',
                              gradientColors: const [
                                AppTheme.themeOrangeStart,
                                AppTheme.themeOrangeEnd
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Basic Info Section
                            _buildBasicInfoSection(),
                            const SizedBox(height: 24),

                            // Credential Info Section
                            _buildCredentialSection(),
                            const SizedBox(height: 24),

                            // Timeline Section
                            _buildTimelineSection(),
                            const SizedBox(height: 24),

                            // Additional Info Section
                            _buildAdditionalInfoSection(),
                            const SizedBox(height: 32),

                            // Save Button
                            _buildSaveButton(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Thêm chứng chỉ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
            ).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chứng chỉ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          _buildTextField(
            controller: _titleController,
            label: 'Tên chứng chỉ *',
            hint: 'vd: AWS Certified Solutions Architect',
            prefixIcon: Icons.workspace_premium,
            validator: (value) => ValidationHelper.required(value, fieldName: 'Tên chứng chỉ'),
          ),
          const SizedBox(height: 16),

          // Issuer
          _buildTextField(
            controller: _issuerController,
            label: 'Tổ chức cấp *',
            hint: 'vd: Amazon Web Services',
            prefixIcon: Icons.business,
            validator: (value) => ValidationHelper.required(value, fieldName: 'Tổ chức cấp'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified,
                  color: AppTheme.themeOrangeStart, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Thông tin xác thực',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Credential ID
          _buildTextField(
            controller: _credentialIdController,
            label: 'Mã chứng chỉ',
            hint: 'vd: ABC123XYZ',
            prefixIcon: Icons.badge,
          ),
          const SizedBox(height: 16),

          // Credential URL
          _buildTextField(
            controller: _credentialUrlController,
            label: 'URL xác thực',
            hint: 'https://verify.certificate.com/...',
            prefixIcon: Icons.link,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.url(value, isRequired: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: AppTheme.themeGreenStart, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Thời gian',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Issue Date
          _buildDateSelector(
            label: 'Ngày cấp',
            date: _issueDate,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 16),

          // Expiry Date
          _buildDateSelector(
            label: 'Ngày hết hạn (nếu có)',
            date: _expiryDate,
            onTap: () => _selectDate(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin bổ sung',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Image URL
          _buildTextField(
            controller: _imageUrlController,
            label: 'URL hình ảnh chứng chỉ',
            hint: 'https://example.com/certificate.jpg',
            prefixIcon: Icons.image,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.url(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Mô tả',
            hint: 'Thông tin thêm về chứng chỉ...',
            prefixIcon: Icons.description,
            maxLines: 4,
            maxLength: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.darkBorderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: AppTheme.darkTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.darkTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? _dateFormat.format(date) : 'Chọn ngày',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down,
                color: AppTheme.darkTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppTheme.darkTextSecondary),
        counterText: maxLength != null ? null : '',
        labelStyle: const TextStyle(color: AppTheme.darkTextSecondary),
        hintStyle: const TextStyle(color: AppTheme.darkTextSecondary),
      ),
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.orangeGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.themeOrangeStart.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveCertificate,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Thêm chứng chỉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
