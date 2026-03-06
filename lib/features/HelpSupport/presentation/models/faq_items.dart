// lib/features/support/models/faq_items.dart
import 'faq_category.dart';

class FaqItem {
  final String questionEn;
  final String questionUr;
  final String answerEn;
  final String answerUr;
  final FaqCategory category;
  final List<String> tags;

  FaqItem({
    required this.questionEn,
    required this.questionUr,
    required this.answerEn,
    required this.answerUr,
    required this.category,
    required this.tags,
  });

  // Get question in current language
  String getQuestion(bool isUrdu) => isUrdu ? questionUr : questionEn;

  // Get answer in current language
  String getAnswer(bool isUrdu) => isUrdu ? answerUr : answerEn;
}