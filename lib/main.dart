/// SimpleMed Radiology - Main Application
///
/// JAVA DEVELOPER NOTES:
///
/// 1. WIDGET TREE:
///    Flutter uses a declarative UI paradigm. Instead of imperatively updating
///    views (like Android's `textView.setText("Hello")`), you describe what the
///    UI should look like for a given state, and Flutter handles updates.
///
///    Everything is a Widget (similar to View in Android). Widgets are immutable
///    and describe the UI. Flutter rebuilds the widget tree when state changes.
///
/// 2. BUILD METHOD:
///    `Widget build(BuildContext context)` is called whenever the widget needs
///    to be rendered. It returns a widget tree describing the UI.
///    Think of it like: "given this state, what should my UI look like?"
///
/// 3. STATE MANAGEMENT:
///    - `StatelessWidget`: Immutable widget, no internal state (like a pure function)
///    - `StatefulWidget`: Has mutable state via `State` class
///    - `Provider`: External state management (like Android ViewModel + LiveData)
///
/// 4. CONTEXT:
///    `BuildContext` provides access to the widget's location in the tree.
///    Used to access inherited widgets (like Theme, Navigator, Provider data).
///    Similar to Android's Context but more specific to widget tree location.
///
/// 5. CONST CONSTRUCTORS:
///    `const` widgets are compile-time constants - Flutter reuses them for
///    performance. Use when widget and all children are immutable.

library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models.dart';
import 'data_service.dart';

// ============================================================================
// NHS BRAND COLORS
// ============================================================================

/// NHS Brand colors as static constants.
/// In Java, these would be `public static final` fields.
class NHSColors {
  // Private constructor prevents instantiation (utility class pattern)
  NHSColors._();

  static const Color primary = Color(0xFF005EB8); // NHS Blue
  static const Color secondary = Color(0xFF003087); // NHS Dark Blue
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF0F4F5);
  static const Color darkGrey = Color(0xFF425563);

  // Traffic light colors for safety indicators
  static const Color green = Color(0xFF00703C);
  static const Color amber = Color(0xFFFFB81C);
  static const Color red = Color(0xFFDA291C);
}

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

/// Application entry point.
/// `main()` is the starting function (like Java's `public static void main`).
/// `runApp()` inflates the widget and attaches it to the screen.
void main() {
  runApp(const SimpleMedApp());
}

/// Root application widget.
///
/// `ChangeNotifierProvider` wraps the app to provide data access to all
/// descendant widgets. Similar to Dagger's dependency injection in Android.
///
/// Widget tree:
/// ```
/// ChangeNotifierProvider
///   └── MaterialApp
///         └── HomeScreen
///               └── (child widgets...)
/// ```
class SimpleMedApp extends StatelessWidget {
  const SimpleMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider creates and manages the DataProvider instance.
    // Any descendant widget can access it via Provider.of or Consumer.
    //
    // JAVA COMPARISON:
    // Similar to using Dagger @Singleton + @Provides for dependency injection,
    // but declaratively in the widget tree.
    return ChangeNotifierProvider(
      // `create` is called once when the widget is first built
      // The `..` cascade operator calls loadData() and returns the provider
      create: (context) => DataProvider()..loadData(),
      child: MaterialApp(
        title: 'SimpleMed Radiology',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  /// Builds the app's visual theme.
  /// Similar to Android's `styles.xml` but defined in Dart code.
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NHSColors.primary,
        primary: NHSColors.primary,
        secondary: NHSColors.secondary,
      ),
      // Google Fonts provides the Lato font family
      textTheme: GoogleFonts.latoTextTheme(),
      scaffoldBackgroundColor: NHSColors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: NHSColors.primary,
        foregroundColor: NHSColors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NHSColors.white,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ============================================================================
// HOME SCREEN
// ============================================================================

/// Main home screen displaying search bar and scan list grouped by category.
///
/// `StatefulWidget` because we need to track search query state.
///
/// JAVA COMPARISON:
/// StatefulWidget is like an Android Activity or Fragment with a ViewModel.
/// The State class holds the mutable data (like ViewModel fields).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The state class for HomeScreen.
/// Prefix with underscore to make it private to this file.
class _HomeScreenState extends State<HomeScreen> {
  /// TextEditingController manages the text field's content.
  /// Similar to Android's EditText.getText()/setText().
  final TextEditingController _searchController = TextEditingController();

  /// Current search query (empty string means show all).
  String _searchQuery = '';

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks
    // Similar to nullifying references in Java or using WeakReferences
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpleMed Radiology'),
        centerTitle: true,
      ),
      // Consumer listens to DataProvider changes and rebuilds when notified.
      //
      // JAVA COMPARISON:
      // Similar to observing LiveData:
      // ```java
      // viewModel.getData().observe(this, data -> updateUI(data));
      // ```
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const _LoadingWidget();
          }

