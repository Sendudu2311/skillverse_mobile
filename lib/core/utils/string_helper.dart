class StringHelper {
  /// Remove Vietnamese diacritics/accents to make searches case and accent insensitive
  static String removeDiacritics(String str) {
    if (str.isEmpty) return str;

    var result = str.toLowerCase();

    const vietnameseMap = <String, String>{
      'a': 'á|à|ả|ã|ạ|ă|ắ|ặ|ằ|ẳ|ẵ|â|ấ|ầ|ẩ|ẫ|ậ',
      'd': 'đ',
      'e': 'é|è|ẻ|ẽ|ẹ|ê|ế|ề|ể|ễ|ệ',
      'i': 'í|ì|ỉ|ĩ|ị',
      'o': 'ó|ò|ỏ|õ|ọ|ô|ố|ồ|ổ|ỗ|ộ|ơ|ớ|ờ|ở|ỡ|ợ',
      'u': 'ú|ù|ủ|ũ|ụ|ư|ứ|ừ|ử|ữ|ự',
      'y': 'ý|ỳ|ỷ|ỹ|ỵ',
    };

    vietnameseMap.forEach((nonAccent, regex) {
      result = result.replaceAll(RegExp(regex), nonAccent);
    });

    return result;
  }
}
