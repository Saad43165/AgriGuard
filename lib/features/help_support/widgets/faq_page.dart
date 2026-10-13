// lib/features/support/widgets/faq_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import '../models/faq_category.dart';
import '../models/faq_data.dart';
import '../models/faq_items.dart';
import 'faq_category_filters.dart';
import 'faq_empty_state.dart';
import 'faq_list_item.dart';
import 'faq_search_bar.dart';
import 'support_app_bar.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FaqItem> _filteredFaqs = [];
  FaqCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _filteredFaqs = FaqData.allFaqItems;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterFaqs(TranslationService translation) {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredFaqs = FaqData.allFaqItems.where((faq) {
        // Filter by category first
        if (_selectedCategory != null && faq.category != _selectedCategory) {
          return false;
        }

        // Then filter by search query if exists
        if (query.isEmpty) return true;

        final question = faq.getQuestion(translation.isUrdu).toLowerCase();
        final answer = faq.getAnswer(translation.isUrdu).toLowerCase();
        final tags = faq.tags.join(' ').toLowerCase();

        return question.contains(query) ||
            answer.contains(query) ||
            tags.contains(query);
      }).toList();
    });
  }

  void _onCategorySelected(FaqCategory? category) {
    setState(() => _selectedCategory = category);
    _filterFaqs(Provider.of<TranslationService>(context, listen: false));
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
      _filteredFaqs = FaqData.allFaqItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: translation.get('all_faqs'),
        showLanguageToggle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: isDark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F23),
            ]
                : [
              const Color(0xFFF5F7FA),
              const Color(0xFFE8EDF2),
              const Color(0xFFF0F4F8),
              const Color(0xFFF5F7FA),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: FaqSearchBar(
                  controller: _searchController,
                  onSearchChanged: () => _filterFaqs(translation),
                  onClear: _clearFilters,
                ),
              ),

              // Category Filters
              FaqCategoryFilters(
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),

              const SizedBox(height: 12),

              // Results Count & Clear Filter Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredFaqs.length} ${_filteredFaqs.length == 1 ? translation.get('faq_result_one') : translation.get('faq_result_many')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory != null || _searchController.text.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: Text(
                          translation.get('clear_filters'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // FAQ List
              Expanded(
                child: _filteredFaqs.isEmpty
                    ? const FaqEmptyState()
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final faq = _filteredFaqs[index];
                    return FaqListItem(
                      faq: faq,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}