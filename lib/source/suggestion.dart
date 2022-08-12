import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/active_server.dart';
import '../../utils/extensions/string.dart';
import '../../utils/retry_future.dart';
import '../../utils/server/response_parser.dart';
import '../entity/server_data.dart';
import '../services/http.dart';
import 'blocked_tags.dart';

final _dataSource = Provider(SuggestionSource.new);
final suggestionFuture =
    FutureProvider.autoDispose.family<List<String>, String>((ref, query) async {
  final serverActive = ref.watch(activeServerProvider);
  if (serverActive == ServerData.empty) {
    return [];
  }

  final source = ref.watch(_dataSource);
  return await source.fetch(query: query, server: serverActive);
});

class SuggestionSource {
  SuggestionSource(this.ref);

  final Ref ref;

  Future<List<String>> fetch({
    required String query,
    required ServerData server,
  }) async {
    final blockedTags = ref.read(blockedTagsProvider);
    final client = ref.read(httpProvider);

    final queries = query.toWordList();
    final url = server.suggestionUrlOf(queries.isEmpty ? '' : queries.last);
    try {
      final res = await retryFuture(
        () => client.get(url.asUri).timeout(const Duration(seconds: 5)),
        retryIf: (e) => e is SocketException || e is TimeoutException,
      );

      return ServerResponseParser.parseTagSuggestion(res, query)
          .where((it) => !blockedTags.listedEntries.contains(it))
          .toList();
    } catch (e) {
      if (query.isEmpty) {
        // the server did not support empty tag matches (hot/trending tags)
        return [];
      }
      rethrow;
    }
  }
}
