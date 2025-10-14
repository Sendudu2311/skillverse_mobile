/// Guard result types
class GuardResult {
  final bool allow;
  final String? reason;

  const GuardResult({required this.allow, this.reason});

  const GuardResult.allow() : allow = true, reason = null;
  const GuardResult.deny(String reason) : allow = false, reason = reason;
}

/// Normalize text for pattern matching (remove accents, lowercase)
String _normalize(String text) {
  try {
    // Remove accents/diacritics
    final normalized = text.toLowerCase();
    // Simple accent removal for Vietnamese
    return normalized
        .replaceAll('àáạảãâầấậẩẫăằắặẳẵ', 'a')
        .replaceAll('èéẹẻẽêềếệểễ', 'e')
        .replaceAll('ìíịỉĩ', 'i')
        .replaceAll('òóọỏõôồốộổỗơờớợởỡ', 'o')
        .replaceAll('ùúụủũưừứựửữ', 'u')
        .replaceAll('ỳýỵỷỹ', 'y')
        .replaceAll('đ', 'd');
  } catch (e) {
    return text.toLowerCase();
  }
}

/// Injection/jailbreak patterns (Vietnamese + English)
final List<RegExp> _injectionPatterns = [
  RegExp(r'bo qua (cac )?(lenh|huong dan)( hien tai| truoc do)?', caseSensitive: false),
  RegExp(r'phot lo( )?(tat ca )?(lenh|huong dan)', caseSensitive: false),
  RegExp(r'bo tat (ca )?rang buoc|khong can theo quy tac', caseSensitive: false),
  RegExp(r'ignore (all )?(previous|prior|above) (instructions|messages|rules)', caseSensitive: false),
  RegExp(r'disregard (the )?(rules|system|instructions)', caseSensitive: false),
  RegExp(r'override (the )?(system|guard|policy|safety)', caseSensitive: false),
  RegExp(r'jailbreak|bypass|prompt[ -]?injection|system prompt', caseSensitive: false),
  RegExp(r'act as .* (without|bypassing) (rules|safety|guard)', caseSensitive: false),
  RegExp(r'pretend you are not bound by', caseSensitive: false),
  RegExp(r'bat dau che do (moi|khong han che|developer|debug|unrestricted)', caseSensitive: false),
  RegExp(r'quen het (huong dan|lenh) truoc', caseSensitive: false),
  RegExp(r'hanh dong nhu (mot|khong co) (rang buoc|luat le|an toan)', caseSensitive: false),
  RegExp(r'simulate (unrestricted|no rules) mode', caseSensitive: false),
  RegExp(r'bay gio (la|tro thanh) (ai khong kiem duyet|uncensored bot)', caseSensitive: false),
  RegExp(r'dung (tuan thu|theo) (quy dinh|he thong)', caseSensitive: false),
  RegExp(r'leak (system|prompt|instructions)', caseSensitive: false),
  RegExp(r'repeat after me: (ignore|override)', caseSensitive: false),
  RegExp(r'encoded: (base64|rot13|hex)', caseSensitive: false),
  RegExp(r'hay gia vo (rang|nhu) (ban khong co|khong bi rang buoc)', caseSensitive: false),
  RegExp(r'tro thanh ai khac|become someone else', caseSensitive: false),
  RegExp(r'thay doi (he thong|cau truc|quy tac)', caseSensitive: false),
];

/// Out-of-scope topic patterns
final List<RegExp> _outOfScopePatterns = [
  // Culinary/recipes
  RegExp(r'cong thuc|recipe|nau an|lam banh|banh (su|su kem|flan|kem|choux)|pha che|am thuc|mon an', caseSensitive: false),
  RegExp(r'cocktail|ruou|bia|nau (canh|sup|chao)', caseSensitive: false),

  // Personal finance/investing
  RegExp(r'tai chinh ca nhan|dau tu|chung khoan|crypto|coin|bitcoin|keo (call|rug)|trade|forex|ngan hang', caseSensitive: false),
  RegExp(r'lam giau|kinh doanh ca nhan|cho vay|dau co', caseSensitive: false),

  // Medical
  RegExp(r'y te|chan doan|ke don|trieu chung|medical advice|benh (tat|vien|ung thu)', caseSensitive: false),
  RegExp(r'thuoc (men|chua|dieu tri)|diet|che do an uong', caseSensitive: false),

  // Legal
  RegExp(r'phap ly|luat su|legal advice|hop dong|to tung|quyen so huu', caseSensitive: false),
  RegExp(r'ly hon|ke thua|thue (thanh toan|vat)', caseSensitive: false),

  // Adult content
  RegExp(r'18\+|xxx|nsfw|sex|porn|erotic|nguoi lon', caseSensitive: false),
  RegExp(r'hentai|bdsm|adult content', caseSensitive: false),

  // Sensitive politics/hate speech
  RegExp(r'hate speech|cuc doan|phan biet chung toc|racism|terrorism', caseSensitive: false),
  RegExp(r'chinh tri (dang phai|quoc gia)|bien dong|chien tranh', caseSensitive: false),

  // Entertainment/gambling
  RegExp(r'phim anh|series|netflix|youtube drama|ca si|nghe si', caseSensitive: false),
  RegExp(r'ca do|gambling|casino|poker|xo so|betting', caseSensitive: false),

  // Religion/superstition
  RegExp(r'ton giao|me tin|boi toan|horoscope|phong thuy', caseSensitive: false),

  // Violence/weapons/illegal content
  RegExp(r'bao luc|vu khi|sung|dao kiem|self defense', caseSensitive: false),
  RegExp(r'hack|crack|pirate|illegal download', caseSensitive: false),
];

/// Guard user input against injection attacks and out-of-scope topics
GuardResult guardUserInput(String rawInput) {
  final normalized = _normalize(rawInput);

  // Check for injection patterns
  if (_injectionPatterns.any((pattern) => pattern.hasMatch(normalized))) {
    return const GuardResult.deny('injection');
  }

  // Check for out-of-scope topics
  if (_outOfScopePatterns.any((pattern) => pattern.hasMatch(normalized))) {
    return const GuardResult.deny('out_of_scope');
  }

  return const GuardResult.allow();
}

/// Fallback messages for different guard reasons
const Map<String, Map<String, String>> _fallbacks = {
  'injection': {
    'vi': 'Xin lỗi, mình không thể thực hiện yêu cầu này. Meowl chỉ hỗ trợ câu hỏi về học tập, kỹ năng và nền tảng SkillVerse 🐱✨.',
    'en': 'Sorry, I can\'t follow that. Meowl only supports questions about learning, skills, and the SkillVerse platform 🐱✨.'
  },
  'out_of_scope': {
    'vi': 'Mình chỉ hỗ trợ về khóa học, kỹ năng và SkillVerse. Bạn thử hỏi về lộ trình học, khóa phù hợp, hoặc mẹo học tập nhé!',
    'en': 'I can only help with courses, skills, and SkillVerse. Try asking about learning paths, suitable courses, or study tips!'
  },
  'output': {
    'vi': 'Có vẻ câu trả lời đi ngoài phạm vi giáo dục/kỹ năng. Bạn thử hỏi lại về khóa học hay lộ trình học nhé 🐱✨.',
    'en': 'It seems the answer goes beyond learning/skills. Please ask about courses or learning paths instead 🐱✨.'
  }
};

/// Get fallback message for a guard reason and language
String pickFallback(String reason, String language) {
  final lang = language == 'vi' ? 'vi' : 'en';
  return _fallbacks[reason]?[lang] ?? _fallbacks[reason]?['en'] ?? 'Sorry, I can\'t help with that right now.';
}