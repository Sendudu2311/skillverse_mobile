/// Validation helper for common form field validations
class ValidationHelper {
  // Private constructor to prevent instantiation
  ValidationHelper._();

  /// Validate field is not empty
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Trường này"} không được để trống';
    }
    return null;
  }

  /// Validate email format
  static String? email(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Email không được để trống' : null;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  /// Validate URL format (accepts both http and https)
  static String? url(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'URL không được để trống' : null;
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?\&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'URL không hợp lệ. URL phải bắt đầu bằng http:// hoặc https://';
    }

    return null;
  }

  /// Validate HTTPS-only URL (matches backend ValidPortfolioUrlValidator)
  static String? httpsUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'URL không được để trống' : null;
    }

    final trimmed = value.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (uri.scheme != 'https') {
        return 'URL phải sử dụng HTTPS';
      }
      if (uri.host.isEmpty) {
        return 'URL không hợp lệ';
      }
      return null;
    } catch (_) {
      return 'URL không hợp lệ';
    }
  }

  /// Validate GitHub URL (matches backend ValidGitHubUrlValidator)
  /// Requires https and github.com domain
  static String? githubUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'GitHub URL không được để trống' : null;
    }

    final trimmed = value.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (uri.host.isEmpty || !uri.host.contains('github.com')) {
        return 'URL GitHub không hợp lệ. Vui lòng nhập URL từ github.com';
      }
      if (uri.scheme != 'https') {
        return 'URL phải sử dụng HTTPS';
      }
      return null;
    } catch (_) {
      return 'URL không hợp lệ';
    }
  }

  /// Validate Behance URL (matches backend ValidBehanceUrlValidator)
  /// Requires https and behance.net domain
  static String? behanceUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Behance URL không được để trống' : null;
    }

    final trimmed = value.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (uri.host.isEmpty || !uri.host.contains('behance.net')) {
        return 'URL Behance không hợp lệ. Vui lòng nhập URL từ behance.net';
      }
      if (uri.scheme != 'https') {
        return 'URL phải sử dụng HTTPS';
      }
      return null;
    } catch (_) {
      return 'URL không hợp lệ';
    }
  }

  /// Validate Dribbble URL (matches backend ValidDribbbleUrlValidator)
  /// Requires https and dribbble.com domain
  static String? dribbbleUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Dribbble URL không được để trống' : null;
    }

    final trimmed = value.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (uri.host.isEmpty || !uri.host.contains('dribbble.com')) {
        return 'URL Dribbble không hợp lệ. Vui lòng nhập URL từ dribbble.com';
      }
      if (uri.scheme != 'https') {
        return 'URL phải sử dụng HTTPS';
      }
      return null;
    } catch (_) {
      return 'URL không hợp lệ';
    }
  }

  /// Reserved slugs that match backend ValidSlugValidator
  static const _reservedSlugs = {'create', 'api', 'admin', 'www', 'portfolio'};

  /// Validate slug format (matches backend ValidSlugValidator)
  /// Rules: lowercase + numbers + hyphens, min 3, max 60,
  /// no reserved words, no all-numeric, no leading/trailing/consecutive hyphens
  static String? slug(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired
          ? 'Đường dẫn tùy chỉnh là bắt buộc'
          : null;
    }

    final cleanSlug = value.trim().toLowerCase();

    if (cleanSlug.length < 3) {
      return 'Đường dẫn tùy chỉnh phải có ít nhất 3 ký tự';
    }

    if (cleanSlug.length > 60) {
      return 'Đường dẫn tùy chỉnh không được quá 60 ký tự';
    }

    if (RegExp(r'^[0-9-]+$').hasMatch(cleanSlug)) {
      return 'Đường dẫn tùy chỉnh không được chỉ chứa số và dấu gạch ngang';
    }

    if (cleanSlug.startsWith('-') || cleanSlug.endsWith('-')) {
      return 'Đường dẫn tùy chỉnh không được bắt đầu hoặc kết thúc bằng dấu gạch ngang';
    }

    if (cleanSlug.contains('--')) {
      return 'Đường dẫn tùy chỉnh không được có hai dấu gạch ngang liên tiếp';
    }

    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(cleanSlug)) {
      return 'Đường dẫn tùy chỉnh chỉ được chứa chữ thường, số và dấu gạch ngang';
    }

    if (_reservedSlugs.contains(cleanSlug)) {
      return '"$cleanSlug" là đường dẫn dự trữ của hệ thống. Vui lòng chọn đường dẫn khác';
    }

    return null;
  }

  /// Validate minimum length
  static String? minLength(
    String? value,
    int minLength, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Trường này"} không được để trống';
    }

    if (value.trim().length < minLength) {
      return '${fieldName ?? "Trường này"} phải có ít nhất $minLength ký tự';
    }

    return null;
  }

  /// Validate maximum length
  static String? maxLength(
    String? value,
    int maxLength, {
    String? fieldName,
  }) {
    if (value != null && value.trim().length > maxLength) {
      return '${fieldName ?? "Trường này"} không được vượt quá $maxLength ký tự';
    }

    return null;
  }

  /// Validate length range
  static String? lengthRange(
    String? value,
    int minLength,
    int maxLength, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Trường này"} không được để trống';
    }

    final length = value.trim().length;

    if (length < minLength) {
      return '${fieldName ?? "Trường này"} phải có ít nhất $minLength ký tự';
    }

    if (length > maxLength) {
      return '${fieldName ?? "Trường này"} không được vượt quá $maxLength ký tự';
    }

    return null;
  }

  /// Validate phone number (Vietnamese format)
  /// Matches backend VietnamesePhoneValidator: ^(0|\+84)[3-9][0-9]{8}$
  static String? phoneNumber(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Số điện thoại không được để trống' : null;
    }

    final cleanPhone = value.trim().replaceAll(RegExp(r'\s'), '');

    // Vietnamese phone: starts with 0 or +84, then digit 3-9, then 8 digits
    final phoneRegex = RegExp(r'^(0|\+84)[3-9][0-9]{8}$');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Số điện thoại không hợp lệ (vd: 0912345678 hoặc +84912345678)';
    }

    return null;
  }

  /// Validate number only
  static String? numeric(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Trường này không được để trống' : null;
    }

    final numericRegex = RegExp(r'^[0-9]+$');

    if (!numericRegex.hasMatch(value.trim())) {
      return 'Chỉ được nhập số';
    }

    return null;
  }

  /// Validate decimal number
  static String? decimal(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Trường này không được để trống' : null;
    }

    final decimalRegex = RegExp(r'^[0-9]+(\.[0-9]+)?$');

    if (!decimalRegex.hasMatch(value.trim())) {
      return 'Chỉ được nhập số thập phân';
    }

    return null;
  }

  /// Validate number range
  static String? numberRange(
    String? value,
    double min,
    double max, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Trường này"} không được để trống';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Giá trị phải là số hợp lệ';
    }

    if (number < min || number > max) {
      return '${fieldName ?? "Giá trị"} phải nằm trong khoảng $min - $max';
    }

    return null;
  }

  /// Validate password strength
  static String? password(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Mật khẩu không được để trống' : null;
    }

    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ hoa';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ thường';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số';
    }

    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }

    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }

    return null;
  }

  /// Validate date format (yyyy-MM-dd)
  static String? dateFormat(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Ngày không được để trống' : null;
    }

    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (!dateRegex.hasMatch(value.trim())) {
      return 'Định dạng ngày không hợp lệ (yyyy-MM-dd)';
    }

    // Try parsing the date
    try {
      DateTime.parse(value.trim());
    } catch (e) {
      return 'Ngày không hợp lệ';
    }

    return null;
  }

  /// Validate date range (start date must be before end date)
  static String? dateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return null;
    }

    if (endDate.isBefore(startDate)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu';
    }

    return null;
  }

  /// Validate GitHub username
  static String? githubUsername(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'GitHub username không được để trống' : null;
    }

    // GitHub username rules: alphanumeric + hyphens, no consecutive hyphens
    final githubRegex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');

    if (!githubRegex.hasMatch(value.trim())) {
      return 'GitHub username không hợp lệ';
    }

    return null;
  }

  /// Validate GitHub repository URL
  static String? githubRepoUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'GitHub repository URL không được để trống' : null;
    }

    final githubUrlRegex = RegExp(
      r'^https:\/\/github\.com\/[a-zA-Z0-9-]+\/[a-zA-Z0-9._-]+\/?$',
    );

    if (!githubUrlRegex.hasMatch(value.trim())) {
      return 'GitHub repository URL không hợp lệ (vd: https://github.com/user/repo)';
    }

    return null;
  }

  /// Validate LinkedIn profile URL
  static String? linkedInUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'LinkedIn URL không được để trống' : null;
    }

    final linkedInRegex = RegExp(
      r'^https:\/\/(www\.)?linkedin\.com\/(in|company)\/[a-zA-Z0-9-]+\/?$',
    );

    if (!linkedInRegex.hasMatch(value.trim())) {
      return 'LinkedIn URL không hợp lệ (vd: https://linkedin.com/in/username)';
    }

    return null;
  }

  /// Validate Twitter/X username
  static String? twitterUsername(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Twitter username không được để trống' : null;
    }

    // Remove @ if present
    final username = value.trim().replaceFirst('@', '');

    // Twitter username: alphanumeric + underscore, 1-15 chars
    final twitterRegex = RegExp(r'^[a-zA-Z0-9_]{1,15}$');

    if (!twitterRegex.hasMatch(username)) {
      return 'Twitter username không hợp lệ (1-15 ký tự, chỉ chữ, số và _)';
    }

    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  /// Create a custom validator with field name
  static String? Function(String?) withFieldName(
    String? Function(String?, {String? fieldName}) validator,
    String fieldName,
  ) {
    return (value) => validator(value, fieldName: fieldName);
  }
}
