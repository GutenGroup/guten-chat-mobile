import 'package:flutter/material.dart';
import 'package:guten_chat/guten_chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace with your Supabase project credentials.
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://your-project.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'your-anon-key',
    ),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guten Chat Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: GutenChat(
        supabase: Supabase.instance.client,
        profileLookup: _profileLookup,
        features: ChatFeatures.resolve(
          reactions: true,
          brandReactions: true,
          tipping: true,
          paymentRequests: true,
          paidGroups: true,
        ),
        brandMarks: const [
          BrandReactionMark(
            id: 'bolt',
            label: 'Bolt',
            emojiFallback: '⚡',
          ),
        ],
      ),
    );
  }
}

Future<ChatProfile> _profileLookup(String profileId) async {
  // Host apps resolve profile display data from their own tables/services.
  return ChatProfile(
    name: 'User ${profileId.substring(0, 6)}',
    avatarUrl: null,
  );
}
