import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_style.dart';
import '../models/wellness_feature.dart';
import '../services/chat_mood.dart';
import '../services/willow_engine.dart';
import '../services/willow_api_service.dart';
import '../../settings/bloc/settings_cubit.dart';
import 'package:mind_care_app/main.dart' show appLanguage;

const _kTeal = Color(0xFF5BA8A0);
const _kDarkTeal = Color(0xFF1A4A4A);

class WillowChatScreen extends StatefulWidget {
  final String lang;
  const WillowChatScreen({super.key, this.lang = 'en'});

  @override
  State<WillowChatScreen> createState() => _WillowChatScreenState();
}

class _WillowChatScreenState extends State<WillowChatScreen>
    with TickerProviderStateMixin {
  final _messages = <ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  bool _isTyping = false;
  bool _showScrollDown = false;
  bool _hasText = false;

  late WillowEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = WillowEngine(isSinhala: appLanguage.value.isSinhala);
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _scrollController.addListener(() {
      final atBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 80;
      if (!atBottom && !_showScrollDown) {
        setState(() => _showScrollDown = true);
      } else if (atBottom && _showScrollDown) {
        setState(() => _showScrollDown = false);
      }
    });
    // Welcome message
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _addWillowMessage(WillowReply(text: _engine.welcomeMessage()));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _addWillowMessage(WillowReply reply) {
    final msg = ChatMessage.text(
      id: _uuid.v4(),
      sender: MessageSender.willow,
      text: reply.text,
      timestamp: DateTime.now(),
      recommendations: reply.recommendations,
    );
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final userMsg = ChatMessage.text(
      id: _uuid.v4(),
      sender: MessageSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    final response = await _engine.respond(userMsg);
    if (!mounted) return;
    setState(() => _isTyping = false);
    _addWillowMessage(response);
  }

  Future<void> _pickAttachment() async {
    final isSi = appLanguage.value.isSinhala;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.image_outlined, color: _kTeal),
              ),
              title: Text(isSi ? 'ඡායාරූප / රූපය' : 'Photo / Image'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(
                  Icons.attach_file_rounded,
                  color: Color(0xFF1565C0),
                ),
              ),
              title: Text(isSi ? 'ගොනුව' : 'File'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'image') {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );
      if (file == null || file.path == null) return;

      final userMsg = ChatMessage.image(
        id: _uuid.v4(),
        filePath: file.path!,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMsg);
        _isTyping = true;
      });
      _scrollToBottom();
      final response = await _engine.respond(userMsg);
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addWillowMessage(response);
    } else {
      final file = await FilePicker.pickFile();
      if (file == null || file.path == null) return;

      final userMsg = ChatMessage.file(
        id: _uuid.v4(),
        filePath: file.path!,
        fileName: file.name,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMsg);
        _isTyping = true;
      });
      _scrollToBottom();
      final response = await _engine.respond(userMsg);
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addWillowMessage(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSi = appLanguage.value.isSinhala;
    final settings = context.watch<SettingsCubit>().state;
    final chatTheme = ChatTheme.fromId(settings.chatTheme);
    final chatFont = ChatFont.fromId(settings.chatFont);
    final accent = chatTheme.accent(isDark);
    final bg = isDark ? chatTheme.backgroundDark : chatTheme.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, isSi, chatTheme, chatFont),
      body: Column(
        children: [
          // API config banner — shown when ngrok URL not set
          if (!WillowApiService.isConfigured)
            _ApiConfigBanner(
              isSinhala: isSi,
              onConfigured: () => setState(() {}),
            ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _TypingIndicator(accent: accent);
                    }
                    return _MessageBubble(
                      message: _messages[index],
                      isDark: isDark,
                      accent: accent,
                      fontFamily: chatFont.family,
                      userLight: chatTheme.userBubbleLight,
                      userDark: chatTheme.userBubbleDark,
                    );
                  },
                ),
                if (_showScrollDown)
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: FloatingActionButton.small(
                      backgroundColor: accent,
                      onPressed: () => _scrollToBottom(),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _InputBar(
            controller: _textController,
            hasText: _hasText,
            isDark: isDark,
            isSinhala: isSi,
            accent: accent,
            fontFamily: chatFont.family,
            onSend: _sendText,
            onAttach: _pickAttachment,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    bool isDark,
    bool isSi,
    ChatTheme theme,
    ChatFont font,
  ) {
    final headerColor = theme.header(isDark);
    return AppBar(
      backgroundColor: headerColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          _WillowAvatar(size: 36),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Willow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                isSi ? 'ඔබේ සෞඛ්‍ය සහකාරිය 🌿' : 'Your wellness companion 🌿',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Pick chat theme + font face
        IconButton(
          tooltip: isSi ? 'තේමාව සහ අකුරු' : 'Chat theme & font',
          icon: const Icon(Icons.palette_outlined),
          color: Colors.white,
          onPressed: () => _showStyleSheet(isSi, theme, font),
        ),
        // Tap to update API URL
        GestureDetector(
          onTap: () {
            final banner = _ApiConfigBanner(
              isSinhala: isSi,
              onConfigured: () => setState(() {}),
            );
            banner._showConfigDialog(context);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: WillowApiService.isConfigured
                        ? const Color(0xFF69F0AE)
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  WillowApiService.isConfigured
                      ? (isSi ? 'සබැඳිව' : 'Online')
                      : (isSi ? 'සකසන්න' : 'Setup'),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStyleSheet(bool isSi, ChatTheme currentTheme, ChatFont currentFont) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChatStyleSheet(
        isSinhala: isSi,
        currentTheme: currentTheme.id,
        currentFont: currentFont.id,
      ),
    );
  }
}

// ── Willow Avatar ─────────────────────────────────────────────────────────────

class _WillowAvatar extends StatelessWidget {
  final double size;
  const _WillowAvatar({this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4DB6AC),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(size * 0.1),
                  SizedBox(width: size * 0.15),
                  _dot(size * 0.1),
                ],
              ),
              SizedBox(height: size * 0.06),
              Container(
                width: size * 0.28,
                height: size * 0.06,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          Positioned(
            top: -size * 0.08,
            right: size * 0.1,
            child: Icon(
              Icons.eco_rounded,
              color: const Color(0xFF2E7D32),
              size: size * 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double s) => Container(
    width: s,
    height: s,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final Color accent;
  final String? fontFamily;
  final Color userLight;
  final Color userDark;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.accent,
    this.fontFamily,
    required this.userLight,
    required this.userDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final mood = isUser
        ? ChatMood.neutral
        : ChatMoodDetector.detect(
            message.content,
            isSinhala: appLanguage.value.isSinhala,
          );
    final palette = ChatMoodDetector.paletteFor(mood);
    final bubbleColor = isUser
        ? (isDark ? userDark : userLight)
        : (isDark ? palette.bubbleDark : palette.bubbleLight);
    final textColor = isUser
        ? (isDark ? Colors.white : _kDarkTeal)
        : (isDark ? palette.textDark : palette.textLight);
    final accentColor = isUser ? accent : palette.accent;
    final timeColor = isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_WillowAvatar(size: 28), const SizedBox(width: 6)],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(textColor, accentColor),
                  if (!isUser && message.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _RecommendationChips(
                      recommendations: message.recommendations,
                      isDark: isDark,
                      accent: accent,
                      fontFamily: fontFamily,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 10, color: timeColor),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.done_all_rounded, size: 13, color: accent),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildContent(Color textColor, Color accentColor) {
    switch (message.type) {
      case MessageType.text:
        return _StyledMessageText(
          text: message.content,
          textColor: textColor,
          accentColor: accentColor,
          isUser: message.sender == MessageSender.user,
          isDark: isDark,
          fontFamily: fontFamily,
        );
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(message.content),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 100,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.grey,
              ),
            ),
          ),
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.fileName ?? 'File',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.voice:
        return _VoiceBubble(message: message, textColor: textColor);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Voice Bubble ──────────────────────────────────────────────────────────────

class _VoiceBubble extends StatelessWidget {
  final ChatMessage message;
  final Color textColor;
  const _VoiceBubble({required this.message, required this.textColor});

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _kTeal, shape: BoxShape.circle),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waveform placeholder
              Row(
                children: List.generate(
                  18,
                  (i) => Container(
                    width: 3,
                    height: (4 + (i % 5) * 4).toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(message.durationSeconds),
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Recommendation Chips ──────────────────────────────────────────────────────

class _RecommendationChips extends StatelessWidget {
  final List<String> recommendations;
  final bool isDark;
  final Color accent;
  final String? fontFamily;

  const _RecommendationChips({
    required this.recommendations,
    required this.isDark,
    required this.accent,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final isSinhala = appLanguage.value.isSinhala;
    final features = recommendations
        .map((id) => WellnessFeature.all[id])
        .whereType<WellnessFeature>()
        .toList();
    if (features.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSinhala ? 'ඔබට ගැළපෙන දේ:' : 'Suggested for you:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : accent,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: features.map((feature) {
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => feature.open(context),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2E4A4A)
                          : const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(feature.icon, size: 14, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          feature.label(isSinhala),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accent,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final Color accent;
  const _TypingIndicator({required this.accent});
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WillowAvatar(size: 28),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3535) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                    final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                        .clamp(0.3, 1.0);
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isDark;
  final bool isSinhala;
  final Color accent;
  final String? fontFamily;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.isDark,
    required this.isSinhala,
    required this.accent,
    this.fontFamily,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    final barBg = isDark ? const Color(0xFF1A2A2A) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF243333) : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : _kDarkTeal;

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach button
            _IconBtn(
              icon: Icons.attach_file_rounded,
              color: accent,
              onTap: onAttach,
            ),
            const SizedBox(width: 6),
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontFamily: fontFamily,
                  ),
                  decoration: InputDecoration(
                    hintText: isSinhala
                        ? 'පණිවිඩයක් ටයිප් කරන්න...'
                        : 'Type a message...',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 14,
                      fontFamily: fontFamily,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Send / mic button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: hasText
                  ? _SendBtn(
                      key: const ValueKey('send'),
                      accent: accent,
                      onTap: onSend,
                    )
                  : const SizedBox(
                      key: ValueKey('empty'),
                      width: 44,
                      height: 44,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Color accent;
  const _SendBtn({super.key, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── API Config Banner ─────────────────────────────────────────────────────────

class _ApiConfigBanner extends StatelessWidget {
  final bool isSinhala;
  final VoidCallback onConfigured;
  const _ApiConfigBanner({required this.isSinhala, required this.onConfigured});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showConfigDialog(context),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFFFF8E1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF795548),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSinhala
                    ? 'AI model URL සකසන්න — ස්පර්ශ කරන්න'
                    : 'Tap to connect your LLaMA model',
                style: const TextStyle(fontSize: 12, color: Color(0xFF795548)),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFF795548),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfigDialog(BuildContext context) {
    final ctrl = TextEditingController(text: WillowApiService.baseUrl);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Connect Willow AI',
          style: TextStyle(color: _kDarkTeal, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Run Cell 10 in your Colab notebook\n'
              '2. Copy the ngrok URL it prints\n'
              '3. Paste it below',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'https://xxxx.ngrok-free.app',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                WillowApiService.setBaseUrl(url);
                Navigator.pop(context);
                onConfigured();
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

// ── Styled Message Text with Colorful Formatting ──────────────────────────────

class _StyledMessageText extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color accentColor;
  final bool isUser;
  final bool isDark;
  final String? fontFamily;

  const _StyledMessageText({
    required this.text,
    required this.textColor,
    required this.accentColor,
    required this.isUser,
    required this.isDark,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    // Accent colors derived from the mood palette so quotes/bullets match the
    // bubble's color instead of always using the brand teal.
    final primaryColor = accentColor;
    final base = accentColor;
    final accentColors = <Color>[
      base,
      base.withValues(alpha: 0.85),
      base.withValues(alpha: 0.7),
      base.withValues(alpha: 0.6),
      base.withValues(alpha: 0.5),
    ];

    // Parse markdown-like formatting for emphasis
    final segments = _parseSegments(text);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          height: 1.5,
          fontFamily: fontFamily,
        ),
        children: segments.map((seg) {
          Color segColor = textColor;
          FontWeight weight = FontWeight.normal;
          FontStyle style = FontStyle.normal;
          double size = 14;

          switch (seg.type) {
            case _SegmentType.bold:
              weight = FontWeight.bold;
              segColor = isUser ? Colors.white : primaryColor;
              break;
            case _SegmentType.italic:
              style = FontStyle.italic;
              segColor = textColor.withValues(alpha: 0.85);
              break;
            case _SegmentType.highlight:
              return WidgetSpan(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    seg.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : primaryColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              );
            case _SegmentType.emoji:
              size = 18;
              break;
            case _SegmentType.quote:
              return WidgetSpan(
                child: Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4, left: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColors[math.Random().nextInt(accentColors.length)].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColors[math.Random().nextInt(accentColors.length)].withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    seg.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: textColor.withValues(alpha: 0.85),
                      height: 1.4,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              );
            case _SegmentType.listItem:
              return WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColors[math.Random().nextInt(accentColors.length)],
                          shape: BoxShape.circle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                            seg.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              height: 1.4,
                              fontFamily: fontFamily,
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              );
            case _SegmentType.normal:
              break;
          }

          return TextSpan(
            text: seg.text,
            style: TextStyle(
              fontSize: size,
              fontWeight: weight,
              fontStyle: style,
              color: segColor,
              height: 1.5,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_TextSegment> _parseSegments(String input) {
    final segments = <_TextSegment>[];
    // Fixed regex: removed invalid emoji range, using separate emoji detection
    final regex = RegExp(r'(\*\*.*?\*\*|__.*?__|\*.*?\*|_.*?_|`.*?`|>.*?(?=\n|$)|\n[-•]\s.*?(?=\n|$))');
    int lastEnd = 0;

    for (final match in regex.allMatches(input)) {
      if (match.start > lastEnd) {
        segments.add(_TextSegment(
          text: input.substring(lastEnd, match.start),
          type: _SegmentType.normal,
        ));
      }

      final matched = match.group(0)!;
      _SegmentType type;
      String displayText = matched;

      if (matched.startsWith('**') && matched.endsWith('**')) {
        type = _SegmentType.bold;
        displayText = matched.substring(2, matched.length - 2);
      } else if (matched.startsWith('__') && matched.endsWith('__')) {
        type = _SegmentType.bold;
        displayText = matched.substring(2, matched.length - 2);
      } else if (matched.startsWith('*') && matched.endsWith('*') && matched.length > 2) {
        type = _SegmentType.italic;
        displayText = matched.substring(1, matched.length - 1);
      } else if (matched.startsWith('_') && matched.endsWith('_') && matched.length > 2) {
        type = _SegmentType.italic;
        displayText = matched.substring(1, matched.length - 1);
      } else if (matched.startsWith('`') && matched.endsWith('`')) {
        type = _SegmentType.highlight;
        displayText = matched.substring(1, matched.length - 1);
      } else if (matched.startsWith('>')) {
        type = _SegmentType.quote;
        displayText = matched.substring(1).trim();
      } else if (matched.startsWith('\n-') || matched.startsWith('\n•')) {
        type = _SegmentType.listItem;
        displayText = matched.substring(2).trim();
      } else {
        type = _SegmentType.normal;
      }

      segments.add(_TextSegment(text: displayText, type: type));
      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      // Check remaining text for emojis
      final remaining = input.substring(lastEnd);
      // Emoji range: \u{1F600}-\u{1F64F} (emoticons)
      final emojiRegex = RegExp(r'[\uD83D[\uDE00-\uDE4F]]');
      int emojiLastEnd = 0;
      for (final emojiMatch in emojiRegex.allMatches(remaining)) {
        if (emojiMatch.start > emojiLastEnd) {
          segments.add(_TextSegment(
            text: remaining.substring(emojiLastEnd, emojiMatch.start),
            type: _SegmentType.normal,
          ));
        }
        segments.add(_TextSegment(
          text: emojiMatch.group(0)!,
          type: _SegmentType.emoji,
        ));
        emojiLastEnd = emojiMatch.end;
      }
      if (emojiLastEnd < remaining.length) {
        segments.add(_TextSegment(
          text: remaining.substring(emojiLastEnd),
          type: _SegmentType.normal,
        ));
      }
    }

    return segments;
  }
}

enum _SegmentType {
  normal,
  bold,
  italic,
  highlight,
  emoji,
  quote,
  listItem,
}

class _TextSegment {
  final String text;
  final _SegmentType type;

  const _TextSegment({required this.text, required this.type});
}

// ── Chat Theme & Font Picker ─────────────────────────────────────────────────

class _ChatStyleSheet extends StatelessWidget {
  final bool isSinhala;
  final String currentTheme;
  final String currentFont;

  const _ChatStyleSheet({
    required this.isSinhala,
    required this.currentTheme,
    required this.currentFont,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSinhala ? 'චැට් පෙනුම' : 'Chat look',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isSinhala ? 'තේමාව තෝරන්න' : 'Choose a theme',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: ChatTheme.byId.values.map((theme) {
                final selected = theme.id == currentTheme;
                return GestureDetector(
                  onTap: () => cubit.setChatTheme(theme.id),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.accentLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.grey.shade900
                                : Colors.grey.shade300,
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSinhala ? theme.siName : theme.enName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              isSinhala ? 'අකුරු (font) තෝරන්න' : 'Choose a font',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            ...ChatFont.byId.values.map((font) {
              final selected = font.id == currentFont;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => cubit.setChatFont(font.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? themeAccent(context).withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? themeAccent(context)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isSinhala ? font.siName : font.enName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontFamily: font.family,
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_rounded,
                            color: themeAccent(context),
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              isSinhala
                  ? 'අකුරු ආකෘතිය පණිවිඩවලට යොදවයි'
                  : 'Font face applies to the messages',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color themeAccent(BuildContext context) =>
      ChatTheme.fromId(currentTheme).accent(
        Theme.of(context).brightness == Brightness.dark,
      );
}
