import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/module_with_content_models.dart';
import 'dart:convert';

const jsonString = '''
[
  {
    "id": 266,
    "title": "Module 1: Nhập Môn & Môi Trường",
    "description": "Làm quen với kiến trúc React Native và cài đặt SDK.",
    "orderIndex": 1,
    "createdAt": "2026-04-13T03:28:24.742586Z",
    "updatedAt": "2026-04-13T03:28:24.742586Z",
    "lessons": [
      {
        "id": 566,
        "title": "Bài 1.1: Tổng quan kiến trúc React Native",
        "type": "READING",
        "orderIndex": 1,
        "durationSec": 900,
        "contentText": "React Native hoạt động thông qua JS Thread và Native Thread, giao tiếp qua Bridge/JSI..."
      },
      {
        "id": 567,
        "title": "Bài 1.2: Cài đặt SDK và Android Studio",
        "type": "VIDEO",
        "orderIndex": 2,
        "durationSec": 1500,
        "videoUrl": "https://www.youtube.com/watch?v=0-S5a0eXPoc"
      }
    ],
    "quizzes": [],
    "assignments": []
  },
  {
    "id": 267,
    "title": "Module 2: UI & Navigation",
    "description": "Thiết kế giao diện Core Components và Navigation.",
    "orderIndex": 2,
    "createdAt": "2026-04-13T03:28:24.879121Z",
    "updatedAt": "2026-04-13T03:28:24.879122Z",
    "lessons": [
      {
        "id": 568,
        "title": "Bài 2.1: Core Components (View, Text, FlatList)",
        "type": "VIDEO",
        "orderIndex": 1,
        "durationSec": 1800,
        "videoUrl": "https://www.youtube.com/watch?v=qSRrxpdMpVc"
      }
    ],
    "quizzes": [],
    "assignments": [
      {
        "id": 106,
        "title": "Đồ án 1: Xây dựng Profile Screen cơ bản",
        "description": "Dùng View, Text, Image và StyleSheet để tạo màn hình Profile đúng chuẩn Pixel-perfect. Gửi link Github repo của bạn tại đây.",
        "submissionType": "TEXT",
        "maxScore": 100.00,
        "moduleId": 267,
        "orderIndex": 2
      }
    ]
  }
]
''';

void main() {
  test('Test parsing listModulesWithContent', () {
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      final list = data
          .map(
            (json) =>
                ModuleWithContentDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      print('SUCCESS PARSING: \${list.length} modules found.');
    } catch (e, stackTrace) {
      print('=== PARSE ERROR ===');
      print(e);
      print(stackTrace);
      fail('Parsing failed');
    }
  });
}
