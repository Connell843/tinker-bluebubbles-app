import 'package:bluebubbles/database/global/attributed_body.dart';

/// What a message said before it was unsent. iMessage clears an unsent message's text and body, so this copy is
/// all that's left of it: either kept by the server (sent as `unsentContent`, BlueBubbles Server with saved copies
/// on) or taken from this device's own stored copy when the unsend arrived.
///
/// Lives in the message's `metadata` under [Message.unsentContentKey], so it's saved with the message and shows in
/// its Message Info. The chat still draws the part as unsent; this is only read from there.
class UnsentContent {
  UnsentContent({
    this.text,
    this.subject,
    this.attributedBody = const [],
    this.attachmentNames = const [],
    this.savedAt,
    this.fromServer = false,
  });

  final String? text;
  final String? subject;
  final List<AttributedBody> attributedBody;

  /// File names of the attachments the message had. The files themselves aren't kept.
  final List<String> attachmentNames;

  /// When the copy was taken, if known.
  final DateTime? savedAt;

  /// Whether the server kept this copy, rather than this device.
  final bool fromServer;

  bool get isEmpty => (text ?? "").trim().isEmpty && (subject ?? "").trim().isEmpty && attachmentNames.isEmpty;

  /// Reads the server's `unsentContent` field, or a copy already stored in a message's metadata.
  static UnsentContent? fromMap(dynamic json) {
    if (json is! Map) return null;
    final map = json.cast<String, dynamic>();
    final body = map["attributedBody"];
    final attachments = map["attachments"];
    final savedAt = map["savedAt"];
    final content = UnsentContent(
      text: map["text"] as String?,
      subject: map["subject"] as String?,
      attributedBody: body is List
          ? body.whereType<Map>().map((e) => AttributedBody.fromMap(e.cast<String, dynamic>())).toList()
          : const [],
      attachmentNames: attachments is List
          ? attachments.map((e) => e is Map ? (e["transferName"] ?? e["name"]) : e).whereType<String>().toList()
          : const [],
      savedAt: savedAt is int ? DateTime.fromMillisecondsSinceEpoch(savedAt) : null,
      fromServer: map["fromServer"] == true,
    );
    return content.isEmpty ? null : content;
  }

  Map<String, dynamic> toMap() => {
    "text": text,
    "subject": subject,
    if (attributedBody.isNotEmpty) "attributedBody": attributedBody.map((e) => e.toMap()).toList(),
    if (attachmentNames.isNotEmpty) "attachments": attachmentNames.map((e) => {"transferName": e}).toList(),
    "savedAt": savedAt?.millisecondsSinceEpoch,
    "fromServer": fromServer,
  };

  /// The text the given part had. A message's parts are told apart by the attributed body; without one, the whole
  /// text is part 0's.
  String? textForPart(int part) {
    final body = attributedBody.firstOrNull;
    if (body != null) {
      final buffer = StringBuffer();
      var found = false;
      for (final run in body.runs) {
        if (run.attributes?.messagePart != part || run.isAttachment || run.range.length != 2) continue;
        final start = run.range[0], length = run.range[1];
        if (start < 0 || length <= 0 || start + length > body.string.length) continue;
        buffer.write(body.string.substring(start, start + length));
        found = true;
      }
      if (found) return buffer.toString();
      // A body that has runs but none for this part: the part was only an attachment
      if (body.runs.any((r) => r.attributes?.messagePart != null)) return null;
    }
    return part == 0 ? text : null;
  }
}
