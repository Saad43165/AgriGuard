// chatbot_service.dart
// API service handling Groq AI + local fallback for AgriGuard chatbot

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../chatbot_constants.dart';
import '../models/chatbot_models.dart';

class ChatbotService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Primary: Try Groq API. Returns reply string or null on failure.
  static Future<String?> sendToGroq(List<ChatMessage> messages) async {
    final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final groqModel =
        dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile';

    if (groqKey.isEmpty) return null;

    try {
      final lastUserMsg = messages.lastWhere(
        (m) => m.role == 'user',
        orElse: () => messages.last,
      );
      final langHint = ChatbotConstants.isUrduText(lastUserMsg.content)
          ? '\n\nIMPORTANT: The user is writing in Urdu. You MUST respond entirely in Urdu script. Use the same structured emoji format but in Urdu.'
          : '';

      final apiMessages = messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $groqKey',
            },
            body: jsonEncode({
              'model': groqModel,
              'messages': [
                {
                  'role': 'system',
                  'content': ChatbotConstants.systemPrompt + langHint,
                },
                ...apiMessages,
              ],
              'max_tokens': 700,
              'temperature': 0.65,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply =
            data['choices'][0]['message']['content'] as String;
        return reply.trim();
      }
      debugPrint('Groq error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Groq exception: $e');
      return null;
    }
  }

  /// Fallback: keyword-based local responses
  static String localFallback(String query, bool isUrduQuery) {
    final q = query.toLowerCase();

    // ── Owner / contact ──────────────────────────────────────────────────────
    if (q.contains('owner') ||
        q.contains('who made') ||
        q.contains('contact') ||
        q.contains('developer') ||
        q.contains('saad') ||
        query.contains('مالک') ||
        query.contains('رابطہ') ||
        query.contains('بنایا')) {
      return isUrduQuery
          ? "👨‍💻 **AgriGuard ایپ کے بارے میں**\n\n**مالک:** سعد اکرم\n**ای میل:** saadnaz43165@gmail.com\n\n💡 **مدد:** کسی بھی سوال یا مسئلے کے لیے ای میل کریں۔"
          : "👨‍💻 **About AgriGuard**\n\n**Developer:** Saad Ikram\n**Email:** saadnaz43165@gmail.com\n\n💡 **Support:** Feel free to reach out for help or feedback!";
    }

    // ── Tomato ───────────────────────────────────────────────────────────────
    if (q.contains('tomato') || query.contains('ٹماٹر')) {
      return isUrduQuery
          ? "🍅 **ٹماٹر کی بیماریاں (11 کلاسز)**\n\n📋 **فنگل بیماریاں:**\n• Early Blight: ہدف جیسے بھورے دھبے — chlorothalonil\n• Late Blight: پانی جیسے زخم — فوری metalaxyl\n• Leaf Mold: زیتونی سبز سانچہ — ہوادار جگہ\n• Septoria: گہرے کناروں والے دھبے — mancozeb\n\n🦠 **بیکٹیریل:**\n• Bacterial Spot: پانی بھرے دھبے — تانبے کی دوا\n\n🐛 **حشرات:**\n• Leaf Curl: پتے مڑے — imidacloprid\n• Leaf Miner: سفید سرنگیں — spinosad\n• Spider Mites: جالا — abamectin\n\n⚠️ **لاعلاج:**\n• Fusarium Wilt / Verticillium Wilt — مزاحم اقسام\n\n💡 **ٹپ:** AgriGuard آف لائن اسکین سے فوری تشخیص کریں!"
          : "🍅 **Tomato Diseases (11 Classes)**\n\n📋 **Fungal:**\n• Early Blight: Target-like brown spots — chlorothalonil\n• Late Blight: Water-soaked lesions — metalaxyl immediately!\n• Leaf Mold: Yellow spots, olive mold — improve airflow\n• Septoria: Small spots with dark borders — mancozeb\n\n🦠 **Bacterial:**\n• Bacterial Spot: Water-soaked spots — copper bactericide\n\n🐛 **Pest-related:**\n• Leaf Curl: Curling/yellowing — imidacloprid for whiteflies\n• Leaf Miner: White tunnels — spinosad\n• Spider Mites: Bronze + webbing — abamectin\n\n⚠️ **No cure:**\n• Fusarium Wilt / Verticillium Wilt — use resistant varieties\n\n💡 **Tip:** Scan with AgriGuard for instant offline diagnosis!";
    }

    // ── Grape ────────────────────────────────────────────────────────────────
    if (q.contains('grape') || query.contains('انگور')) {
      return isUrduQuery
          ? "🍇 **انگور کی بیماریاں (7 کلاسز)**\n\n📋 **علامات اور علاج:**\n• Anthracnose: گہرے کناروں والے گول دھبے — mancozeb یا تانبا\n• Brown Spot: کونے دار بھورے دھبے — تانبے کا فنگسائیڈ\n• Downy Mildew: پیلے تیلی دھبے، نیچے سفید — metalaxyl\n• Powdery Mildew: سفید پاؤڈری کوٹنگ — گندھک\n• Mites: پتوں کی خرابی، کانسی رنگ — abamectin\n• Shot Hole: گول سوراخ — تانبے کی دوا\n\n💡 **ٹپ:** AgriGuard سے اسکین کریں — فوری نتائج!"
          : "🍇 **Grape Diseases (7 Classes)**\n\n📋 **Symptoms & Treatment:**\n• Anthracnose: Circular spots, dark borders — mancozeb/copper\n• Brown Spot: Angular brown spots — copper fungicide\n• Downy Mildew: Yellow oily spots, white underside — metalaxyl\n• Powdery Mildew: White powdery coating — sulfur fungicide\n• Mites: Leaf distortion, bronzing — abamectin\n• Shot Hole: Circular holes — copper bactericide\n\n💡 **Tip:** Scan with AgriGuard for instant offline results!";
    }

    // ── Corn ─────────────────────────────────────────────────────────────────
    if (q.contains('corn') ||
        q.contains('maize') ||
        query.contains('مکئی')) {
      return isUrduQuery
          ? "🌽 **مکئی کی بیماریاں (4 کلاسز)**\n\n📋 **علامات اور علاج:**\n• Gray Leaf Spot: مستطیل خاکستری دھبے — triazole فنگسائیڈ\n• Fungal Leaf Disease: بھورے/تن رنگ زخم — strobilurin\n• Holcus Leaf Spot: سفید سے تن رنگ دھبے — تانبے کا بیکٹیریسائیڈ\n\n⚠️ **احتیاط:** گرم اور مرطوب موسم میں بیماری تیزی پھیلتی ہے۔\n\n💡 **ٹپ:** AgriGuard آف لائن سے فوری تشخیص!"
          : "🌽 **Corn Diseases (4 Classes)**\n\n📋 **Symptoms & Treatment:**\n• Gray Leaf Spot: Rectangular gray lesions along veins — triazole fungicide\n• Fungal Leaf Disease: Brown/tan lesions — strobilurin fungicide\n• Holcus Leaf Spot: White to tan spots — copper bactericide\n\n⚠️ **Note:** Spreads fast in warm, humid conditions.\n\n💡 **Tip:** Scan with AgriGuard for instant offline diagnosis!";
    }

    // ── Bean ─────────────────────────────────────────────────────────────────
    if (q.contains('bean') ||
        query.contains('پھلی') ||
        query.contains('پھلیاں')) {
      return isUrduQuery
          ? "🫘 **پھلیوں کی بیماریاں (4 کلاسز)**\n\n📋 **علامات اور علاج:**\n• Fungal Leaf Disease: پیلے ہالے کے ساتھ بھورے دھبے — mancozeb یا chlorothalonil\n• Bean Rust: زنگ رنگ کے پھوڑے — triazole فنگسائیڈ\n• Shot Hole: گول سوراخ — تانبے کا بیکٹیریسائیڈ\n\n💡 **ٹپ:** AgriGuard آف لائن اسکین سے فوری نتیجہ!"
          : "🫘 **Bean Diseases (4 Classes)**\n\n📋 **Symptoms & Treatment:**\n• Fungal Leaf Disease: Brown spots with yellow halos — mancozeb/chlorothalonil\n• Bean Rust: Rust-colored pustules underneath leaves — triazole fungicide\n• Shot Hole: Circular holes in leaves — copper bactericide\n\n💡 **Tip:** Scan offline with AgriGuard for instant results!";
    }

    // ── Fig ──────────────────────────────────────────────────────────────────
    if (q.contains('fig') || query.contains('انجیر')) {
      return isUrduQuery
          ? "🌿 **انجیر کی بیماریاں (4 کلاسز)**\n\n📋 **علامات اور علاج:**\n• Blight: تیز بھوری رنگت اور مرجھانا — تانبے کا فنگسائیڈ\n• Brown Spot: بھورے گول دھبے — mancozeb یا تانبا\n• Rust: پیلے نارنجی دھبے، نیچے زنگ — گندھک یا تانبا\n\n💡 **ٹپ:** AgriGuard سے اسکین کریں!"
          : "🌿 **Fig Diseases (4 Classes)**\n\n📋 **Symptoms & Treatment:**\n• Blight: Rapid browning and wilting — copper fungicide\n• Brown Spot: Brown circular spots — mancozeb or copper\n• Rust: Yellow-orange spots on top, rust pustules below — sulfur/copper\n\n💡 **Tip:** Scan with AgriGuard for fast offline results!";
    }

    // ── Walnut ───────────────────────────────────────────────────────────────
    if (q.contains('walnut') || query.contains('اخروٹ')) {
      return isUrduQuery
          ? "🌰 **اخروٹ کی بیماریاں (5 کلاسز)**\n\n📋 **علامات اور علاج:**\n• Anthracnose: بھورے بے قاعدہ دھبے — تانبے کا فنگسائیڈ\n• Blotch: سفید پاؤڈری دھبے — گندھک کا فنگسائیڈ\n• Shot Hole: گول سوراخ — تانبے کی دوا\n• Leaf Gall Mite: محسوس جیسے گال — ڈورمنٹ تیل\n\n💡 **ٹپ:** AgriGuard سے فوری اسکین کریں!"
          : "🌰 **Walnut Diseases (5 Classes)**\n\n📋 **Symptoms & Treatment:**\n• Anthracnose: Brown irregular spots — copper fungicide\n• Blotch: White powdery patches — sulfur fungicide\n• Shot Hole: Circular holes in leaves — copper spray\n• Leaf Gall Mite: Felt-like galls on leaves — dormant oil\n\n💡 **Tip:** Scan with AgriGuard for instant offline results!";
    }

    // ── How to use / scan ────────────────────────────────────────────────────
    if (q.contains('scan') ||
        q.contains('how to') ||
        q.contains('use') ||
        q.contains('work') ||
        query.contains('اسکین') ||
        query.contains('کیسے') ||
        query.contains('استعمال')) {
      return isUrduQuery
          ? "📱 **AgriGuard کا استعمال**\n\n**مرحلہ 1:** نیچے کیمرہ بٹن دبائیں\n**مرحلہ 2:** طریقہ منتخب کریں:\n   • 🔌 **آن ڈیوائس** — آف لائن، فوری (6 پودے)\n   • 🌐 **ایڈوانسڈ AI** — کلاؤڈ، ہزاروں پودے\n**مرحلہ 3:** متاثرہ پتے کی تصویر لیں\n**مرحلہ 4:** نتائج دیکھیں: نام، بیماری، علاج\n\n✅ **بہترین نتائج کے لیے:**\n• اچھی روشنی میں تصویر لیں\n• پتے کو قریب سے دکھائیں\n• صاف، دھندلا نہیں\n\n💡 **ٹپ:** آن ڈیوائس بالکل مفت اور آف لائن کام کرتا ہے!"
          : "📱 **How to Use AgriGuard**\n\n**Step 1:** Tap the camera button (bottom nav)\n**Step 2:** Choose scan mode:\n   • 🔌 **On-Device** — Offline, instant (6 plants)\n   • 🌐 **Advanced AI** — Cloud, thousands of plants\n**Step 3:** Take/select a photo of the affected leaf\n**Step 4:** See results: plant, disease, severity, treatment\n\n✅ **Best results tips:**\n• Good natural lighting\n• Show the leaf up close\n• Clear, not blurry photo\n\n💡 **Tip:** On-Device scan is completely free and offline!";
    }

    // ── Plants not in on-device model ────────────────────────────────────────
    if (q.contains('apple') ||
        q.contains('wheat') ||
        q.contains('rice') ||
        q.contains('mango') ||
        q.contains('potato') ||
        q.contains('pear') ||
        q.contains('cherry') ||
        query.contains('سیب') ||
        query.contains('گندم') ||
        query.contains('چاول') ||
        query.contains('آم') ||
        query.contains('آلو')) {
      return isUrduQuery
          ? "ℹ️ **یہ پودہ آن ڈیوائس ماڈل میں شامل نہیں**\n\n✅ **آن ڈیوائس** صرف 6 پودے:\nپھلیاں • مکئی • انجیر • انگور • اخروٹ • ٹماٹر\n\n🌐 **دوسرے پودوں کے لیے — Advanced AI استعمال کریں:**\n• ہزاروں پودوں کی شناخت\n• تفصیلی بیماری کا تجزیہ\n• علاج کی مکمل رہنمائی\n\n💡 **ٹپ:** Advanced AI بٹن دبائیں اور تصویر اپلوڈ کریں!"
          : "ℹ️ **This plant is not in the On-Device model**\n\n✅ **On-Device** supports only 6 plants:\nBean • Corn • Fig • Grape • Walnut • Tomato\n\n🌐 **For other plants — use Advanced AI scan:**\n• Identifies thousands of plant species\n• Detailed disease analysis\n• Complete treatment guidance\n\n💡 **Tip:** Tap Advanced AI and upload your plant photo!";
    }

    // ── Greeting ─────────────────────────────────────────────────────────────
    if (q.contains('hello') ||
        q.contains('hi') ||
        q.contains('hey') ||
        q.contains('salam') ||
        query.contains('السلام') ||
        query.contains('ہیلو') ||
        query.contains('سلام')) {
      return isUrduQuery
          ? "🌱 **السلام علیکم! AgriGuard AI میں خوش آمدید**\n\nمیں آپ کا پودوں کا ماہر ہوں۔ میں مدد کر سکتا ہوں:\n\n🔌 **آن ڈیوائس:** 6 پودوں کی 35 بیماریاں (آف لائن)\n🌐 **ایڈوانسڈ AI:** ہزاروں پودوں کی شناخت\n💬 **یہ چیٹ:** کسی بھی پودے کے بارے میں سوال کریں\n\n**آج کیا مسئلہ ہے؟**"
          : "🌱 **Welcome to AgriGuard AI!**\n\nI'm your personal plant health expert. I can help with:\n\n🔌 **On-Device:** 35 diseases for Bean, Corn, Fig, Grape, Walnut, Tomato (offline)\n🌐 **Advanced AI:** Thousands of plant species via Plant.id\n💬 **This Chat:** Ask me anything about any plant!\n\n**What plant issue can I help you with today?**";
    }

    // ── Supported plants list ────────────────────────────────────────────────
    if (q.contains('plant') ||
        q.contains('support') ||
        q.contains('which') ||
        q.contains('list') ||
        query.contains('پودے') ||
        query.contains('کون سے') ||
        query.contains('فہرست')) {
      return isUrduQuery
          ? "🌿 **AgriGuard سپورٹڈ پودے**\n\n🔌 **آن ڈیوائس (آف لائن) — 6 پودے:**\n🫘 پھلیاں (4 بیماریاں)\n🌽 مکئی (4 بیماریاں)\n🌿 انجیر (4 بیماریاں)\n🍇 انگور (7 بیماریاں)\n🌰 اخروٹ (5 بیماریاں)\n🍅 ٹماٹر (11 بیماریاں)\n\n🌐 **ایڈوانسڈ AI (کلاؤڈ):**\nہزاروں پودے اور بیماریاں!\n\n💡 **ٹپ:** کسی بھی پودے کے بارے میں مزید معلومات مانگیں!"
          : "🌿 **AgriGuard Supported Plants**\n\n🔌 **On-Device (Offline) — 6 Plants:**\n🫘 Bean (4 diseases)\n🌽 Corn (4 diseases)\n🌿 Fig (4 diseases)\n🍇 Grape (7 diseases)\n🌰 Walnut (5 diseases)\n🍅 Tomato (11 diseases)\n\n🌐 **Advanced AI (Cloud):**\nThousands of plant species!\n\n💡 **Tip:** Ask me details about any specific plant!";
    }

    // ── Treatment / fungicide ────────────────────────────────────────────────
    if (q.contains('fungicide') ||
        q.contains('treatment') ||
        q.contains('cure') ||
        q.contains('medicine') ||
        query.contains('علاج') ||
        query.contains('دوا') ||
        query.contains('فنگسائیڈ')) {
      return isUrduQuery
          ? "💊 **عمومی علاج کی رہنمائی**\n\n🍄 **فنگل بیماریاں:**\n• تانبے کا فنگسائیڈ، mancozeb، triazole، strobilurin\n\n🦠 **بیکٹیریل بیماریاں:**\n• تانبے کا بیکٹیریسائیڈ، streptomycin\n\n🦠 **وائرل بیماریاں:**\n• کیڑوں کو کنٹرول کریں — کوئی براہ راست علاج نہیں\n\n🕷️ **ذرات (مائٹس):**\n• abamectin، bifenazate\n\n⚠️ **اہم:** ہمیشہ لیبل کی ہدایات پر عمل کریں اور خوراک درست رکھیں!\n\n💡 **ٹپ:** پہلے AgriGuard سے بیماری کی شناخت کریں!"
          : "💊 **General Treatment Guide**\n\n🍄 **Fungal Diseases:**\n• Copper fungicides, mancozeb, triazoles, strobilurin\n\n🦠 **Bacterial Diseases:**\n• Copper bactericides, streptomycin\n\n🦠 **Viral Diseases:**\n• Control insect vectors — no direct cure exists\n\n🕷️ **Mites:**\n• Abamectin, bifenazate miticides\n\n⚠️ **Important:** Always follow label dosage instructions!\n\n💡 **Tip:** Scan with AgriGuard first to identify the exact disease!";
    }

    // ── Default ──────────────────────────────────────────────────────────────
    return isUrduQuery
        ? "🌱 **میں مدد کر سکتا ہوں!**\n\nمجھ سے پوچھیں:\n• کسی بھی پودے کی بیماری کے بارے میں\n• AgriGuard کے استعمال کے بارے میں\n• کسی بھی فصل کی دیکھ بھال کے بارے میں\n\nیا AgriGuard سے اپنے پودے کو اسکین کریں!"
        : "🌱 **I'm here to help!**\n\nAsk me about:\n• Any plant disease (Bean, Corn, Fig, Grape, Walnut, Tomato + more)\n• How to use AgriGuard features\n• General crop care & treatment advice\n\nOr scan your plant with AgriGuard for instant AI diagnosis!";
  }
}
