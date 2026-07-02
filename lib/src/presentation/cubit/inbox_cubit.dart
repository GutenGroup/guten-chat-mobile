import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/conversation.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/chat_repository.dart';

class InboxState extends Equatable {
  const InboxState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.profileNames = const {},
  });

  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;
  final Map<String, ChatProfile> profileNames;

  InboxState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
    Map<String, ChatProfile>? profileNames,
  }) {
    return InboxState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profileNames: profileNames ?? this.profileNames,
    );
  }

  @override
  List<Object?> get props =>
      [conversations, isLoading, error, profileNames];
}

class InboxCubit extends Cubit<InboxState> {
  InboxCubit({
    required ChatRepository repository,
    required ProfileLookup profileLookup,
  })  : _repository = repository,
        _profileLookup = profileLookup,
        super(const InboxState(isLoading: true));

  final ChatRepository _repository;
  final ProfileLookup _profileLookup;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final conversations = await _repository.fetchConversations();
      final profiles = Map<String, ChatProfile>.from(state.profileNames);
      for (final conversation in conversations) {
        if (conversation.createdByProfileId != null &&
            !profiles.containsKey(conversation.createdByProfileId)) {
          profiles[conversation.createdByProfileId!] =
              await _safeLookup(conversation.createdByProfileId!);
        }
      }
      emit(
        state.copyWith(
          conversations: conversations,
          isLoading: false,
          profileNames: profiles,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<ChatProfile> _safeLookup(String profileId) async {
    try {
      return await _profileLookup(profileId);
    } catch (_) {
      return unknownProfile;
    }
  }
}
