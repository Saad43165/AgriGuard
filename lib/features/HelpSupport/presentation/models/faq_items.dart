import 'faq_category.dart';

class FaqItem {
  final String question;
  final String answer;
  final FaqCategory category;
  final List<String> tags;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
  });
}