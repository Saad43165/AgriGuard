import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'glass_card.dart';

// FAQ Item Model
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

// FAQ Categories
enum FaqCategory {
  general('General', Icons.help_outline_rounded),
  scanning('Plant Scanning', Icons.camera_alt_rounded),
  database('Database', Icons.storage_rounded),
  account('Account', Icons.person_outline_rounded),
  technical('Technical', Icons.settings_rounded),
  sharing('Sharing', Icons.share_rounded);

  const FaqCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

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
  bool _isSearching = false;

  // Comprehensive FAQ data
  static final List<FaqItem> _allFaqItems = [
    // General FAQs
    FaqItem(
      question: 'What is this plant identification app?',
      answer: 'Our app uses advanced AI technology to identify plants from photos. Simply take a picture of any plant, and our system will provide detailed information including species name, care instructions, and interesting facts.',
      category: FaqCategory.general,
      tags: ['identification', 'AI', 'plants'],
    ),
    FaqItem(
      question: 'How accurate is the plant identification?',
      answer: 'Our AI model has over 95% accuracy for common plants and flowers. The accuracy depends on photo quality, lighting, and how clearly the plant features are visible. For best results, capture clear images of leaves, flowers, or distinctive features.',
      category: FaqCategory.general,
      tags: ['accuracy', 'AI', 'reliability'],
    ),
    FaqItem(
      question: 'Is the app free to use?',
      answer: 'The app offers both free and premium features. Basic plant identification is free with limited daily scans. Premium subscription unlocks unlimited scans, detailed care guides, disease detection, and priority support.',
      category: FaqCategory.general,
      tags: ['pricing', 'premium', 'subscription'],
    ),

    // Scanning FAQs
    FaqItem(
      question: 'How do I take the best photo for identification?',
      answer: 'For optimal results: 1) Use natural lighting or bright indoor light, 2) Fill the frame with the plant, 3) Focus on distinctive features like leaves, flowers, or bark, 4) Avoid shadows and blur, 5) Take multiple angles if needed.',
      category: FaqCategory.scanning,
      tags: ['photography', 'tips', 'lighting'],
    ),
    FaqItem(
      question: 'What should I do if the scan fails?',
      answer: 'If scanning fails: 1) Check your internet connection, 2) Ensure good lighting, 3) Clean your camera lens, 4) Try focusing on different plant parts, 5) Restart the app if issues persist, 6) Contact support for technical problems.',
      category: FaqCategory.scanning,
      tags: ['troubleshooting', 'errors', 'support'],
    ),
    FaqItem(
      question: 'Can I scan multiple plants in one photo?',
      answer: 'For best accuracy, focus on one plant per photo. If multiple plants are present, the AI might identify the most prominent one. Use the crop feature to isolate specific plants before scanning.',
      category: FaqCategory.scanning,
      tags: ['multiple plants', 'cropping', 'focus'],
    ),

    // Database FAQs
    FaqItem(
      question: 'How do I update the plant database?',
      answer: 'The plant database updates automatically with each app update. You can manually check for updates in Settings > Database > Check for Updates. New species and improved identification models are added monthly.',
      category: FaqCategory.database,
      tags: ['updates', 'database', 'species'],
    ),
    FaqItem(
      question: 'How many plant species can the app identify?',
      answer: 'Our database contains over 30,000 plant species including flowers, trees, shrubs, houseplants, succulents, and weeds. We continuously add new species based on user requests and regional needs.',
      category: FaqCategory.database,
      tags: ['species count', 'coverage', 'variety'],
    ),
    FaqItem(
      question: 'Can I use the app offline?',
      answer: 'Limited offline functionality is available. You can view previously identified plants and saved information without internet. However, new plant identification and database access require an active internet connection.',
      category: FaqCategory.database,
      tags: ['offline', 'internet', 'connectivity'],
    ),

    // Account FAQs
    FaqItem(
      question: 'How do I create an account?',
      answer: 'Tap "Sign Up" on the welcome screen. You can register with email, Google, or Apple ID. Creating an account lets you save identifications, sync across devices, and access premium features.',
      category: FaqCategory.account,
      tags: ['registration', 'sign up', 'sync'],
    ),
    FaqItem(
      question: 'How do I reset my password?',
      answer: 'On the login screen, tap "Forgot Password" and enter your email. Follow the reset instructions sent to your email. If you don\'t receive the email, check your spam folder or contact support.',
      category: FaqCategory.account,
      tags: ['password', 'reset', 'email'],
    ),
    FaqItem(
      question: 'How do I delete my account?',
      answer: 'Go to Settings > Account > Delete Account. This will permanently remove all your data including scan history and saved plants. This action cannot be undone.',
      category: FaqCategory.account,
      tags: ['delete account', 'data removal', 'permanent'],
    ),

    // Technical FAQs
    FaqItem(
      question: 'Does the app support multiple languages?',
      answer: 'Yes, the app supports 15+ languages including English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, and more. Change language in Settings > Language & Region.',
      category: FaqCategory.technical,
      tags: ['languages', 'international', 'localization'],
    ),
    FaqItem(
      question: 'What are the system requirements?',
      answer: 'iOS: Requires iOS 13.0 or later. Android: Requires Android 7.0 (API level 24) or later. Camera access and internet connection required for full functionality.',
      category: FaqCategory.technical,
      tags: ['requirements', 'compatibility', 'system'],
    ),
    FaqItem(
      question: 'Why is the app using so much storage?',
      answer: 'Storage usage includes cached plant data for faster loading, saved scan history, and downloaded offline content. Clear cache in Settings > Storage to free up space while keeping your important data.',
      category: FaqCategory.technical,
      tags: ['storage', 'cache', 'space'],
    ),

    // Sharing FAQs
    FaqItem(
      question: 'How do I share my scan results?',
      answer: 'From any identification result, tap the share icon. You can share via social media, email, messaging, or save to your photo gallery. Choose to include or exclude detailed plant information.',
      category: FaqCategory.sharing,
      tags: ['sharing', 'social media', 'export'],
    ),
    FaqItem(
      question: 'Can I export my scan history?',
      answer: 'Yes! Go to Settings > Data Export to download your complete scan history as a PDF or CSV file. This includes all identified plants, dates, locations, and notes.',
      category: FaqCategory.sharing,
      tags: ['export', 'history', 'backup'],
    ),
  ];

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
    _filteredFaqItems = _allFaqItems;
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
      _filteredFaqItems = _allFaqItems.where((faq) {
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
    HapticFeedback.selectionClick();
  }

  Widget _buildSearchBar() {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return GlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: itemSpacing),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => _filterFaqs(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
          ),
          decoration: InputDecoration(
            hintText: 'Search FAQs...',
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(
                Icons.clear_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                _searchController.clear();
                _filterFaqs();
                HapticFeedback.lightImpact();
              },
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: itemSpacing),
        itemCount: FaqCategory.values.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" category
            bool isSelected = _selectedCategory == null;
            return Padding(
              padding: EdgeInsets.only(right: itemSpacing / 2),
              child: FilterChip(
                selected: isSelected,
                label: Text('All'),
                avatar: Icon(
                  Icons.apps_rounded,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                onSelected: (_) => _selectCategory(null),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          FaqCategory category = FaqCategory.values[index - 1];
          bool isSelected = _selectedCategory == category;

          return Padding(
            padding: EdgeInsets.only(right: itemSpacing / 2),
            child: FilterChip(
              selected: isSelected,
              label: Text(category.label),
              avatar: Icon(
                category.icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onSelected: (_) => _selectCategory(category),
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqItem(FaqItem faq, int index) {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        )),
        child: GlassCard(
          borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              leading: Container(
                padding: EdgeInsets.all(itemSpacing / 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Icon(
                  faq.category.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                ),
              ),
              title: Text(
                faq.question,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  faq.category.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                  ),
                ),
              ),
              trailing: Icon(
                Icons.expand_more_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              childrenPadding: EdgeInsets.fromLTRB(
                itemSpacing * 3.5, 0, itemSpacing, itemSpacing,
              ),
              onExpansionChanged: (expanded) {
                if (expanded) HapticFeedback.lightImpact();
              },
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq.answer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                      height: 1.5,
                    ),
                  ),
                ),
                if (faq.tags.isNotEmpty) ...[
                  SizedBox(height: itemSpacing),
                  Wrap(
                    spacing: itemSpacing / 2,
                    runSpacing: itemSpacing / 3,
                    children: faq.tags.map((tag) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: itemSpacing / 2,
                        vertical: itemSpacing / 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 11),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
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
        ),
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
                child: _buildSearchBar(),
              ),

              // Category Filters
              _buildCategoryFilters(),

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
                    ? Center(
                  child: GlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(itemSpacing * 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          SizedBox(height: itemSpacing),
                          Text(
                            'No FAQs found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: itemSpacing / 2),
                          Text(
                            'Try adjusting your search or category filter',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : ListView.separated(
                  padding: EdgeInsets.all(itemSpacing),
                  itemCount: _filteredFaqItems.length,
                  separatorBuilder: (context, index) => SizedBox(height: itemSpacing),
                  itemBuilder: (context, index) {
                    return _buildFaqItem(_filteredFaqItems[index], index);
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