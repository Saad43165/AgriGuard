import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'plant_species.dart';

class SpeciesGridWidget extends StatelessWidget {
  const SpeciesGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detectable Species',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 20,
                        ),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view detailed information',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: AppMeasurements.getResponsiveFontSize(
                          context,
                          baseSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${AppSpecies.allSpecies.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: AppSpecies.allSpecies.length,
            itemBuilder: (context, index) {
              final species = AppSpecies.allSpecies[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < AppSpecies.allSpecies.length - 1 ? 12 : 0,
                ),
                child: _SpeciesCard(species: species),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpeciesCard extends StatefulWidget {
  final PlantSpecies species;

  const _SpeciesCard({required this.species});

  @override
  State<_SpeciesCard> createState() => _SpeciesCardState();
}

class _SpeciesCardState extends State<_SpeciesCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        _showSpeciesDetails(context);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 95,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? widget.species.color.withOpacity(0.4)
                  : widget.species.color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? widget.species.color.withOpacity(0.25)
                    : widget.species.color.withOpacity(0.12),
                blurRadius: _isPressed ? 12 : 8,
                offset: Offset(0, _isPressed ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'species_${widget.species.name}',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.species.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      widget.species.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.eco,
                          color: widget.species.color,
                          size: 32,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.species.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image and Title Section
                      Center(
                        child: Column(
                          children: [
                            Hero(
                              tag: 'species_${widget.species.name}',
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.species.color.withOpacity(0.15),
                                      widget.species.color.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.species.color.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  widget.species.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.eco,
                                      color: widget.species.color,
                                      size: 60,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.species.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.species.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.species.scientificName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Description Section
                      _InfoSection(
                        icon: Icons.info_outline,
                        title: 'About',
                        color: widget.species.color,
                        content: widget.species.description,
                      ),
                      const SizedBox(height: 20),

                      // Growth Information Section
                      _InfoSection(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Growth Requirements',
                        color: widget.species.color,
                        content: widget.species.growthInfo,
                      ),
                      const SizedBox(height: 20),

                      // Common Diseases Section
                      _InfoSection(
                        icon: Icons.bug_report_outlined,
                        title: 'Common Diseases',
                        color: widget.species.color,
                        content: widget.species.commonDiseases,
                      ),
                      const SizedBox(height: 32),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/capture');
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Start Disease Detection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.species.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String content;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}