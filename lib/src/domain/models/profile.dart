import 'package:equatable/equatable.dart';

/// Host-provided profile metadata. The package never reads profile columns
/// directly — always via [ProfileLookup].
class ChatProfile extends Equatable {
  const ChatProfile({
    required this.name,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  List<Object?> get props => [name, avatarUrl];
}

/// Resolves a profile id to display metadata supplied by the host app.
typedef ProfileLookup = Future<ChatProfile> Function(String profileId);

/// Optional synchronous cache wrapper around an async [ProfileLookup].
class CachedProfileLookup {
  CachedProfileLookup(this._lookup);

  final ProfileLookup _lookup;
  final Map<String, ChatProfile> _cache = {};

  Future<ChatProfile> call(String profileId) async {
    final cached = _cache[profileId];
    if (cached != null) {
      return cached;
    }
    final profile = await _lookup(profileId);
    _cache[profileId] = profile;
    return profile;
  }

  void invalidate(String profileId) => _cache.remove(profileId);

  void clear() => _cache.clear();
}

/// Unknown profile placeholder when lookup fails.
const unknownProfile = ChatProfile(name: 'Unknown');
