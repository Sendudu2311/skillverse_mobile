import 'package:json_annotation/json_annotation.dart';

part 'group_chat_models.g.dart';

/// Mirrors backend GroupChatResponse DTO
@JsonSerializable()
class GroupChatResponse {
  final int id;
  final int? courseId;
  final int mentorId;
  final String? mentorName;
  final String name;
  final String? avatarUrl;
  final String? createdAt;
  final bool isMember;
  final int memberCount;
  final List<GroupMemberDTO>? members;

  GroupChatResponse({
    required this.id,
    this.courseId,
    required this.mentorId,
    this.mentorName,
    required this.name,
    this.avatarUrl,
    this.createdAt,
    this.isMember = false,
    this.memberCount = 0,
    this.members,
  });

  factory GroupChatResponse.fromJson(Map<String, dynamic> json) =>
      _$GroupChatResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GroupChatResponseToJson(this);
}

/// Mirrors backend GroupMemberDTO
@JsonSerializable()
class GroupMemberDTO {
  final int userId;
  final String? userName;
  final String? email;
  final String? avatarUrl;
  final String? role; // MENTOR, STUDENT
  final String? joinedAt;
  final bool isOnline;

  GroupMemberDTO({
    required this.userId,
    this.userName,
    this.email,
    this.avatarUrl,
    this.role,
    this.joinedAt,
    this.isOnline = false,
  });

  factory GroupMemberDTO.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDTOFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberDTOToJson(this);
}

/// Mirrors backend GroupChatMessageDTO
@JsonSerializable()
class GroupChatMessageDTO {
  final int? id;
  final int? groupId;
  final int? senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String content;
  final String? timestamp;
  final String messageType; // TEXT, EMOJI, GIF, IMAGE
  final String? gifUrl;
  final String? imageUrl;
  final String? emojiCode;

  GroupChatMessageDTO({
    this.id,
    this.groupId,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.content,
    this.timestamp,
    this.messageType = 'TEXT',
    this.gifUrl,
    this.imageUrl,
    this.emojiCode,
  });

  factory GroupChatMessageDTO.fromJson(Map<String, dynamic> json) =>
      _$GroupChatMessageDTOFromJson(json);
  Map<String, dynamic> toJson() => _$GroupChatMessageDTOToJson(this);

  /// Check if this message was sent by the given user
  bool isMine(int userId) => senderId == userId;
}
