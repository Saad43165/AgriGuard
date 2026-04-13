import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/widgets/app_themes.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  ChatMessage({required this.role, required this.content, required this.timestamp});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;
  late AnimationController _fadeCtrl;

  // Full AgriGuard knowledge base as system prompt
  static const String _systemPrompt = '''You are AgriGuard AI Assistant — a smart, friendly agricultural expert built into the AgriGuard mobile app.

## About AgriGuard App
AgriGuard is a Flutter mobile app for plant disease detection. It has:
- **On-Device Scan**: Uses TFLite ML models (plant species + disease detection + severity) — works offline, instant results
- **Advanced AI Scan**: Uses cloud APIs (Groq AI, Hugging Face Vision, Plant.id) for deeper analysis
- **Scan History**: Saves all scans locally (SQLite) and syncs to Firebase
- **Weather Card**: Shows local weather relevant to farming
- **PDF Reports**: Generate and share scan reports
- **11 Supported Plants**: Apple, Bell Pepper, Cherry, Corn, Grape, Peach, Potato, Soybean, Strawberry, Tomato, Wheat

## Supported Diseases (by plant)
- Apple: Apple Scab, Black Rot, Cedar Apple Rust
- Bell Pepper: Bacterial Spot
- Cherry: Powdery Mildew
- Corn: Cercospora Leaf Spot, Common Rust, Northern Leaf Blight
- Grape: Black Rot, Esca (Black Measles), Leaf Blight
- Peach: Bacterial Spot
- Potato: Early Blight, Late Blight
- Soybean: Bacterial Blight
- Strawberry: Leaf Scorch
- Tomato: Bacterial Spot, Early Blight, Late Blight, Septoria Leaf Spot, Yellow Leaf Curl Virus
- Wheat: Stripe Rust

## Your Role
1. Help users understand their scan results
2. Explain plant diseases, symptoms, causes, and treatments
3. Give actionable farming advice
4. Answer questions about the AgriGuard app features
5. Provide crop care, fertilization, and pest management tips
6. Support both English and Urdu (respond in the user's language)

## Response Style
- Be concise and practical
- Use bullet points for lists
- Always mention: symptoms, causes, treatment, prevention
- Be encouraging and supportive to farmers
- Keep responses under 200 words unless more detail is needed''';

  final List<String> _suggestions = [
    'What causes tomato blight?',
    'How to treat apple scab?',
    'Potato late blight signs?',
    'Best fungicide for rust?',
    'How to use AgriGuard?',
    'Wheat stripe rust cure?',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this)..forward();
    _messages.add(ChatMessage(
      role: 'assistant',
      content: 'Hello! I\'m AgriGuard AI 🌱\n\nI can help you with:\n• Plant disease identification & treatment\n• Understanding your scan results\n• Crop care & farming advice\n• How to use the AgriGuard app\n\nWhat would you like to know?',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    final userMsg = text.trim();
    _inputCtrl.clear();

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: userMsg, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    // Try Groq first (fast, free tier available)
    final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final groqModel = dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile';
    if (groqKey.isNotEmpty) {
      final success = await _tryGroq(groqKey, groqModel);
      if (success) return;
    }

    // Fallback: local rule-based responses
    _localFallback(userMsg);
  }

  Future<bool> _tryGroq(String apiKey, String model) async {
    try {
      // Build messages — skip welcome (index 0)
      final msgs = _messages.skip(1).map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...msgs,
          ],
          'max_tokens': 512,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(role: 'assistant', content: reply.trim(), timestamp: DateTime.now()));
            _isLoading = false;
          });
          _scrollToBottom();
        }
        return true;
      }
      debugPrint('Groq error: ${response.statusCode} — ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Groq exception: $e');
      return false;
    }
  }

  void _localFallback(String query) {
    final q = query.toLowerCase();
    String reply;

    if (q.contains('blight') || q.contains('late blight') || q.contains('early blight')) {
      reply = '**Blight Disease**\n\n'
          '• **Symptoms**: Dark brown lesions on leaves, water-soaked spots, rapid wilting\n'
          '• **Cause**: Fungal pathogens (Phytophthora, Alternaria)\n'
          '• **Treatment**: Apply copper-based fungicide, remove infected parts, improve drainage\n'
          '• **Prevention**: Avoid overhead watering, rotate crops, use resistant varieties\n\n'
          'Scan your plant with AgriGuard for a precise diagnosis!';
    } else if (q.contains('rust')) {
      reply = '**Rust Disease**\n\n'
          '• **Symptoms**: Orange/rust-colored pustules on leaf undersides, yellowing\n'
          '• **Cause**: Fungal rust pathogens (Puccinia, Phragmidium)\n'
          '• **Treatment**: Fungicides with myclobutanil or mancozeb, remove infected leaves\n'
          '• **Prevention**: Good air circulation, avoid wetting foliage, remove alternate hosts\n\n'
          'Use AgriGuard\'s On-Device scan to detect rust early!';
    } else if (q.contains('scab') || q.contains('apple scab')) {
      reply = '**Apple Scab**\n\n'
          '• **Symptoms**: Olive-green to black scabby lesions on leaves and fruit\n'
          '• **Cause**: Fungus Venturia inaequalis\n'
          '• **Treatment**: Apply fungicide at green tip stage, rake fallen leaves\n'
          '• **Prevention**: Choose scab-resistant varieties, prune for air circulation\n\n'
          'AgriGuard can detect Apple Scab with 90%+ accuracy!';
    } else if (q.contains('spot') || q.contains('leaf spot')) {
      reply = '**Leaf Spot Disease**\n\n'
          '• **Symptoms**: Small circular spots with yellow halos, spots may merge\n'
          '• **Cause**: Bacterial or fungal pathogens\n'
          '• **Treatment**: Apply appropriate fungicide/bactericide, prune affected areas\n'
          '• **Prevention**: Avoid overhead watering, remove debris, improve spacing\n\n'
          'Scan with AgriGuard to identify the exact type of leaf spot!';
    } else if (q.contains('scan') || q.contains('how to') || q.contains('use')) {
      reply = '**How to Use AgriGuard**\n\n'
          '1. **Tap the Scan button** (center of bottom nav)\n'
          '2. **Choose method**: On-Device (offline, fast) or Advanced AI (cloud, detailed)\n'
          '3. **Take/select a photo** of the affected leaf\n'
          '4. **View results**: Plant name, disease, severity, and treatment\n'
          '5. **Generate PDF** report to share with experts\n\n'
          'Tip: For best results, fill the frame with the leaf in good lighting!';
    } else if (q.contains('tomato')) {
      reply = '**Tomato Diseases in AgriGuard**\n\n'
          'Supported: Early Blight, Late Blight, Bacterial Spot, Septoria Leaf Spot, Yellow Leaf Curl Virus\n\n'
          '• **Early Blight**: Brown spots with concentric rings — use copper fungicide\n'
          '• **Late Blight**: Water-soaked lesions, white mold — act immediately\n'
          '• **Bacterial Spot**: Small dark spots — use copper bactericide\n\n'
          'Scan your tomato leaf now for instant diagnosis!';
    } else if (q.contains('potato')) {
      reply = '**Potato Diseases in AgriGuard**\n\n'
          'Supported: Early Blight, Late Blight\n\n'
          '• **Early Blight**: Dark spots with yellow halos — apply mancozeb\n'
          '• **Late Blight**: Gray-green water-soaked lesions — emergency treatment needed\n\n'
          'Late blight spreads rapidly — scan immediately if you suspect it!';
    } else if (q.contains('wheat')) {
      reply = '**Wheat Stripe Rust**\n\n'
          '• **Symptoms**: Yellow-orange stripes of pustules along leaf veins\n'
          '• **Cause**: Puccinia striiformis fungus\n'
          '• **Treatment**: Triazole fungicides (propiconazole, tebuconazole)\n'
          '• **Prevention**: Resistant varieties, early sowing, monitor regularly\n\n'
          'AgriGuard detects wheat stripe rust — scan your crop today!';
    } else if (q.contains('hello') || q.contains('hi') || q.contains('salam') || q.contains('السلام')) {
      reply = 'Hello! 👋 I\'m AgriGuard AI, your plant health assistant.\n\n'
          'I can help with:\n'
          '• Plant disease diagnosis & treatment\n'
          '• Crop care advice\n'
          '• How to use AgriGuard\n\n'
          'What plant issue can I help you with today?';
    } else if (q.contains('urdu') || q.contains('اردو') || q.contains('پاکستان')) {
      reply = 'میں اردو میں بھی مدد کر سکتا ہوں! 🌱\n\n'
          'AgriGuard آپ کی فصلوں کی بیماریوں کی تشخیص کرتا ہے۔\n\n'
          'آپ کے پودے میں کیا مسئلہ ہے؟ مجھے بتائیں!';
    } else if (q.contains('severity') || q.contains('serious') || q.contains('bad')) {
      reply = '**Disease Severity Levels in AgriGuard**\n\n'
          '• 🟢 **None/Healthy**: Plant is healthy, continue regular care\n'
          '• 🔵 **Low**: Early stage, apply preventive treatment\n'
          '• 🟡 **Medium**: Moderate infection, begin treatment now\n'
          '• 🟠 **High**: Severe infection, immediate action required\n'
          '• 🔴 **Critical**: Emergency — isolate plant, consult expert\n\n'
          'AgriGuard automatically assesses severity from your scan!';
    } else if (q.contains('fungicide') || q.contains('pesticide') || q.contains('treatment') || q.contains('cure')) {
      reply = '**General Treatment Guidelines**\n\n'
          '• **Fungal diseases**: Copper-based fungicides, mancozeb, triazoles\n'
          '• **Bacterial diseases**: Copper bactericides, streptomycin\n'
          '• **Viral diseases**: Control insect vectors, remove infected plants\n'
          '• **General**: Remove infected parts, improve air circulation, avoid overhead watering\n\n'
          '⚠️ Always follow label instructions and local regulations.\n'
          'Scan with AgriGuard first to identify the exact disease!';
    } else {
      reply = 'I\'m here to help with plant diseases and AgriGuard! 🌿\n\n'
          'Try asking me about:\n'
          '• A specific disease (e.g., "tomato blight treatment")\n'
          '• A specific plant (e.g., "apple diseases")\n'
          '• How to use AgriGuard features\n'
          '• Severity levels and what they mean\n\n'
          'Or just scan your plant with AgriGuard for instant AI diagnosis!';
    }

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now()));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF);
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AgriGuard AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Always available', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: borderColor)),
      ),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _TypingIndicator(isDark: isDark);
                  return _MessageBubble(message: _messages[index], isDark: isDark);
                },
              ),
            ),
          ),
          if (_messages.length <= 2)
            _SuggestionsRow(suggestions: _suggestions, onTap: _sendMessage, isDark: isDark),
          _InputBar(controller: _inputCtrl, isLoading: _isLoading, isDark: isDark, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 14, height: 1.5,
                  color: isUser ? Colors.white : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 30, height: 30,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)),
            border: Border.all(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
              final val = ((_ctrl.value + i * 0.33) % 1.0);
              final scale = 0.6 + (val < 0.5 ? val * 0.8 : (1 - val) * 0.8);
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(scale: scale,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.7), shape: BoxShape.circle))));
            })),
          ),
        ),
      ]),
    );
  }
}

class _SuggestionsRow extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  final bool isDark;
  const _SuggestionsRow({required this.suggestions, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onTap(suggestions[i]); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(suggestions[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isDark;
  final void Function(String) onSend;
  const _InputBar({required this.controller, required this.isLoading, required this.isDark, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TextField(
              controller: controller,
              maxLines: 4, minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
              decoration: InputDecoration(
                hintText: 'Ask about plant diseases...',
                hintStyle: TextStyle(color: isDark ? AppColors.darkCaption : AppColors.lightCaption, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: isLoading ? null : onSend,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: isLoading ? null : () => onSend(controller.text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: isLoading ? null : const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              color: isLoading ? (isDark ? AppColors.darkCard : AppColors.lightBg) : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isLoading ? null : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
