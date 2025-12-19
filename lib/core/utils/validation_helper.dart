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

  /// Validate URL format
  static String? url(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'URL không được để trống' : null;
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'URL không hợp lệ. URL phải bắt đầu bằng http:// hoặc https://';
    }

    return null;
  }

  /// Validate slug format (lowercase, numbers, hyphens only)
  static String? slug(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Slug không được để trống' : null;
    }

    final slugRegex = RegExp(r'^[a-z0-9-]+$');

    if (!slugRegex.hasMatch(value.trim())) {
      return 'Slug chỉ được chứa chữ thường, số và dấu gạch ngang';
    }

    if (value.startsWith('-') || value.endsWith('-')) {
      return 'Slug không được bắt đầu hoặc kết thúc bằng dấu gạch ngang';
    }

    if (value.contains('--')) {
      return 'Slug không được chứa nhiều dấu gạch ngang liên tiếp';
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
  static String? phoneNumber(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Số điện thoại không được để trống' : null;
    }

    // Vietnamese phone number: starts with 0, followed by 9 digits
    final phoneRegex = RegExp(r'^0[0-9]{9}$');

    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
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
