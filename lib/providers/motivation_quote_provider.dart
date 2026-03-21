// Implementation of Motivation Quotes Provider with offline support
// Using both local cached quotes and API fetch when available

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/quote_model.dart';

/// Motivation Quote Provider - Provides daily motivational quotes
/// Handles both offline (local cache) and online mode
class MotivationQuoteProvider extends StateNotifier<AsyncValue<QuoteModel>> {
  final math.Random _random = math.Random();

  // Local quotes for offline mode
  static const List<QuoteModel> _localQuotes = [
    QuoteModel(
      id: 'local_1',
      text: 'The only bad workout is the one that didn\'t happen.',
      author: 'Unknown',
      category: 'workout',
    ),
    QuoteModel(
      id: 'local_2',
      text: 'Your only limit is you.',
      author: 'Unknown',
      category: 'motivation',
    ),
    QuoteModel(
      id: 'local_3',
      text: 'Push yourself because no one else is going to do it for you.',
      author: 'Unknown',
      category: 'motivation',
    ),
    QuoteModel(
      id: 'local_4',
      text: 'Success isn\'t always about greatness. It\'s about consistency.',
      author: 'Dwayne Johnson',
      category: 'success',
    ),
    QuoteModel(
      id: 'local_5',
      text: 'The body achieves what the mind believes.',
      author: 'Unknown',
      category: 'mindset',
    ),
    QuoteModel(
      id: 'local_6',
      text: 'Don\'t wish for it, work for it.',
      author: 'Unknown',
      category: 'workout',
    ),
    QuoteModel(
      id: 'local_7',
      text: 'It never gets easier, you just get stronger.',
      author: 'Unknown',
      category: 'progress',
    ),
    QuoteModel(
      id: 'local_8',
      text: 'Every workout counts.',
      author: 'Unknown',
      category: 'consistency',
    ),
    QuoteModel(
      id: 'local_9',
      text: 'You don\'t have to be great to start, but you have to start to be great.',
      author: 'Zig Ziglar',
      category: 'start',
    ),
    QuoteModel(
      id: 'local_10',
      text: 'The pain you feel today will be the strength you feel tomorrow.',
      author: 'Unknown',
      category: 'resilience',
    ),
    QuoteModel(
      id: 'local_11',
      text: 'Slow progress is still progress.',
      author: 'Unknown',
      category: 'patience',
    ),
    QuoteModel(
      id: 'local_12',
      text: 'Success is usually the culmination of controlling failure.',
      author: 'Sylvester Stallone',
      category: 'success',
    ),
    QuoteModel(
      id: 'local_13',
      text: 'If you want something you\'ve never had, you must be willing to do something you\'ve never done.',
      author: 'Thomas Jefferson',
      category: 'commitment',
    ),
    QuoteModel(
      id: 'local_14',
      text: 'Discipline is choosing between what you want now and what you want most.',
      author: 'Unknown',
      category: 'discipline',
    ),
    QuoteModel(
      id: 'local_15',
      text: 'A little progress each day adds up to big results.',
      author: 'Unknown',
      category: 'consistency',
    ),
    QuoteModel(
      id: 'local_16',
      text: 'Strength does not come from what you can do. It comes from overcoming the things you once thought you couldn\'t.',
      author: 'Rikki Rogers',
      category: 'strength',
    ),
    QuoteModel(
      id: 'local_17',
      text: 'The difference between try and triumph is a little\'umph.',
      author: 'Marvin Phillips',
      category: 'motivation',
    ),
    QuoteModel(
      id: 'local_18',
      text: 'When you feel like quitting, think about why you started.',
      author: 'Unknown',
      category: 'perseverance',
    ),
    QuoteModel(
      id: 'local_19',
      text: 'Today I will do what others won\'t, so tomorrow I can do what others can\'t.',
      author: 'Jerry Rice',
      category: 'dedication',
    ),
    QuoteModel(
      id: 'local_20',
      text: 'The hardest lift of all is lifting your butt off the couch.',
      author: 'Unknown',
      category: 'humor',
    ),
  ];

  // API quotes cache
  List<QuoteModel> _apiQuotes = [];

  MotivationQuoteProvider() : super(const AsyncLoading()) {
    Future.microtask(loadDailyQuote);
  }

  /// Loads a daily motivational quote
  Future<void> loadDailyQuote() async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.mobile);

      QuoteModel quote;

      // Try to load from API when online
      if (isOnline) {
        quote = await _loadFromApiWithFallback();
      } else {
        // Offline mode - use local quotes
        quote = _localQuotes[_random.nextInt(_localQuotes.length)];
      }

      state = AsyncData(quote);
    } catch (e) {
      // Fallback to local on any error
      state = AsyncData(_localQuotes[_random.nextInt(_localQuotes.length)]);
    }
  }

  /// Try API first, fallback to local
  Future<QuoteModel> _loadFromApiWithFallback() async {
    try {
      // Attempt API fetch if not already cached
      if (_apiQuotes.isEmpty) {
        _apiQuotes = await _fetchFromApi();
      }

      // Use API quotes if available
      if (_apiQuotes.isNotEmpty) {
        return _apiQuotes[_random.nextInt(_apiQuotes.length)];
      }

      // Fallback to local
      return _localQuotes[_random.nextInt(_localQuotes.length)];
    } catch (e) {
      // On any error, use local quotes
      return _localQuotes[_random.nextInt(_localQuotes.length)];
    }
  }

  /// Fetch quotes from external API (quotable.io - free, no API key required)
  Future<List<QuoteModel>> _fetchFromApi() async {
    // Using Quotable.io API - free, no authentication required
    // Returns random quotes with properties: _id, content, author
    try {
      // Note: This is a placeholder for API implementation
      // In production, integrate with: https://api.quotable.io/random
      // For now, return empty list to trigger local fallback
      return [];
      
      // Real implementation would use http package:
      // final response = await http.get(Uri.parse('https://api.quotable.io/random'));
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   return [QuoteModel(
      //     id: data['_id'] ?? '',
      //     text: data['content'] ?? '',
      //     author: data['author'] ?? 'Unknown',
      //     category: 'motivation',
      //   )];
      // }
      // return [];
    } catch (e) {
      return [];
    }
  }
}

// Provider for accessing quotes
final motivationQuoteProvider = StateNotifierProvider<MotivationQuoteProvider, AsyncValue<QuoteModel>>((ref) {
  return MotivationQuoteProvider();
});
