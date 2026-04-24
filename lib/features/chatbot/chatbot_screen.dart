import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'chatbot_constants.dart';
import 'widgets/chatbot_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  // Static list — persists across widget rebuilds and navigation
  static final List<ChatMessage> _messages = [];
  static bool _guidanceDismissed = false;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;
  late AnimationController _fadeCtrl;

  static const String _systemPrompt = '''You are AgriGuard AI Assistant — a smart, friendly agricultural expert built into the AgriGuard mobile app.

## App Owner
- App: AgriGuard — Plant Disease Detection
- Owner: Saad Ikram
- Contact: saadnaz43165@gmail.com
- If anyone asks who made this app, who is the owner, or how to contact support, answer with the above info.

## About AgriGuard App
AgriGuard is a Flutter mobile app for plant disease detection using the PlantCity 52-class EfficientNetB3 model (99.23% accuracy). It has:
- **On-Device Scan**: TFLite PlantCity model — works offline, instant results, 52 disease classes
- **Advanced AI Scan**: Cloud APIs (Groq AI, Hugging Face Vision, Plant.id) for deeper analysis
- **Disease Library**: Browse all 52 plant conditions with descriptions, symptoms, treatment, prevention
- **Scan History**: Saves all scans locally and syncs to Firebase
- **Weather Card**: Shows local weather relevant to farming
- **Farm Diary**: Log farm activities and observations
- **Supported Plants (12 total)**: Apple, Apricot, Bean, Cherry, Corn, Fig, Grape, Loquat, Pear, Persimmon, Tomato, Walnut

## Supported Diseases — Full 52-Class PlantCity Dataset

### Apple (3 classes)
- Apple Scab (سیب کی کھجلی): Olive-green scabby lesions on leaves and fruit. Caused by Venturia inaequalis fungus. Treat with captan or myclobutanil fungicide.
- Black Spot (کالا دھبہ): Dark circular spots on leaves and fruit. Caused by Diplocarpon mali. Treat with mancozeb or captan.
- Healthy (صحت مند)

### Apricot (3 classes)
- Blight Leaf Disease (پتوں کا جھلساؤ): Rapid browning and wilting of leaves. Fungal/bacterial. Treat with copper-based fungicide.
- Shot Hole Disease (سوراخ دار پتے): Circular spots that fall out leaving holes. Caused by Wilsonomyces carpophilus. Treat with copper fungicide.
- Healthy (صحت مند)

### Bean (4 classes)
- Fungal Leaf Disease (فنگل پتوں کی بیماری): Brown spots with yellow halos. Various fungi. Treat with mancozeb or chlorothalonil.
- Rust (زنگ): Rust-colored pustules on leaf undersides. Caused by Uromyces appendiculatus. Treat with triazole fungicides.
- Shot Hole (سوراخ دار پتے): Circular spots dropping out. Bacterial/fungal. Treat with copper bactericide.
- Healthy (صحت مند)

### Cherry (5 classes)
- Leaf Scorch (پتوں کا جھلساؤ): Leaf edges turn brown and scorched. Caused by Xylella fastidiosa bacterium. No cure — remove infected trees.
- Brown Spot (بھورے دھبے): Brown circular spots with yellow halos. Caused by Cercospora circumscissa. Treat with copper or mancozeb.
- Purple Leaf Spot (جامنی دھبے): Purple-red circular spots. Caused by Cercospora circumscissa. Treat with fungicide at bud break.
- Shot Hole Disease (سوراخ دار پتے): Circular spots leaving holes. Caused by Wilsonomyces carpophilus. Treat with copper fungicide.
- Healthy (صحت مند)

### Corn (4 classes)
- Fungal Leaf Disease (فنگل پتوں کی بیماری): Brown/tan lesions, yellowing. Various fungi. Treat with strobilurin or triazole fungicides.
- Gray Leaf Spot (گرے لیف اسپاٹ): Rectangular gray-tan lesions parallel to leaf veins. Caused by Cercospora zeae-maydis. Treat with strobilurin fungicide.
- Holcus Leaf Spot (ہولکس لیف اسپاٹ): White to tan circular spots with water-soaked margins. Caused by Pseudomonas syringae. Treat with copper bactericide.
- Healthy (صحت مند)

### Fig (4 classes)
- Blight Leaf Disease (پتوں کا جھلساؤ): Rapid browning and wilting. Fungal/bacterial. Treat with copper-based fungicide.
- Brown Spot (بھورے دھبے): Brown circular spots with yellowing. Caused by Cercospora fici. Treat with mancozeb or copper.
- Rust (زنگ): Yellow-orange spots on upper surface, rust pustules underneath. Caused by Cerotelium fici. Treat with sulfur or copper.
- Healthy (صحت مند)

### Grape (7 classes)
- Anthracnose (اینتھراکنوز): Circular spots with dark borders on leaves and fruit. Caused by Elsinoe ampelina. Treat with mancozeb or copper from bud break.
- Brown Spot (بھورے دھبے): Angular brown spots on upper leaf surface. Caused by Pseudocercospora vitis. Treat with copper fungicides.
- Downy Mildew (نیچے کی پھپھوندی): Yellow oily spots on upper surface, white downy growth underneath. Caused by Plasmopara viticola. Treat with metalaxyl or copper.
- Mite Damage (کیڑوں کا نقصان): Leaf distortion, bronzing, fine webbing. Spider mites. Treat with abamectin miticide.
- Powdery Mildew (پھپھوندی): White powdery coating on leaves. Caused by Erysiphe necator. Treat with sulfur or potassium bicarbonate.
- Shot Hole (سوراخ دار پتے): Circular spots leaving holes. Fungal/bacterial. Treat with copper fungicide.
- Healthy (صحت مند)

### Loquat (2 classes)
- Leaf Spot (پتوں کے دھبے): Brown spots on leaves. Fungal. Treat with copper or mancozeb fungicide.
- Healthy (صحت مند)

### Pear (3 classes)
- Black Spot (کالے دھبے): Dark spots on leaves and fruit. Fungal. Treat with mancozeb or captan.
- Fire Blight (آگ کا جھلساؤ): Blossoms and shoots wilt and turn brown (shepherd's crook). Caused by Erwinia amylovora bacterium. Prune 30cm below symptoms, apply copper.
- Healthy (صحت مند)

### Persimmon (2 classes)
- Brown Spot (بھورے دھبے): Brown circular spots on leaves. Fungal. Treat with copper or mancozeb.
- Healthy (صحت مند)

### Tomato (11 classes)
- Bacterial Spot (بیکٹیریل دھبہ): Water-soaked spots turning brown. Caused by Xanthomonas vesicatoria. Treat with copper bactericide.
- Early Blight (ابتدائی جھلساؤ): Target-like brown spots with concentric rings on lower leaves. Caused by Alternaria solani. Treat with chlorothalonil or mancozeb.
- Late Blight (آخری جھلساؤ): Large water-soaked lesions, white mold underneath. Caused by Phytophthora infestans. Treat with metalaxyl immediately.
- Leaf Curl (پتوں کا کرل): Upward curling and yellowing. Caused by Tomato Leaf Curl Virus via whiteflies. Control whiteflies with imidacloprid.
- Leaf Miner (پتوں کا کان کن): Winding white tunnels in leaves. Liriomyza fly larvae. Treat with spinosad or abamectin.
- Leaf Mold (پتوں کی پھپھوندی): Yellow spots on upper surface, olive-green mold underneath. Caused by Passalora fulva. Improve ventilation, apply chlorothalonil.
- Septoria Leaf Spot (سیپٹوریا دھبے): Small circular spots with dark borders and light centers. Caused by Septoria lycopersici. Treat with chlorothalonil or mancozeb.
- Spider Mites (مکڑی کے ذرات): Fine stippling, bronze discoloration, fine webbing. Tetranychus urticae. Treat with abamectin or bifenazate.
- Fusarium Wilt (فیوزیریم مرجھاؤ): Yellowing of lower leaves, one-sided wilting, brown vascular tissue. Caused by Fusarium oxysporum. No cure — use resistant varieties.
- Verticillium Wilt (ورٹیسیلیم مرجھاؤ): V-shaped yellow lesions, wilting during hot days. Caused by Verticillium dahliae. No cure — use resistant varieties.
- Healthy (صحت مند)

### Walnut (5 classes)
- Anthracnose (اینتھراکنوز): Brown irregular spots on leaves, dark lesions on husks. Caused by Gnomonia leptostyla. Treat with copper or mancozeb at bud break.
- Blotch (بلاچ): White powdery blotches on leaf undersides. Caused by Microstroma juglandis. Treat with sulfur or copper.
- Shot Hole (سوراخ دار پتے): Circular spots leaving holes. Fungal/bacterial. Treat with copper fungicide.
- Leaf Gall Mite (پتوں کے گال ذرات): Felt-like galls on leaf surfaces. Caused by Aceria erinea mite. Apply dormant oil in winter.
- Healthy (صحت مند)

## CRITICAL LANGUAGE RULE
- ALWAYS detect the language of the user's message
- If the user writes in Urdu (اردو) or uses Urdu words, you MUST respond ENTIRELY in Urdu
- If the user writes in English, respond in English
- Never mix languages unless the user does
- Urdu responses must use proper Urdu script (not Roman Urdu)

## Your Role
1. Help users understand their scan results from the 52-class PlantCity model
2. Explain plant diseases, symptoms, causes, and treatments for all 12 supported plants
3. Give actionable farming advice tailored to Pakistani/South Asian agriculture
4. Answer questions about the AgriGuard app features
5. Provide crop care, fertilization, irrigation, and pest management tips
6. If asked about owner/contact: Owner is Saad Ikram, email: saadnaz43165@gmail.com

## Response Style
- Be concise and practical
- Use bullet points for lists
- Always mention: symptoms, causes, treatment, prevention when discussing diseases
- Be encouraging and supportive to farmers
- Keep responses under 300 words unless more detail is needed
- For Urdu responses: use clear, simple Urdu that Pakistani farmers can understand
- Reference the Disease Library in the app for more details when relevant''';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this)..forward();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<({String text, IconData icon})> _getSuggestions(bool isUrdu) => ChatbotConstants.getSuggestions(isUrdu);

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    final userMsg = text.trim();
    _inputCtrl.clear();
    setState(() {
      _guidanceDismissed = true;
      _messages.add(ChatMessage(role: 'user', content: userMsg, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final groqModel = dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile';
    if (groqKey.isNotEmpty) {
      final success = await _tryGroq(groqKey, groqModel);
      if (success) return;
    }
    _localFallback(userMsg);
  }

  Future<bool> _tryGroq(String apiKey, String model) async {
    try {
      final msgs = _messages.map((m) => {'role': m.role, 'content': m.content}).toList();
      // Detect language of last user message and add hint
      final lastUserMsg = _messages.lastWhere((m) => m.role == 'user', orElse: () => _messages.last);
      final langHint = ChatbotConstants.isUrdu(lastUserMsg.content)
          ? '\n\nIMPORTANT: The user is writing in Urdu. You MUST respond entirely in Urdu script.'
          : '';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': ChatbotConstants.systemPrompt + langHint},
            ...msgs,
          ],
          'max_tokens': 600,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 25));

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
      debugPrint('Groq error: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Groq exception: $e');
      return false;
    }
  }

  void _localFallback(String query) {
    final q = query.toLowerCase();
    final isUrduQuery = ChatbotConstants.isUrdu(query);
    String reply;

    // Owner / contact info
    if (q.contains('owner') || q.contains('who made') || q.contains('contact') ||
        q.contains('developer') || q.contains('saad') ||
        query.contains('مالک') || query.contains('رابطہ') || query.contains('بنایا')) {
      reply = isUrduQuery
          ? 'AgriGuard ایپ کے مالک **سعد اکرم** ہیں۔\n\nرابطہ: saadnaz43165@gmail.com\n\nکوئی بھی سوال یا مدد کے لیے ای میل کریں۔'
          : 'AgriGuard is developed by **Saad Ikram**.\n\nContact: saadnaz43165@gmail.com\n\nFeel free to reach out for support or feedback!';
    }
    // Tomato
    else if (q.contains('tomato') || query.contains('ٹماٹر')) {
      reply = isUrduQuery
          ? '**ٹماٹر کی بیماریاں (11 کلاسز)**\n\n• **ارلی بلائٹ**: بھورے ہدف جیسے دھبے — chlorothalonil\n• **لیٹ بلائٹ**: پانی جیسے زخم — فوری metalaxyl\n• **بیکٹیریل اسپاٹ**: پانی سے بھرے دھبے — تانبے کی دوا\n• **لیف کرل**: پتے مڑے ہوئے — سفید مکھی کنٹرول\n• **سیپٹوریا**: گہرے کناروں والے چھوٹے دھبے — mancozeb\n• **فیوزیریم مرجھاؤ**: ایک طرف مرجھانا — مزاحم اقسام\n\nAgriGuard سے اسکین کریں!'
          : '**Tomato Diseases (11 classes)**\n\n• **Early Blight**: Target-like brown spots — chlorothalonil\n• **Late Blight**: Water-soaked lesions — metalaxyl immediately\n• **Bacterial Spot**: Water-soaked spots — copper bactericide\n• **Leaf Curl**: Curling/yellowing — control whiteflies\n• **Septoria**: Small spots with dark borders — mancozeb\n• **Fusarium Wilt**: One-sided wilting — use resistant varieties\n\nScan with AgriGuard for instant diagnosis!';
    }
    // Apple
    else if (q.contains('apple') || query.contains('سیب')) {
      reply = isUrduQuery
          ? '**سیب کی بیماریاں (3 کلاسز)**\n\n• **ایپل اسکیب**: زیتونی سبز کھردرے دھبے — captan یا myclobutanil\n• **بلیک اسپاٹ**: گہرے گول دھبے — mancozeb یا captan\n\nAgriGuard سے اسکین کریں!'
          : '**Apple Diseases (3 classes)**\n\n• **Apple Scab**: Olive-green scabby lesions — captan or myclobutanil\n• **Black Spot**: Dark circular spots — mancozeb or captan\n\nScan with AgriGuard!';
    }
    // Grape
    else if (q.contains('grape') || query.contains('انگور')) {
      reply = isUrduQuery
          ? '**انگور کی بیماریاں (7 کلاسز)**\n\n• **اینتھراکنوز**: گہرے کناروں والے گول دھبے — mancozeb\n• **ڈاؤنی ملڈیو**: پیلے تیلی دھبے — metalaxyl\n• **پاؤڈری ملڈیو**: سفید پاؤڈری کوٹنگ — گندھک\n• **براؤن اسپاٹ**: کونے دار بھورے دھبے — تانبے کی دوا\n• **مائٹ نقصان**: پتوں کی خرابی — abamectin\n\nAgriGuard سے اسکین کریں!'
          : '**Grape Diseases (7 classes)**\n\n• **Anthracnose**: Circular spots with dark borders — mancozeb\n• **Downy Mildew**: Yellow oily spots — metalaxyl\n• **Powdery Mildew**: White powdery coating — sulfur\n• **Brown Spot**: Angular brown spots — copper fungicide\n• **Mite Damage**: Leaf distortion, bronzing — abamectin\n\nScan with AgriGuard!';
    }
    // Corn
    else if (q.contains('corn') || query.contains('مکئی')) {
      reply = isUrduQuery
          ? '**مکئی کی بیماریاں (4 کلاسز)**\n\n• **گرے لیف اسپاٹ**: مستطیل خاکستری دھبے — triazole فنگسائیڈ\n• **فنگل لیف ڈیزیز**: بھورے زخم — strobilurin\n• **ہولکس لیف اسپاٹ**: سفید سے تن رنگ دھبے — تانبے کا بیکٹیریسائیڈ\n\nAgriGuard سے اسکین کریں!'
          : '**Corn Diseases (4 classes)**\n\n• **Gray Leaf Spot**: Rectangular gray lesions — triazole fungicide\n• **Fungal Leaf Disease**: Brown/tan lesions — strobilurin\n• **Holcus Leaf Spot**: White to tan spots — copper bactericide\n\nScan with AgriGuard!';
    }
    // Walnut
    else if (q.contains('walnut') || query.contains('اخروٹ')) {
      reply = isUrduQuery
          ? '**اخروٹ کی بیماریاں (5 کلاسز)**\n\n• **اینتھراکنوز**: بھورے بے قاعدہ دھبے — تانبے کا فنگسائیڈ\n• **بلاچ**: سفید پاؤڈری دھبے — گندھک\n• **سوراخ دار پتے**: گول سوراخ — تانبے کی دوا\n• **گال ذرات**: محسوس جیسے گال — ڈورمنٹ تیل\n\nAgriGuard سے اسکین کریں!'
          : '**Walnut Diseases (5 classes)**\n\n• **Anthracnose**: Brown irregular spots — copper fungicide\n• **Blotch**: White powdery patches — sulfur\n• **Shot Hole**: Circular holes in leaves — copper\n• **Leaf Gall Mite**: Felt-like galls — dormant oil\n\nScan with AgriGuard!';
    }
    // Pear
    else if (q.contains('pear') || query.contains('ناشپاتی')) {
      reply = isUrduQuery
          ? '**ناشپاتی کی بیماریاں (3 کلاسز)**\n\n• **بلیک اسپاٹ**: گہرے دھبے — mancozeb یا captan\n• **فائر بلائٹ**: شاخیں مرجھا کر بھوری ہو جاتی ہیں — متاثرہ لکڑی کاٹیں، تانبے کا اسپرے\n\nAgriGuard سے اسکین کریں!'
          : '**Pear Diseases (3 classes)**\n\n• **Black Spot**: Dark spots on leaves/fruit — mancozeb or captan\n• **Fire Blight**: Shoots wilt and turn brown — prune 30cm below, apply copper\n\nScan with AgriGuard!';
    }
    // Cherry
    else if (q.contains('cherry') || query.contains('چیری')) {
      reply = isUrduQuery
          ? '**چیری کی بیماریاں (5 کلاسز)**\n\n• **لیف اسکارچ**: پتوں کے کنارے جھلسے ہوئے — کوئی علاج نہیں، درخت ہٹائیں\n• **براؤن اسپاٹ**: بھورے گول دھبے — تانبے کی دوا\n• **جامنی دھبے**: جامنی سرخ دھبے — فنگسائیڈ\n• **سوراخ دار پتے**: گول سوراخ — تانبے کی دوا\n\nAgriGuard سے اسکین کریں!'
          : '**Cherry Diseases (5 classes)**\n\n• **Leaf Scorch**: Scorched leaf edges — no cure, remove infected trees\n• **Brown Spot**: Brown circular spots — copper or mancozeb\n• **Purple Leaf Spot**: Purple-red spots — fungicide at bud break\n• **Shot Hole**: Circular holes in leaves — copper fungicide\n\nScan with AgriGuard!';
    }
    // Bean
    else if (q.contains('bean') || query.contains('پھلی') || query.contains('پھلیاں')) {
      reply = isUrduQuery
          ? '**پھلیوں کی بیماریاں (4 کلاسز)**\n\n• **فنگل لیف ڈیزیز**: بھورے دھبے — mancozeb\n• **زنگ**: زنگ رنگ کے پھوڑے — triazole فنگسائیڈ\n• **سوراخ دار پتے**: گول سوراخ — تانبے کی دوا\n\nAgriGuard سے اسکین کریں!'
          : '**Bean Diseases (4 classes)**\n\n• **Fungal Leaf Disease**: Brown spots with yellow halos — mancozeb\n• **Rust**: Rust-colored pustules — triazole fungicide\n• **Shot Hole**: Circular holes — copper bactericide\n\nScan with AgriGuard!';
    }
    // Fig
    else if (q.contains('fig') || query.contains('انجیر')) {
      reply = isUrduQuery
          ? '**انجیر کی بیماریاں (4 کلاسز)**\n\n• **بلائٹ**: تیز بھوری رنگت — تانبے کی دوا\n• **براؤن اسپاٹ**: بھورے گول دھبے — mancozeb\n• **زنگ**: پیلے نارنجی دھبے — گندھک\n\nAgriGuard سے اسکین کریں!'
          : '**Fig Diseases (4 classes)**\n\n• **Blight**: Rapid browning — copper fungicide\n• **Brown Spot**: Brown circular spots — mancozeb\n• **Rust**: Yellow-orange spots — sulfur fungicide\n\nScan with AgriGuard!';
    }
    // Apricot
    else if (q.contains('apricot') || query.contains('خوبانی')) {
      reply = isUrduQuery
          ? '**خوبانی کی بیماریاں (3 کلاسز)**\n\n• **بلائٹ**: پتوں کا تیز بھوری رنگت — تانبے کی دوا\n• **سوراخ دار پتے**: گول سوراخ — تانبے کا فنگسائیڈ\n\nAgriGuard سے اسکین کریں!'
          : '**Apricot Diseases (3 classes)**\n\n• **Blight Leaf Disease**: Rapid browning — copper fungicide\n• **Shot Hole**: Circular holes — copper fungicide at bud break\n\nScan with AgriGuard!';
    }
    // Loquat
    else if (q.contains('loquat') || query.contains('لوکاٹ')) {
      reply = isUrduQuery
          ? '**لوکاٹ کی بیماریاں (2 کلاسز)**\n\n• **لیف اسپاٹ**: پتوں پر بھورے دھبے — تانبے یا mancozeb فنگسائیڈ\n\nAgriGuard سے اسکین کریں!'
          : '**Loquat Diseases (2 classes)**\n\n• **Leaf Spot**: Brown spots on leaves — copper or mancozeb fungicide\n\nScan with AgriGuard!';
    }
    // Persimmon
    else if (q.contains('persimmon') || query.contains('املوک')) {
      reply = isUrduQuery
          ? '**املوک کی بیماریاں (2 کلاسز)**\n\n• **براؤن اسپاٹ**: بھورے گول دھبے — تانبے یا mancozeb فنگسائیڈ\n\nAgriGuard سے اسکین کریں!'
          : '**Persimmon Diseases (2 classes)**\n\n• **Brown Spot**: Brown circular spots — copper or mancozeb fungicide\n\nScan with AgriGuard!';
    }
    // How to use / scan
    else if (q.contains('scan') || q.contains('how to') || q.contains('use') ||
        query.contains('اسکین') || query.contains('کیسے') || query.contains('استعمال')) {
      reply = isUrduQuery
          ? '**AgriGuard کا استعمال**\n\n1. نیچے کیمرہ بٹن دبائیں\n2. طریقہ منتخب کریں: آن ڈیوائس (آف لائن) یا ایڈوانسڈ AI\n3. پتے کی تصویر لیں\n4. نتائج دیکھیں: پودے کا نام، بیماری، علاج\n\n**52 بیماریاں** 12 پودوں میں تشخیص ہوتی ہیں!\nبہترین نتائج کے لیے: اچھی روشنی میں پتے کی واضح تصویر لیں!'
          : '**How to Use AgriGuard**\n\n1. Tap the camera button (bottom nav)\n2. Choose: On-Device (offline) or Advanced AI (cloud)\n3. Take/select a photo of the affected leaf\n4. View results: plant name, disease, severity, treatment\n\n**52 disease classes** across 12 plants!\nTip: Good lighting + clear leaf photo = best results!';
    }
    // Hello / greeting
    else if (q.contains('hello') || q.contains('hi') || q.contains('salam') ||
        query.contains('السلام') || query.contains('ہیلو') || query.contains('سلام')) {
      reply = isUrduQuery
          ? 'السلام علیکم! 👋 میں AgriGuard AI ہوں، آپ کا پودوں کا ماہر۔\n\nمیں مدد کر سکتا ہوں:\n• 12 پودوں کی 52 بیماریوں کی تشخیص\n• فصلوں کی دیکھ بھال\n• AgriGuard کا استعمال\n\nآج کیا مسئلہ ہے؟'
          : 'Hello! 👋 I\'m AgriGuard AI, your plant health assistant.\n\nI can help with:\n• 52 disease classes across 12 plants\n• Crop care & treatment advice\n• How to use AgriGuard\n\nWhat plant issue can I help you with today?';
    }
    // Urdu language request
    else if (q.contains('urdu') || query.contains('اردو') || query.contains('پاکستان')) {
      reply = 'جی ہاں! میں اردو میں بات کر سکتا ہوں۔ 🌱\n\nAgriGuard 12 پودوں کی 52 بیماریوں کی تشخیص کرتا ہے۔\n\nآپ کے پودے میں کیا مسئلہ ہے؟ مجھے بتائیں!';
    }
    // Treatment / fungicide
    else if (q.contains('fungicide') || q.contains('treatment') || q.contains('cure') ||
        query.contains('علاج') || query.contains('دوا')) {
      reply = isUrduQuery
          ? '**عمومی علاج کی ہدایات**\n\n• **فنگل بیماریاں**: تانبے کی فنگسائیڈ، mancozeb، triazole\n• **بیکٹیریل بیماریاں**: تانبے کی دوا، streptomycin\n• **وائرل بیماریاں**: کیڑوں کو کنٹرول کریں، متاثرہ پودے ہٹائیں\n• **ذرات (مائٹس)**: abamectin، bifenazate\n\n⚠️ ہمیشہ لیبل کی ہدایات پر عمل کریں۔\nپہلے AgriGuard سے اسکین کریں!'
          : '**General Treatment Guidelines**\n\n• **Fungal**: Copper fungicides, mancozeb, triazoles, strobilurin\n• **Bacterial**: Copper bactericides, streptomycin\n• **Viral**: Control insect vectors, remove infected plants\n• **Mites**: Abamectin, bifenazate miticides\n\n⚠️ Always follow label instructions.\nScan with AgriGuard first to identify the exact disease!';
    }
    // Supported plants list
    else if (q.contains('plant') || q.contains('support') || q.contains('which') ||
        query.contains('پودے') || query.contains('کون سے')) {
      reply = isUrduQuery
          ? '**AgriGuard کے معاون پودے (12)**\n\nسیب، خوبانی، پھلیاں، چیری، مکئی، انجیر، انگور، لوکاٹ، ناشپاتی، املوک، ٹماٹر، اخروٹ\n\n**کل 52 بیماریاں** تشخیص ہوتی ہیں!\n\nکسی بھی پودے کے بارے میں پوچھیں۔'
          : '**AgriGuard Supported Plants (12)**\n\nApple, Apricot, Bean, Cherry, Corn, Fig, Grape, Loquat, Pear, Persimmon, Tomato, Walnut\n\n**52 total disease classes** detected!\n\nAsk me about any specific plant.';
    }
    // Default
    else {
      reply = isUrduQuery
          ? 'میں پودوں کی بیماریوں اور AgriGuard کے بارے میں مدد کر سکتا ہوں! 🌿\n\nپوچھیں:\n• کسی پودے کے بارے میں (مثلاً "ٹماٹر کی بیماریاں")\n• کسی بیماری کے بارے میں (مثلاً "انگور کی پھپھوندی")\n• AgriGuard کا استعمال\n\nیا AgriGuard سے اپنے پودے کو اسکین کریں!'
          : 'I\'m here to help with plant diseases and AgriGuard! 🌿\n\nTry asking about:\n• A specific plant (e.g., "Tomato diseases", "Grape diseases")\n• A specific disease (e.g., "fire blight treatment")\n• How to use AgriGuard features\n\nOr scan your plant with AgriGuard for instant AI diagnosis!';
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
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final suggestions = _getSuggestions(t.isUrdu);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 22),
          onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
        ),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.get('chatbot_title'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                Row(children: [
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(t.get('chatbot_always_available'),
                      style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: (_guidanceDismissed ? 0 : 1) + _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (!_guidanceDismissed && index == 0) {
                    return _buildGuidanceCard(isDark, t);
                  }
                  final msgIndex = index - (_guidanceDismissed ? 0 : 1);
                  if (msgIndex == _messages.length) return TypingIndicator(isDark: isDark);
                  return MessageBubble(message: _messages[msgIndex], isDark: isDark);
                },
              ),
            ),
          ),
          if (_messages.isEmpty)
            SuggestionsRow(suggestions: suggestions, onTap: _sendMessage, isDark: isDark),
          ChatInputBar(
            controller: _inputCtrl,
            isLoading: _isLoading,
            isDark: isDark,
            hintText: t.isUrdu ? t.get('chatbot_hint_ur') : t.get('chatbot_hint'),
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(bool isDark, TranslationService t) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(t.get('chatbot_guidance_title'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.get('chatbot_guidance_desc'),
              style: TextStyle(fontSize: 13, color: captionColor, height: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(t.get('chatbot_guidance_examples'),
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}


