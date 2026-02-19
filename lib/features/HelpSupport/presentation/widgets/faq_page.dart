// lib/features/support/widgets/faq_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../models/faq_category.dart';
import '../models/faq_data.dart';
import '../models/faq_items.dart';
import 'faq_category_filters.dart';
import 'faq_empty_state.dart';
import 'faq_list_item.dart';
import 'faq_search_bar.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> with TickerProviderStateMixin {
  late TextEditingController _searchController;
  FaqCategory? _selectedCategory;
  List<FaqItem> _filteredFaqItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredFaqItems = FaqData.allFaqItems;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFaqs() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      _filteredFaqItems = FaqData.allFaqItems.where((faq) {
        bool matchesCategory =
            _selectedCategory == null || faq.category == _selectedCategory;
        bool matchesSearch = query.isEmpty ||
            faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query) ||
            faq.tags.any((tag) => tag.toLowerCase().contains(query));

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _selectCategory(FaqCategory? category) {
    setState(() => _selectedCategory = category);
    _filterFaqs();
  }

  void _clearSearch() {
    _searchController.clear();
    _filterFaqs();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: FaqSearchBar(
                controller: _searchController,
                onSearchChanged: _filterFaqs,
                onClear: _clearSearch,
              ),
            ),

            // Category Filters
            FaqCategoryFilters(
              selectedCategory: _selectedCategory,
              onCategorySelected: _selectCategory,
            ),

            const SizedBox(height: 16),

            // Results Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_filteredFaqItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _filteredFaqItems.length == 1 ? 'result found' : 'results found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // FAQ List
            Expanded(
              child: _filteredFaqItems.isEmpty
                  ? const FaqEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filteredFaqItems.length,
                itemBuilder: (context, index) {
                  return FaqListItem(
                    faq: _filteredFaqItems[index],
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 8),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (LEFT)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Title (CENTER)
              Expanded(
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'FAQs',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Spacer (RIGHT) - to keep title centered
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}