          if (dataProvider.hasError) {
            return _ErrorWidget(
              message: dataProvider.errorMessage ?? 'Unknown error',
              onRetry: () => dataProvider.refreshData(),
            );
          }

          if (!dataProvider.hasData) {
            return const _EmptyWidget();
          }

          // Show either search results or full category list
          return _buildContent(dataProvider);
        },
      ),
    );
  }

  /// Builds the main content with search bar and scan list.
  Widget _buildContent(DataProvider dataProvider) {
    return Column(
      children: [
        // Search bar
        _SearchBar(
          controller: _searchController,
          onChanged: (query) {
            // setState triggers a rebuild with new _searchQuery value
            // Similar to calling LiveData.setValue() in Android ViewModel
            setState(() {
              _searchQuery = query;
            });
          },
        ),

        // Scan list (expands to fill remaining space)
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildCategoryList(dataProvider)
              : _buildSearchResults(dataProvider),
        ),
      ],
    );
  }

  /// Builds the grouped list of scans by category.
  Widget _buildCategoryList(DataProvider dataProvider) {
    final sections = dataProvider.appData!.sections;

    // RefreshIndicator enables pull-to-refresh gesture
    return RefreshIndicator(
      onRefresh: () => dataProvider.refreshData(),
      color: NHSColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        // Total items = sections + scans in each section + header for each section
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          final section = sections[sectionIndex];
          return _CategorySection(section: section);
        },
      ),
    );
  }

  /// Builds search results list.
  Widget _buildSearchResults(DataProvider dataProvider) {
    final results = dataProvider.searchScans(_searchQuery);

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: NHSColors.darkGrey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No scans found for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: NHSColors.darkGrey.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _ScanCard(
          scan: result.scan,
          categoryColor: _parseColor(result.categoryColor),
          categoryName: result.categoryName,
        );
      },
    );
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

/// Search bar widget with NHS styling.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: NHSColors.lightGrey,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search scans...',
          prefixIcon: const Icon(Icons.search, color: NHSColors.primary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: NHSColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// A category section with header and scan cards.
class _CategorySection extends StatelessWidget {
  final Section section;

  const _CategorySection({required this.section});

  @override
  Widget build(BuildContext context) {
    final categoryColor = _parseColor(section.colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(color: categoryColor, width: 4),
            ),
          ),
          child: Text(
            section.categoryName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: categoryColor,
            ),
          ),
        ),

        // Scan cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: section.scans.map((scan) {
              return _ScanCard(
                scan: scan,
                categoryColor: categoryColor,
                categoryName: section.categoryName,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Card widget displaying a scan summary.
/// Tapping navigates to the detail screen.
class _ScanCard extends StatelessWidget {
  final Scan scan;
  final Color categoryColor;
  final String categoryName;

  const _ScanCard({
    required this.scan,
    required this.categoryColor,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // onTap callback - similar to Android's setOnClickListener
        onTap: () => _navigateToDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon/thumbnail
              _buildIcon(),
              const SizedBox(width: 16),

              // Title and summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scan.shortSummary,
                      style: TextStyle(
                        fontSize: 14,
                        color: NHSColors.darkGrey.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(
                Icons.chevron_right,
                color: NHSColors.darkGrey.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the scan icon with caching.
  Widget _buildIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: scan.media.iconUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // CachedNetworkImage caches images to disk for offline use.
              // Similar to Android's Glide or Picasso libraries.
              child: CachedNetworkImage(
                imageUrl: scan.media.iconUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.medical_services_outlined,
                  color: categoryColor,
                  size: 32,
                ),
              ),
            )
          : Icon(
              Icons.medical_services_outlined,
              color: categoryColor,
              size: 32,
            ),
    );
  }

  /// Navigates to the detail screen.
  ///
  /// JAVA COMPARISON:
  /// Similar to Android's:
  /// ```java
  /// Intent intent = new Intent(this, DetailActivity.class);
  /// intent.putExtra("scan", scan);
  /// startActivity(intent);
  /// ```
  ///
  /// In Flutter, we push a new route onto the Navigator stack.
  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          scan: scan,
          categoryColor: categoryColor,
          categoryName: categoryName,
        ),
      ),
    );
  }
}

