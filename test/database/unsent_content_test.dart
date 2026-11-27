import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// A run marking [length] characters from [start] as part [part] of the message, as the server sends it.
Map<String, dynamic> _run(int start, int length, int part) => {
  'range': [start, length],
  'attributes': {'__kIMMessagePartAttributeName': part},
};

/// The message as stored before anything was unsent.
Message _stored({String text = 'see you at 8', Map<String, dynamic>? metadata}) =>
    Message(guid: 'msg', text: text, handleId: 0, metadata: metadata);

/// The same message coming back with [parts] unsent. iMessage clears the text of a message unsent whole.
Message _unsent({List<int> parts = const [0], String? text, Map<String, dynamic>? metadata}) => Message(
  guid: 'msg',
  text: text,
  handleId: 0,
  dateEdited: DateTime(2026, 11, 27, 10, 1),
  metadata: metadata,
  messageSummaryInfo: [
    MessageSummaryInfo(retractedParts: parts, editedContent: {}, originalTextRange: {}, editedParts: []),
  ],
);

Map<String, dynamic> _serverCopy(String text) => {
  Message.unsentContentKey: {'text': text, 'subject': null, 'savedAt': 1, 'fromServer': true},
};

void main() {
  group('reading the server copy', () {
    test("the server's unsentContent lands in metadata, marked as the server's", () {
      final message = Message.fromMap({
        'guid': 'msg',
        'text': null,
        'unsentContent': {'text': 'see you at 8', 'subject': null, 'attachments': null, 'savedAt': 1795700000000},
      });
      final kept = message.unsentContent!;
      expect(kept.text, 'see you at 8');
      expect(kept.fromServer, isTrue);
      expect(kept.savedAt, DateTime.fromMillisecondsSinceEpoch(1795700000000));
      expect(message.text ?? '', isEmpty, reason: 'the chat still draws the message as unsent');
    });

    test('a message without the field has no kept copy', () {
      expect(Message.fromMap({'guid': 'msg', 'text': 'hi'}).unsentContent, isNull);
    });

    test('an empty copy counts as none', () {
      expect(
        Message.fromMap({
          'guid': 'msg',
          'unsentContent': {'text': '  ', 'subject': null},
        }).unsentContent,
        isNull,
      );
    });
  });

  group('keptUnsentContent', () {
    test("an unsend arriving takes a copy of the stored message's text", () {
      final kept = Message.keptUnsentContent(_stored(), _unsent());
      expect(kept?['text'], 'see you at 8');
      expect(kept?['fromServer'], isFalse);
    });

    test('works with the stored copy on either side, as merges are called both ways', () {
      expect(Message.keptUnsentContent(_unsent(), _stored())?['text'], 'see you at 8');
    });

    test("the server's copy wins over one taken on this device", () {
      final kept = Message.keptUnsentContent(_stored(), _unsent(metadata: _serverCopy('from the server')));
      expect(kept?['text'], 'from the server');
      expect(kept?['fromServer'], isTrue);
    });

    test('a copy already kept stays when the unsend arrives again', () {
      final first = _unsent(
        metadata: {
          Message.unsentContentKey: {'text': 'kept earlier', 'fromServer': false},
        },
      );
      expect(Message.keptUnsentContent(first, _unsent())?['text'], 'kept earlier');
    });

    test('nothing to keep when neither copy is unsent, or both already are', () {
      expect(Message.keptUnsentContent(_stored(), _stored()), isNull);
      expect(Message.keptUnsentContent(_unsent(), _unsent()), isNull);
    });

    test('nothing to keep when the copy from before the unsend was empty', () {
      expect(Message.keptUnsentContent(_stored(text: ''), _unsent()), isNull);
    });
  });

  group('Message.merge', () {
    test('a synced unsend clears the text but keeps a copy of it', () {
      final merged = Message.merge(_stored(), _unsent());
      expect(merged.text, isNull);
      expect(merged.unsentContent?.text, 'see you at 8');
    });

    test('a partial unsend keeps the whole original, not just what is left', () {
      final merged = Message.merge(_stored(text: 'one two'), _unsent(parts: [1], text: 'one'));
      expect(merged.text, 'one');
      expect(merged.unsentContent?.text, 'one two');
    });
  });

  group('textForPart', () {
    final multipart = UnsentContent.fromMap({
      'text': 'first second',
      'attributedBody': [
        {
          'string': 'first second',
          'runs': [_run(0, 6, 0), _run(6, 6, 1)],
        },
      ],
    })!;

    test("each part's own text comes from the attributed body", () {
      expect(multipart.textForPart(0), 'first ');
      expect(multipart.textForPart(1), 'second');
    });

    test('a part the body has no text for has none', () {
      expect(multipart.textForPart(2), isNull);
    });

    test('without a body, the whole text is part 0', () {
      final plain = UnsentContent.fromMap({'text': 'hello'})!;
      expect(plain.textForPart(0), 'hello');
      expect(plain.textForPart(1), isNull);
    });

    test('runs outside the string are skipped rather than throwing', () {
      final broken = UnsentContent.fromMap({
        'text': 'hi',
        'attributedBody': [
          {
            'string': 'hi',
            'runs': [_run(0, 40, 0)],
          },
        ],
      })!;
      expect(broken.textForPart(0), isNull);
    });
  });

  group('unsentTextForPart', () {
    test('uses the kept copy', () {
      final message = _unsent(metadata: _serverCopy('from the server'));
      expect(message.unsentTextForPart(0, fullyUnsent: true), 'from the server');
    });

    test('falls back to the text still stored when nothing was kept', () {
      expect(_unsent(text: 'still stored').unsentTextForPart(0, fullyUnsent: true), 'still stored');
    });

    test("doesn't pass off what's left of a partly unsent message as the unsent part", () {
      expect(_unsent(parts: [1], text: 'what is left').unsentTextForPart(1, fullyUnsent: false), isNull);
    });

    test('names the attachments of a message that was only attachments', () {
      final message = _unsent(
        metadata: {
          Message.unsentContentKey: {
            'text': null,
            'attachments': [
              {'transferName': 'IMG_0001.HEIC'},
            ],
            'fromServer': true,
          },
        },
      );
      expect(message.unsentTextForPart(0, fullyUnsent: true), 'Attachment: IMG_0001.HEIC');
    });
  });
}
