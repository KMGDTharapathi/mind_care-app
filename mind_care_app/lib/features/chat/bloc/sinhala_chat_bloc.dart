import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/features/chat/models/chat_message.dart';
import 'package:mind_care_app/services/chat/sinhala_chat_service.dart';
import 'package:uuid/uuid.dart';

// --- Events ---
abstract class SinhalaChatEvent extends Equatable {
  const SinhalaChatEvent();
  @override List<Object?> get props => [];
}

class SendMessageEvent extends SinhalaChatEvent {
  final String text;
  const SendMessageEvent(this.text);
  @override List<Object?> get props => [text];
}

class ClearChatEvent extends SinhalaChatEvent {}

// --- States ---
abstract class SinhalaChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool crisisDetected;
  const SinhalaChatState({required this.messages, this.crisisDetected = false});
  @override List<Object?> get props => [messages, crisisDetected];
}

class SinhalaChatIdle extends SinhalaChatState {
  const SinhalaChatIdle({required super.messages, super.crisisDetected});
}

class SinhalaChatLoading extends SinhalaChatState {
  const SinhalaChatLoading({required super.messages, super.crisisDetected});
}

class SinhalaChatError extends SinhalaChatState {
  final String errorMessage;
  const SinhalaChatError({required super.messages, required this.errorMessage, super.crisisDetected});
  @override List<Object?> get props => [messages, errorMessage, crisisDetected];
}

// --- BLoC ---
class SinhalaChatBloc extends Bloc<SinhalaChatEvent, SinhalaChatState> {
  final SinhalaChatService _service;
  final _uuid = const Uuid();

  SinhalaChatBloc({required SinhalaChatService service})
      : _service = service,
        super(const SinhalaChatIdle(messages: [])) {
    on<SendMessageEvent>(_onSend);
    on<ClearChatEvent>(_onClear);
  }

  Future<void> _onSend(SendMessageEvent event, Emitter<SinhalaChatState> emit) async {
    final userMsg = ChatMessage.text(
      id: _uuid.v4(),
      sender: MessageSender.user,
      text: event.text,
      timestamp: DateTime.now(),
    );
    final updatedMessages = [...state.messages, userMsg];
    emit(SinhalaChatLoading(messages: updatedMessages, crisisDetected: state.crisisDetected));

    try {
      final response = await _service.sendMessage(event.text);
      final botMsg = ChatMessage.text(
        id: _uuid.v4(),
        sender: MessageSender.willow,
        text: response.response,
        timestamp: DateTime.now(),
      );
      emit(SinhalaChatIdle(
        messages: [...updatedMessages, botMsg],
        crisisDetected: response.crisisDetected,
      ));
    } catch (e) {
      emit(SinhalaChatError(
        messages: updatedMessages,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        crisisDetected: state.crisisDetected,
      ));
    }
  }

  void _onClear(ClearChatEvent event, Emitter<SinhalaChatState> emit) {
    _service.clearHistory();
    emit(const SinhalaChatIdle(messages: []));
  }

  @override
  Future<void> close() {
    _service.dispose();
    return super.close();
  }
}
