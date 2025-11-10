import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/glass_card.dart';
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  FaqCategory? _selectedCategory;
  List<FaqItem> _filteredFaqItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _filteredFaqItems = FaqData.allFaqItems;
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterFaqs() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      _filteredFaqItems = FaqData.allFaqItems.where((faq) {
        // Add null safety checks
        if (faq == null) return false;

        bool matchesCategory = _selectedCategory == null || faq.category == _selectedCategory;
        bool matchesSearch = query.isEmpty ||
            faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query) ||
            faq.tags.any((tag) => tag.toLowerCase().contains(query));

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }
  void _selectCategory(FaqCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterFaqs();
  }

  void _clearSearch() {
    _searchController.clear();
    _filterFaqs();
  }

  Widget _buildAppBar() {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          label: 'FAQ page with back button',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
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
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 26),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
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
                    width: 1,
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
                      padding: EdgeInsets.all(itemSpacing * 0.5),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(itemSpacing),
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

              SizedBox(height: itemSpacing),

              // Results Counter
              Padding(
                padding: EdgeInsets.symmetric(horizontal: itemSpacing),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredFaqItems.length} result${_filteredFaqItems.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: itemSpacing / 2),

              // FAQ List
              Expanded(
                child: _filteredFaqItems.isEmpty
                    ? const FaqEmptyState()
                    : ListView.separated(
                  padding: EdgeInsets.all(itemSpacing),
                  itemCount: _filteredFaqItems.length,
                  separatorBuilder: (context, index) => SizedBox(height: itemSpacing),
                  itemBuilder: (context, index) {
                    return FaqListItem(
                      faq: _filteredFaqItems[index],
                      index: index,
                      fadeAnimation: _fadeAnimation,
                      animationController: _animationController,
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