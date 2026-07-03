/// Guten Chat Mobile — public API barrel.
///
/// Drop [GutenChat] into a host Flutter app with a configured [SupabaseClient]
/// and a [ProfileLookup] callback. Talks to the same `chat_*` Supabase schema
/// as Guten Chat Web (@gutengroup/chat-*).
library guten_chat;

export 'src/domain/models/chat_features.dart';
export 'src/domain/models/conversation.dart';
export 'src/domain/models/message.dart';
export 'src/domain/models/message_attachment.dart';
export 'src/domain/models/participant.dart';
export 'src/domain/models/payment_request.dart';
export 'src/domain/models/profile.dart';
export 'src/domain/models/reaction.dart';
export 'src/domain/models/tip.dart';
export 'src/domain/models/tip_presets.dart';
export 'src/domain/repositories/chat_repository.dart';
export 'src/presentation/theme/chat_theme.dart';
export 'src/presentation/widgets/groups/group_icon_mark.dart';
export 'src/presentation/widgets/groups/group_icon_picker.dart';
export 'src/presentation/widgets/guten_chat.dart';
export 'src/presentation/widgets/shell/liquid_glass_bottom_bar.dart';
