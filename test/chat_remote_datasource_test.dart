import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/data/datasources/chat_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late ChatRemoteDataSource dataSource;

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = ChatRemoteDataSource(client);
  });

  group('getCurrentProfileId', () {
    test('falls back to auth uid when the host lacks the RPC', () async {
      when(() => client.rpc('chat_current_profile_id')).thenThrow(
        const PostgrestException(
          message:
              'Could not find the function public.chat_current_profile_id',
          code: 'PGRST202',
        ),
      );
      when(() => auth.currentUser).thenReturn(
        const User(
          id: 'auth-uid-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00Z',
        ),
      );

      expect(await dataSource.getCurrentProfileId(), 'auth-uid-123');
    });

    test('throws StateError when the RPC is missing and unauthenticated',
        () async {
      when(() => client.rpc('chat_current_profile_id')).thenThrow(
        const PostgrestException(message: 'missing', code: 'PGRST202'),
      );
      when(() => auth.currentUser).thenReturn(null);

      expect(dataSource.getCurrentProfileId(), throwsStateError);
    });
  });
}
