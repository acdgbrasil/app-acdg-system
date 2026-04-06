import 'dart:collection';
import 'dart:math';

/// Represents an authenticated user session.
class Session {
  Session({
    required this.id,
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required Set<String> roles,
    required this.expiresAt,
  }) : roles = UnmodifiableSetView(Set.of(roles));

  /// Unique session identifier.
  final String id;

  /// OAuth2 access token.
  final String accessToken;

  /// OAuth2 refresh token.
  final String refreshToken;

  /// Authenticated user ID.
  final String userId;

  /// Unmodifiable set of roles assigned to the user.
  final Set<String> roles;

  /// UTC timestamp when this session expires.
  final DateTime expiresAt;

  /// Returns `true` if this session has expired relative to [now].
  ///
  /// Defaults to [DateTime.now] in UTC if [now] is not provided.
  bool isExpired({DateTime? now}) =>
      (now ?? DateTime.now().toUtc()).isAfter(expiresAt);

  /// Returns a copy of this session with the given fields replaced.
  Session copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return Session(
      id: id,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId,
      roles: roles,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// In-memory session store with TTL-based expiration and injectable clock.
class SessionStore {
  SessionStore({
    Duration ttl = const Duration(hours: 1),
    DateTime Function()? clock,
  }) : _ttl = ttl,
       _clock = clock ?? _defaultClock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  final Duration _ttl;
  final DateTime Function() _clock;
  final Map<String, Session> _sessions = {};
  final Random _random = Random.secure();

  /// Creates a new session and returns its cryptographically random ID.
  String create({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required Set<String> roles,
  }) {
    final id = _generateId();
    final now = _clock();
    _sessions[id] = Session(
      id: id,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      roles: roles,
      expiresAt: now.add(_ttl),
    );
    return id;
  }

  /// Retrieves a session by [sessionId].
  ///
  /// Returns `null` if the session does not exist or has expired.
  Session? get(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return null;

    if (session.isExpired(now: _clock())) {
      _sessions.remove(sessionId);
      return null;
    }

    return session;
  }

  /// Updates tokens for an existing, non-expired session (e.g. after a token
  /// refresh) and extends the session TTL.
  ///
  /// Returns `true` if the session was updated, `false` if not found or expired.
  bool updateTokens(
    String sessionId, {
    required String accessToken,
    required String refreshToken,
  }) {
    final session = _sessions[sessionId];
    if (session == null) return false;

    if (session.isExpired(now: _clock())) {
      _sessions.remove(sessionId);
      return false;
    }

    _sessions[sessionId] = session.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: _clock().add(_ttl),
    );
    return true;
  }

  /// Destroys a session by [sessionId].
  void destroy(String sessionId) {
    _sessions.remove(sessionId);
  }

  /// Removes all expired sessions from the store.
  void destroyExpired() {
    final now = _clock();
    _sessions.removeWhere((_, session) => session.isExpired(now: now));
  }

  /// Generates a 32-byte cryptographically secure random hex string.
  String _generateId() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
