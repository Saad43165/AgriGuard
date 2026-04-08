// lib/features/home/screens/species/species_grid_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import 'plant_species.dart';

class SpeciesGridWidget extends StatelessWidget {
  const SpeciesGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: AppSpecies.allSpecies.length,
        itemBuilder: (context, index) {
          final species = AppSpecies.allSpecies[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < AppSpecies.allSpecies.length - 1 ? 8 : 0,
            ),
            child: _ModernSpeciesCard(species: species),
          );
        },
      ),
    );
  }
}

class _ModernSpeciesCard extends StatefulWidget {
  final PlantSpecies species;

  const _ModernSpeciesCard({required this.species});

  @override
  State<_ModernSpeciesCard> createState() => _ModernSpeciesCardState();
}

class _ModernSpeciesCardState extends State<_ModernSpeciesCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<TranslationService>(
      builder: (context, translation, _) {
        return GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: () => _showSpeciesDetails(context),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    widget.species.color.withOpacity(0.25),
                    widget.species.color.withOpacity(0.15),
                  ]
                      : [
                    Colors.white,
                    widget.species.color.withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isPressed
                      ? widget.species.color.withOpacity(0.6)
                      : widget.species.color.withOpacity(0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                    widget.species.color.withOpacity(_isPressed ? 0.35 : 0.2),
                    blurRadius: _isPressed ? 12 : 10,
                    offset: Offset(0, _isPressed ? 4 : 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'species_${widget.species.nameEn}',
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.species.color.withOpacity(0.25),
                              widget.species.color.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.species.color.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(
                            widget.species.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.eco,
                                color: widget.species.color,
                                size: 18,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.species.getName(translation.isUrdu),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSpeciesDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.species.color.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Content
                Expanded(
                  child: Consumer<TranslationService>(
                    builder: (context, trans, _) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Hero(
                                  tag: 'species_${widget.species.nameEn}',
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          widget.species.color.withOpacity(0.3),
                                          widget.species.color.withOpacity(0.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: widget.species.color
                                            .withOpacity(0.4),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.species.color
                                              .withOpacity(0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Image.asset(
                                      widget.species.imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Icons.eco,
                                          color: widget.species.color,
                                          size: 36,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.species.color
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: widget.species.color
                                                .withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          trans
                                              .get('plant_species_label')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: widget.species.color,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.species.getName(trans.isUrdu),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.species.scientificName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Info Sections
                            _buildModernInfoSection(
                              context,
                              icon: Icons.info_outline_rounded,
                              title: trans.get('about_plant'),
                              content:
                              widget.species.getDescription(trans.isUrdu),
                              color: Colors.blue,
                            ),

                            const SizedBox(height: 12),

                            _buildModernInfoSection(
                              context,
                              icon: Icons.wb_sunny_rounded,
                              title: trans.get('growth_requirements'),
                              content: widget.species.getGrowthInfo(trans.isUrdu),
                              color: Colors.orange,
                            ),

                            const SizedBox(height: 12),

                            _buildModernInfoSection(
                              context,
                              icon: Icons.bug_report_rounded,
                              title: trans.get('common_diseases'),
                              content: widget.species
                                  .getCommonDiseases(trans.isUrdu),
                              color: Colors.red,
                            ),

                            const SizedBox(height: 20),

                            // Action Button
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.species.color,
                                    widget.species.color.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    widget.species.color.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/capture');
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          trans.get('start_disease_detection'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernInfoSection(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String content,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.75),
                    height: 1.4,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}