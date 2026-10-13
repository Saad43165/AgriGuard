// chatbot_screen.dart
// Main AgriGuard AI chatbot screen

import 'dart:io';
import 'package:agriguard_fyp/features/chatbot/service/chatbot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:agriguard_fyp/features/advance_search_screen/service/plant_id_api_service.dart';
import 'chatbot_constants.dart';
import 'models/chatbot_models.dart';
import 'models/chatbot_storage.dart';
import 'widgets/chatbot_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  static final List<ChatMessage> _messages = [];
  static bool _isLoaded = false;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final PlantIdService _plantIdService = PlantIdService();

  bool _isLoading = false;
  bool _showScrollBtn = false;

  late AnimationController _fadeCtrl;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    )..forward();

    _scrollCtrl.addListener(_onScroll);
    _loadPersistedMessages();
  }

  Future<void> _loadPersistedMessages() async {
    if (_isLoaded) return; // Already loaded in this session
    final saved = await ChatStorageService.loadMessages();
    if (saved.isNotEmpty && mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(saved);
        _isLoaded = true;
      });
      _scrollToBottom(immediate: true);
    } else {
      _isLoaded = true;
    }
  }

  void _onScroll() {
    final atBottom = _scrollCtrl.hasClients &&
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset < 120;
    if (atBottom != !_showScrollBtn) {
      setState(() => _showScrollBtn = !atBottom);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool get _isUrduSession {
    final recentUserMsgs = _messages
        .where((m) => m.role == 'user')
        .toList()
        .reversed
        .take(3);
    return recentUserMsgs
        .any((m) => ChatbotConstants.isUrduText(m.content));
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration:
          immediate ? const Duration(milliseconds: 1) : const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _addMessage(ChatMessage msg) async {
    setState(() => _messages.add(msg));
    _scrollToBottom();
    await ChatStorageService.appendMessage(msg);
  }

  Future<void> _replaceLastBotMessage(ChatMessage msg) async {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
        _messages.removeLast();
      }
      _messages.add(msg);
    });
    _scrollToBottom();
    await ChatStorageService.saveMessages(_messages);
  }

  // ── Clear chat ─────────────────────────────────────────────────────────────
  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
          isDark ? AppColors.darkCard : AppColors.lightCard,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Clear Chat',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          content: Text(
            'This will delete all messages. Continue?',
            style: TextStyle(
              color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _messages.clear();
        _isLoaded = true;
      });
      await ChatStorageService.clearMessages();
    }
  }

  // ── Send text message ──────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = text.trim();
    _inputCtrl.clear();

    final isUrdu = ChatbotConstants.isUrduText(userMsg) || _isUrduSession;

    // Add user message
    await _addMessage(ChatMessage(
      role: 'user',
      content: userMsg,
      timestamp: DateTime.now(),
    ));

    setState(() => _isLoading = true);

    // Build context messages (last 20 for context window efficiency)
    final contextMsgs = _messages.length > 20
        ? _messages.sublist(_messages.length - 20)
        : List<ChatMessage>.from(_messages);

    // Try Groq AI first
    final aiReply = await ChatbotService.sendToGroq(contextMsgs);

    final replyContent = aiReply ??
        ChatbotService.localFallback(userMsg, isUrdu);

    setState(() => _isLoading = false);

    await _addMessage(ChatMessage(
      role: 'assistant',
      content: replyContent,
      timestamp: DateTime.now(),
      status: aiReply == null ? MessageStatus.sent : MessageStatus.sent,
    ));
  }

  // ── Image picker ───────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(isDark: Theme.of(ctx).brightness == Brightness.dark),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source == 0 ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 92,
      );
      if (image != null) {
        await _analyzeImage(image.path);
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  // ── Analyze image via Plant.id ─────────────────────────────────────────────
  Future<void> _analyzeImage(String imagePath) async {
    if (_isLoading) return;

    final isUrdu = _isUrduSession;

    await _addMessage(ChatMessage(
      role: 'user',
      content: isUrdu
          ? 'پودے کی تصویر بھیج رہا ہوں — تجزیہ کریں...'
          : 'Analyzing this plant image...',
      timestamp: DateTime.now(),
      imagePath: imagePath,
    ));

    setState(() => _isLoading = true);

    try {
      if (!_plantIdService.hasApiKey()) {
        throw Exception('Plant.id API key not configured');
      }

      final result =
      await _plantIdService.analyzeWithPlantId(File(imagePath));

      if (result['success'] == true) {
        final reply = _buildPlantIdReply(result, isUrdu);
        setState(() => _isLoading = false);
        await _addMessage(ChatMessage(
          role: 'assistant',
          content: reply,
          timestamp: DateTime.now(),
        ));
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await _addMessage(ChatMessage(
        role: 'assistant',
        content: isUrdu
            ? '⚠️ تجزیہ ناکام ہوا۔ براہ کرم دوبارہ کوشش کریں یا Advanced AI استعمال کریں۔\n\nخطا: $e'
            : '⚠️ Analysis failed. Please try again or use the Advanced AI scan feature.\n\nError: $e',
        timestamp: DateTime.now(),
        status: MessageStatus.error,
      ));
    }
  }

  String _buildPlantIdReply(Map<String, dynamic> result, bool isUrdu) {
    final data = result['data'] as Map<String, dynamic>? ?? result;
    final plantName = data['plantName'] as String? ?? 'Unknown';
    final scientificName = data['scientificName'] as String? ?? '';
    final diseaseName = data['diseaseName'] as String? ?? '';
    final confidence = (data['confidence'] ?? 0) as num;
    final diseaseConfidence = (data['diseaseConfidence'] ?? 0) as num;
    final severity = data['severity'] as String? ?? '';
    final symptoms =
        (data['symptoms'] as List<dynamic>?)?.cast<String>() ?? [];
    final remediation =
        (data['remediation'] as List<dynamic>?)?.cast<String>() ?? [];
    final precautions =
        (data['precautions'] as List<dynamic>?)?.cast<String>() ?? [];

    final isHealthy =
        diseaseName.isEmpty || diseaseName.toLowerCase() == 'healthy';
    final sb = StringBuffer();

    // Header
    sb.writeln('🌱 **${isUrdu ? 'تجزیہ کے نتائج' : 'Analysis Results'}**');
    sb.writeln();
    sb.writeln('🌿 ${isUrdu ? 'پودا:' : 'Plant:'} $plantName');
    if (scientificName.isNotEmpty) {
      sb.writeln(
          '🔬 ${isUrdu ? 'سائنسی نام:' : 'Scientific Name:'} $scientificName');
    }
    if (confidence > 0) {
      sb.writeln(
          '📊 ${isUrdu ? 'یقین:' : 'Confidence:'} $confidence%');
    }
    sb.writeln();

    if (isHealthy) {
      sb.writeln('✅ **${isUrdu ? 'پودا صحت مند ہے!' : 'Plant is Healthy!'}**');
      sb.writeln();
      sb.writeln(isUrdu
          ? '💡 **ٹپ:** پودے کی صحت برقرار رکھنے کے لیے باقاعدگی سے پانی دیں اور مٹی کی جانچ کریں۔'
          : '💡 **Tip:** Maintain plant health with regular watering and periodic soil testing.');
    } else {
      sb.writeln(
          '⚠️ **${isUrdu ? 'بیماری کا پتہ چلا:' : 'Disease Detected:'} $diseaseName**');
      if (diseaseConfidence > 0) {
        sb.writeln(
            '🎯 ${isUrdu ? 'بیماری کا یقین:' : 'Disease Confidence:'} $diseaseConfidence%');
      }
      if (severity.isNotEmpty && severity != 'Unknown') {
        sb.writeln(
            '📌 ${isUrdu ? 'شدت:' : 'Severity:'} $severity');
      }

      if (symptoms.isNotEmpty) {
        sb.writeln();
        sb.writeln('📋 **${isUrdu ? 'علامات:' : 'Symptoms:'}**');
        for (final s in symptoms.take(4)) {
          sb.writeln('• $s');
        }
      }

      if (remediation.isNotEmpty) {
        sb.writeln();
        sb.writeln('💊 **${isUrdu ? 'علاج:' : 'Treatment:'}**');
        for (int i = 0; i < remediation.length && i < 5; i++) {
          sb.writeln('${i + 1}. ${remediation[i]}');
        }
      }

      if (precautions.isNotEmpty) {
        sb.writeln();
        sb.writeln('🛡️ **${isUrdu ? 'احتیاطات:' : 'Precautions:'}**');
        for (final p in precautions.take(3)) {
          sb.writeln('• $p');
        }
      }

      sb.writeln();
      sb.writeln(
          '💡 **${isUrdu ? 'ٹپ:' : 'Tip:'}** ${isUrdu ? 'AgriGuard آن ڈیوائس اسکین سے فوری تشخیص بھی کر سکتے ہیں۔' : 'You can also use AgriGuard On-Device scan for supported plants.'}');
    }

    return sb.toString().trim();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
    isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final suggestions =
    ChatbotConstants.getSuggestions(t.isUrdu || _isUrduSession);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, surfaceColor, textPrimary, t),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeCtrl,
                  child: _buildMessageList(isDark, t),
                ),

                // Scroll to bottom button
                if (_showScrollBtn)
                  PositionedDirectional(
                    bottom: 12,
                    end: 16,
                    child: _ScrollToBottomBtn(
                      isDark: isDark,
                      onTap: _scrollToBottom,
                    ),
                  ),
              ],
            ),
          ),

          // Suggestions (only when no messages)
          if (_messages.isEmpty)
            SuggestionsRow(
              suggestions: suggestions,
              onTap: _sendMessage,
              isDark: isDark,
            ),

          ChatInputBar(
            controller: _inputCtrl,
            isLoading: _isLoading,
            isDark: isDark,
            hintText: t.isUrdu
                ? (t.get('chatbot_hint_ur'))
                : (t.get('chatbot_hint')),
            onSend: _sendMessage,
            onImageTap: _pickImage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      bool isDark,
      Color surfaceColor,
      Color textPrimary,
      TranslationService t,
      ) {
    return AppBar(
      backgroundColor: surfaceColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.primary,
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.get('chatbot_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t.get('chatbot_always_available'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Message count badge
        if (_messages.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_messages.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

        // Clear chat button
        if (_messages.isNotEmpty)
          IconButton(
            onPressed: _clearChat,
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
              size: 22,
            ),
            tooltip: ChatbotConstants.clearChatLabel(t.isUrdu),
          ),

        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isDark, TranslationService t) {
    // Compute items: optional welcome card + messages + optional loading
    final hasMessages = _messages.isNotEmpty;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount:
      (hasMessages ? 0 : 1) + _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Welcome card (when empty)
        if (!hasMessages && index == 0) {
          return WelcomeCard(
            isDark: isDark,
            title: t.get('chatbot_guidance_title'),
            description: t.get('chatbot_guidance_desc'),
            examples: t.get('chatbot_guidance_examples'),
          );
        }

        final msgIndex = index - (hasMessages ? 0 : 1);

        // Typing indicator
        if (msgIndex == _messages.length) {
          return TypingIndicator(isDark: isDark);
        }

        final msg = _messages[msgIndex];

        // Date divider logic
        Widget? divider;
        if (msgIndex == 0) {
          divider = DateDivider(date: msg.timestamp, isDark: isDark);
        } else {
          final prev = _messages[msgIndex - 1];
          final prevDate = DateTime(
              prev.timestamp.year, prev.timestamp.month, prev.timestamp.day);
          final currDate = DateTime(
              msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
          if (currDate != prevDate) {
            divider = DateDivider(date: msg.timestamp, isDark: isDark);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (divider != null) divider,
            MessageBubble(
              message: msg,
              isDark: isDark,
              showTimestamp: true,
            ),
          ],
        );
      },
    );
  }
}

// ── Image source bottom sheet ─────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final bool isDark;
  const _ImageSourceSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select Image Source',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Take a photo or choose from gallery',
            style: TextStyle(
              fontSize: 13,
              color:
              isDark ? AppColors.darkCaption : AppColors.lightCaption,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                subtitle: 'Take a photo',
                onTap: () => Navigator.pop(context, 0),
                isDark: isDark,
              ),
              _SourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                subtitle: 'Choose existing',
                onTap: () => Navigator.pop(context, 1),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scroll to bottom FAB ──────────────────────────────────────────────────────
class _ScrollToBottomBtn extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ScrollToBottomBtn({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}