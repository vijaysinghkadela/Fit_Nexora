import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymos_ai/providers/motivation_quote_provider.dart';
import 'package:go_router/go_router.dart';

/// Daily Motivation Quotes Screen
class MotivationQuoteScreen extends ConsumerWidget {
  const MotivationQuoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(motivationQuoteProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/member');
            }
          },
        ),
        title: const Text('Daily Motivation'),
      ),
      body: Center(
        child: quoteAsync.when(
          data: (quote) => Card(
            margin: const EdgeInsets.all(32.0),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.format_quote, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    quote.text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 24,
                        ),
                  ),
                  if (quote.author.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '- ${quote.author}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 18,
                          ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .read(motivationQuoteProvider.notifier)
                        .loadDailyQuote(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Quote'),
                  ),
                ],
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Unable to load quote',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref
                      .read(motivationQuoteProvider.notifier)
                      .loadDailyQuote(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