/// Loading indicator widget.
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NHSColors.primary),
          SizedBox(height: 16),
          Text('Loading scan information...'),
        ],
      ),
    );
  }
}

/// Error display widget with retry button.
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: NHSColors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget.
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: NHSColors.darkGrey),
            SizedBox(height: 16),
            Text(
              'No scan information available',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DETAIL SCREEN
// ============================================================================

/// Detail screen showing full scan information.
class DetailScreen extends StatelessWidget {
  final Scan scan;
  final Color categoryColor;
  final String categoryName;

  const DetailScreen({
    super.key,
    required this.scan,
    required this.categoryColor,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        // CustomScrollView enables sliver-based scrolling with collapsing app bar
        slivers: [
          // Collapsing app bar with hero image
          _buildSliverAppBar(context),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  _buildCategoryTag(),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    scan.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Summary
                  Text(
                    scan.shortSummary,
                    style: TextStyle(
                      fontSize: 18,
                      color: NHSColors.darkGrey.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full description
                  Text(
                    scan.fullDescription,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Traffic light safety box
                  SafetyInfoBox(safety: scan.safety),
                  const SizedBox(height: 24),

                  // Preparation info
                  _InfoBlock(
                    title: 'Preparation',
                    icon: Icons.checklist,
                    color: NHSColors.primary,
                    children: [
                      _InfoRow(
                        label: 'Fasting',
                        value: scan.preparation.requiresFasting
                            ? '${scan.preparation.fastingHours} hours before'
                            : 'Not required',
                        icon: Icons.restaurant,
                      ),
                      _InfoRow(
                        label: 'Bladder',
                        value: scan.preparation.bladder,
                        icon: Icons.water_drop,
                      ),
                      if (scan.preparation.instructions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            scan.preparation.instructions,
                            style: TextStyle(
                              fontSize: 14,
                              color: NHSColors.darkGrey.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Logistics info
                  _InfoBlock(
                    title: 'What to Expect',
                    icon: Icons.schedule,
                    color: NHSColors.secondary,
                    children: [
                      _InfoRow(
                        label: 'Duration',
                        value: '${scan.logistics.durationMinutes} minutes',
                        icon: Icons.timer_outlined,
                      ),
                      _InfoRow(
                        label: 'Noise Level',
                        value: scan.logistics.noiseLevel,
                        icon: Icons.volume_up,
                      ),
                      _InfoRow(
                        label: 'Claustrophobia Risk',
                        value: scan.logistics.claustrophobiaRisk,
                        icon: Icons.sentiment_satisfied_alt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the collapsing app bar with hero image.
  Widget _buildSliverAppBar(BuildContext context) {
    // Calculate height based on aspect ratio
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth / scan.media.heroAspectRatio;

    return SliverAppBar(
      expandedHeight: imageHeight.clamp(200.0, 400.0),
      pinned: true,
      backgroundColor: categoryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: scan.media.heroImageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: scan.media.heroImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: categoryColor.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: NHSColors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: categoryColor.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.medical_services,
                    size: 64,
                    color: NHSColors.white.withValues(alpha: 0.7),
                  ),
                ),
              )
            : Container(
                color: categoryColor.withValues(alpha: 0.3),
                child: Icon(
                  Icons.medical_services,
                  size: 64,
                  color: NHSColors.white.withValues(alpha: 0.7),
                ),
              ),
      ),
    );
  }

  /// Builds the category tag chip.
  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        categoryName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: categoryColor,
        ),
      ),
    );
  }
}

// ============================================================================
// SAFETY INFO BOX (Traffic Light Widget)
// ============================================================================

/// Traffic light safety indicator widget.
///
/// Displays safety information with color-coded indicators:
/// - Green: Low risk/safe
/// - Amber: Moderate risk/caution
/// - Red: High risk/warning
class SafetyInfoBox extends StatelessWidget {
  final Safety safety;

  const SafetyInfoBox({super.key, required this.safety});

  @override
  Widget build(BuildContext context) {
    final radiationColor = _getRadiationColor(safety.radiationLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: radiationColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: radiationColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with traffic light
          Row(
            children: [
              _TrafficLight(activeLevel: safety.radiationLevel),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safety Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Radiation Level: ${safety.radiationLevel}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: radiationColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (safety.radiationNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              safety.radiationNote,
              style: TextStyle(
                fontSize: 14,
                color: NHSColors.darkGrey.withValues(alpha: 0.8),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Warning indicators
          Row(
            children: [
              Expanded(
                child: _SafetyIndicator(
                  icon: Icons.science_outlined,
                  label: 'Contrast Dye',
                  isRisk: safety.contrastRisk,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SafetyIndicator(
                  icon: Icons.pregnant_woman,
                  label: 'Pregnancy',
                  isRisk: !safety.pregnancySafe,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns color based on radiation level.
  Color _getRadiationColor(String level) {
    switch (level.toLowerCase()) {
      case 'green':
        return NHSColors.green;
      case 'amber':
      case 'orange':
        return NHSColors.amber;
      case 'red':
        return NHSColors.red;
      default:
        return NHSColors.green;
    }
  }
}

/// Visual traffic light indicator widget.
class _TrafficLight extends StatelessWidget {
  final String activeLevel;

  const _TrafficLight({required this.activeLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: NHSColors.darkGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLight(NHSColors.red, activeLevel.toLowerCase() == 'red'),
          const SizedBox(height: 4),
          _buildLight(NHSColors.amber, activeLevel.toLowerCase() == 'amber'),
          const SizedBox(height: 4),
          _buildLight(NHSColors.green, activeLevel.toLowerCase() == 'green'),
        ],
      ),
    );
  }

  Widget _buildLight(Color color, bool isActive) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? color : color.withValues(alpha: 0.2),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Individual safety indicator (e.g., contrast risk, pregnancy).
class _SafetyIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isRisk;

  const _SafetyIndicator({
    required this.icon,
    required this.label,
    required this.isRisk,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRisk ? NHSColors.red : NHSColors.green;
    final statusText = isRisk ? 'Caution' : 'Safe';

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// INFO BLOCKS
// ============================================================================

/// Reusable info block container with title and icon.
class _InfoBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _InfoBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NHSColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Row displaying a label-value pair with an icon.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: NHSColors.darkGrey.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: NHSColors.darkGrey.withValues(alpha: 0.8),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Parses hex color string to Color object.
///
/// JAVA COMPARISON:
/// Similar to Android's `Color.parseColor("#RRGGBB")`.
///
/// Dart doesn't have a built-in hex parser, so we implement it manually.
Color _parseColor(String hexString) {
  // Remove # prefix if present
  final hex = hexString.replaceFirst('#', '');

  // Parse as integer with radix 16 (hexadecimal)
  // `0xFF` prefix adds full opacity (alpha = 255)
  try {
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  } catch (e) {
    // Return default color if parsing fails
  }
  return NHSColors.primary;
}
