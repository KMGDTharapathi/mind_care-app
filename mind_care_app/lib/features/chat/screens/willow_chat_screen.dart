import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/willow_engine.dart';
import '../services/willow_api_service.dart';
import 'package:mind_care_app/main.dart' show appLanguage;

const _kTeal = Color(0xFF5BA8A0);
const _kDarkTeal = Color(0xFF1A4A4A);
const _kBg = Color(0xFFF0F9F9);
const _kUserBubble = Color(0xFFDCF8C6);
const _kWillowBubble = Colors.white;

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
      _addWillowMessage(_engine.welcomeMessage());
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

  void _addWillowMessage(String text) {
    final msg = ChatMessage.text(
      id: _uuid.v4(),
      sender: MessageSender.willow,
      text: text,
      timestamp: DateTime.now(),
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
    final bg = isDark ? const Color(0xFF0D1A1A) : _kBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, isSi),
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
                      return _TypingIndicator();
                    }
                    return _MessageBubble(
                      message: _messages[index],
                      isDark: isDark,
                    );
                  },
                ),
                if (_showScrollDown)
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: FloatingActionButton.small(
                      backgroundColor: _kTeal,
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
            onSend: _sendText,
            onAttach: _pickAttachment,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, bool isSi) {
    return AppBar(
      backgroundColor: _kTeal,
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
  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final bubbleColor = isUser
        ? (isDark ? const Color(0xFF1B5E20) : _kUserBubble)
        : (isDark ? const Color(0xFF1E3535) : _kWillowBubble);
    final textColor = isDark ? Colors.white : _kDarkTeal;
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
                  _buildContent(textColor),
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
                        Icon(Icons.done_all_rounded, size: 13, color: _kTeal),
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

  Widget _buildContent(Color textColor) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
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
                color: _kTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.insert_drive_file_outlined,
                color: _kTeal,
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

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
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
                        color: _kTeal.withValues(alpha: opacity),
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
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.isDark,
    required this.isSinhala,
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
              color: _kTeal,
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
                  style: TextStyle(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: isSinhala
                        ? 'පණිවිඩයක් ටයිප් කරන්න...'
                        : 'Type a message...',
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
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
                  ? _SendBtn(key: const ValueKey('send'), onTap: onSend)
                  : _MicBtn(key: const ValueKey('mic')),
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
  const _SendBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MicBtn extends StatelessWidget {
  const _MicBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
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
