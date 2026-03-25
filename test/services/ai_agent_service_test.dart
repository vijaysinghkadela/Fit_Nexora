import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_ai/services/ai_agent_service.dart';

void main() {
  group('AiAgentService parsing helpers', () {
    test('extractMessageText normalizes nested content blocks', () {
      final text = AiAgentService.extractMessageText([
        'First line',
        {'text': 'Second line'},
        {
          'content': [
            'Third line',
            {'value': 'Fourth line'},
          ],
        },
      ]);

      expect(text, 'First line\nSecond line\nThird line\nFourth line');
    });

    test('decodeJsonObject handles JSON-only and fenced payloads', () {
      expect(
        AiAgentService.decodeJsonObject('{"alpha":1,"nested":{"beta":2}}'),
        {
          'alpha': 1,
          'nested': {'beta': 2},
        },
      );

      expect(
        AiAgentService.decodeJsonObject('```json\n{"gamma":3}\n```'),
        {'gamma': 3},
      );
    });

    test('decodeJsonObject falls back to raw text for malformed payloads', () {
      expect(
        AiAgentService.decodeJsonObject('this is not valid json'),
        {'raw_text': 'this is not valid json'},
      );
    });

    test('parseNvidiaChatPayload includes reasoning content and usage', () {
      final result = AiAgentService.parseNvidiaChatPayload(
        {
          'model': 'moonshotai/kimi-k2-thinking',
          'choices': [
            {
              'message': {
                'content': [
                  {'text': '{"plan":"combined"}'},
                ],
                'reasoning_content': [
                  'Step one reasoning',
                  {'text': 'Step two reasoning'},
                ],
              },
            },
          ],
          'usage': {
            'prompt_tokens': 12,
            'completion_tokens': 34,
          },
        },
        fallbackModel: 'fallback-model',
        generationMs: 456,
      );

      expect(result.content, '{"plan":"combined"}');
      expect(result.reasoningContent, 'Step one reasoning\nStep two reasoning');
      expect(result.tokensUsed, 46);
      expect(result.model, 'moonshotai/kimi-k2-thinking');
      expect(result.generationMs, 456);
    });

    test('parseNvidiaChatPayload survives missing model and empty choices', () {
      final result = AiAgentService.parseNvidiaChatPayload(
        {
          'choices': [
            {
              'message': {
                'content': 'plain content',
              },
            },
          ],
        },
        fallbackModel: 'fallback-model',
        generationMs: 0,
      );

      expect(result.content, 'plain content');
      expect(result.reasoningContent, '');
      expect(result.tokensUsed, 0);
      expect(result.model, 'fallback-model');
    });
  });
}
