import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:elevenlabs_agents/src/utils/overrides.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsrOverrides.toJson', () {
    test('omits keywords key when keywords is null', () {
      expect(AsrOverrides().toJson(), <String, dynamic>{});
    });

    test('emits keywords when non-empty', () {
      expect(
        AsrOverrides(keywords: ['colonoscopy', 'dr smith']).toJson(),
        {
          'keywords': ['colonoscopy', 'dr smith'],
        },
      );
    });

    test('emits an empty keywords list verbatim (guards null only)', () {
      expect(AsrOverrides(keywords: <String>[]).toJson(), {'keywords': <String>[]});
    });
  });

  group('ConversationOverrides.toJson - asr', () {
    test('omits asr when null', () {
      final json = ConversationOverrides(
        agent: AgentOverrides(prompt: 'hi'),
      ).toJson();
      expect(json.containsKey('asr'), isFalse);
      expect(json.containsKey('agent'), isTrue);
    });

    test('emits asr as a top-level sibling of agent', () {
      final json = ConversationOverrides(
        agent: AgentOverrides(prompt: 'hi'),
        asr: AsrOverrides(keywords: ['aspirin']),
      ).toJson();
      expect(json.containsKey('agent'), isTrue);
      expect(json.containsKey('asr'), isTrue);
      expect(json['asr'], {
        'keywords': ['aspirin'],
      });
    });
  });

  group('constructOverrides - asr emission', () {
    ConversationConfig configWith(ConversationOverrides overrides) =>
        ConversationConfig(
          conversationToken: 'tok',
          overrides: overrides,
        );

    test('emits conversation_config_override.asr only when asr present', () {
      final json = constructOverrides(
        configWith(
          ConversationOverrides(asr: AsrOverrides(keywords: ['aspirin'])),
        ),
      );
      final cco = json['conversation_config_override'] as Map<String, dynamic>;
      expect(cco['asr'], {
        'keywords': ['aspirin'],
      });
    });

    test('omits asr when absent, without regressing existing keys', () {
      final json = constructOverrides(
        configWith(
          ConversationOverrides(
            agent: AgentOverrides(prompt: 'hi', firstMessage: 'hello'),
            tts: TtsOverrides(voiceId: 'v1'),
          ),
        ),
      );
      final cco = json['conversation_config_override'] as Map<String, dynamic>;
      expect(cco.containsKey('asr'), isFalse);
      expect(cco.containsKey('agent'), isTrue);
      expect(cco.containsKey('tts'), isTrue);
      expect((cco['agent'] as Map)['prompt'], {'prompt': 'hi'});
      expect((cco['agent'] as Map)['first_message'], 'hello');
    });

    test('agent and asr co-emit as siblings under conversation_config_override', () {
      final json = constructOverrides(
        configWith(
          ConversationOverrides(
            agent: AgentOverrides(prompt: 'hi'),
            asr: AsrOverrides(keywords: ['colonoscopy']),
          ),
        ),
      );
      final cco = json['conversation_config_override'] as Map<String, dynamic>;
      expect(cco.containsKey('agent'), isTrue);
      expect(cco.containsKey('asr'), isTrue);
    });
  });
}
