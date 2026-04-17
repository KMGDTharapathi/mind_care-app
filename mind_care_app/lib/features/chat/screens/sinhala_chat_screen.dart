import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/features/chat/bloc/sinhala_chat_bloc.dart';
import 'package:mind_care_app/features/chat/models/chat_message.dart';
import 'package:mind_care_app/features/chat/widgets/crisis_alert_banner.dart';
import 'package:mind_care_app/services/chat/sinhala_chat_service.dart';

class SinhalaChatScreen extends StatelessWidget {
  const SinhalaChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SinhalaChatBloc(
        service: SinhalaChatService(
          // TODO: Replace with your actual API URL and token
          baseUrl: 'https://your-api-server.com',
          bearerToken: 'your-bearer-token',
        ),
      ),
      child: const _SinhalaChatView(),
    );
  }
}

class _SinhalaChatView extends StatefulWidget {
  const _SinhalaChatView();

  @override
  State<_SinhalaChatView> createState() => _SinhalaChatViewState();
}

class _SinhalaChatViewState extends State<_SinhalaChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<SinhalaChatBloc>().add(SendMessageEvent(text));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Willow - සිංහල'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
            onPressed: () => context.read<SinhalaChatBloc>().add(ClearChatEvent()),
          ),
        ],
      ),
      body: BlocConsumer<SinhalaChatBloc, SinhalaChatState>(
        listener: (context, state) {
          if (state is! SinhalaChatLoading) _scrollToBottom();
        },
        builder: (context, state) {
          return Column(
            children: [
              // Crisis banner
              if (state.crisisDetected) const CrisisAlertBanner(),

              // Messages list
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) =>
                            _MessageBubble(message: state.messages[index]),
                      ),
              ),

              // Error banner
              if (state is SinhalaChatError)
                _ErrorBanner(
                  message: state.errorMessage,
                  onRetry: () {
                    final lastUser = state.messages.lastWhere(
                      (m) => m.sender == MessageSender.user,
                      orElse: () => state.messages.last,
                    );
                    context.read<SinhalaChatBloc>().add(SendMessageEvent(lastUser.content));
                  },
                ),

              // Loading indicator
              if (state is SinhalaChatLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Willow is typing...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),

              // Input bar
              _InputBar(
                controller: _controller,
                onSend: () => _send(context),
                enabled: state is! SinhalaChatLoading,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'ආයුබෝවන්! මම Willow.\nඔබට කොහොමද?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryLight : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: 'ඔබේ හැඟීම් බෙදා ගන්න...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: enabled ? AppColors.primaryLight : Colors.grey.shade300,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: enabled ? onSend : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
