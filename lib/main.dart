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
///
/// 6. ACCESSIBILITY (a11y):
///    Flutter provides built-in accessibility through `Semantics` widgets.
///    These provide labels for screen readers (TalkBack on Android, VoiceOver on iOS).
///    Similar to Android's `contentDescription` attribute.

library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'models.dart';
import 'data_service.dart';

// ============================================================================
// SIMPLEMED BRAND COLORS
// ============================================================================

/// SimpleMed brand colors as static constants.
/// In Java, these would be `public static final` fields.
class AppColors {
  // Private constructor prevents instantiation (utility class pattern)
  AppColors._();

  static const Color primary = Color(0xFF03CCBD); // SimpleMed Teal
  static const Color secondary = Color(0xFF0B858A); // Dark Teal
  static const Color accent = Color(0xFF03E16D); // Green accent
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF9FAFC);
  static const Color darkGrey = Color(0xFF696969);

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
        title: 'SimpleRad',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        // Enable dynamic text scaling for accessibility
        // Users can set larger text in system settings
        builder: (context, child) {
          // Get the system text scale factor
          final mediaQuery = MediaQuery.of(context);

          // Cap the text scale to prevent layout issues with very large text
          // but still allow significant scaling for accessibility
          final cappedTextScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.5,
          );

          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: cappedTextScaler),
            child: child!,
          );
        },
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
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
      ),
      // Google Fonts provides the Lato font family
      textTheme: GoogleFonts.latoTextTheme(),
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
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
// HOME SCREEN WITH BOTTOM NAVIGATION
// ============================================================================

/// Main home screen with bottom navigation for Scans, Favourites, and FAQ.
///
/// JAVA COMPARISON:
/// Similar to an Activity with BottomNavigationView and Fragments.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ScansScreen(),
    FavouritesScreen(),
    FAQScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Scans',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'FAQ',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCANS SCREEN (Main List)
// ============================================================================

/// Screen displaying search bar and scan list grouped by category.
class ScansScreen extends StatefulWidget {
  const ScansScreen({super.key});

  @override
  State<ScansScreen> createState() => _ScansScreenState();
}

class _ScansScreenState extends State<ScansScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpleRad'),
        centerTitle: true,
      ),
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

          return _buildContent(dataProvider);
        },
      ),
    );
  }

  Widget _buildContent(DataProvider dataProvider) {
    return Column(
      children: [
        // Search bar with accessibility label
        Semantics(
          label: 'Search for scans',
          hint: 'Type to filter the scan list',
          child: _SearchBar(
            controller: _searchController,
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
        ),

        // Scan list
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildCategoryList(dataProvider)
              : _buildSearchResults(dataProvider),
        ),
      ],
    );
  }

  Widget _buildCategoryList(DataProvider dataProvider) {
    final sections = dataProvider.appData!.sections;

    return RefreshIndicator(
      onRefresh: () => dataProvider.refreshData(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          final section = sections[sectionIndex];
          return _CategorySection(section: section);
        },
      ),
    );
  }

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
                color: AppColors.darkGrey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No scans found for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey.withValues(alpha: 0.7),
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
// FAVOURITES SCREEN
// ============================================================================

/// Screen displaying user's saved/bookmarked scans.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Scans'),
        centerTitle: true,
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const _LoadingWidget();
          }

          final favourites = dataProvider.favouriteScans;

          if (favourites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 80,
                      color: AppColors.darkGrey.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No saved scans yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGrey.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the heart icon on any scan to save it here for quick access.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.darkGrey.withValues(alpha: 0.6),
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
            itemCount: favourites.length,
            itemBuilder: (context, index) {
              final result = favourites[index];
              return _ScanCard(
                scan: result.scan,
                categoryColor: _parseColor(result.categoryColor),
                categoryName: result.categoryName,
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// FAQ SCREEN
// ============================================================================

/// Frequently Asked Questions screen for common patient queries.
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FAQItem(
            question: 'Can I eat before my scan?',
            answer:
                'It depends on the scan type. CT and ultrasound scans often require fasting (no food for 4-6 hours). MRI and X-ray scans usually have no fasting requirements. Always check the specific preparation instructions for your scan.',
          ),
          _FAQItem(
            question: 'What if I\'m claustrophobic?',
            answer:
                'Let your hospital know when booking. For MRI scans, you may be offered a sedative or referred to a hospital with an open MRI scanner. CT scanners are much more open and usually cause less anxiety. Staff are trained to help you feel comfortable.',
          ),
          _FAQItem(
            question: 'Are scans safe during pregnancy?',
            answer:
                'Ultrasound and MRI are generally safe during pregnancy. CT and X-ray scans use radiation and are usually avoided unless absolutely necessary. Always inform staff if you are or might be pregnant.',
          ),
          _FAQItem(
            question: 'What is contrast dye?',
            answer:
                'Contrast is a special liquid given by injection or drink that helps certain organs and blood vessels show up more clearly on scans. It\'s very safe but can cause allergic reactions in rare cases. Tell staff if you\'ve had a reaction before.',
          ),
          _FAQItem(
            question: 'How long do results take?',
            answer:
                'Results are usually reviewed by a radiologist within 24-48 hours. Your referring doctor will discuss the results with you, typically within 1-2 weeks. Urgent findings are communicated immediately.',
          ),
          _FAQItem(
            question: 'Can I bring someone with me?',
            answer:
                'Yes, a friend or family member can usually accompany you to the waiting area. They may not be allowed in the scan room for safety reasons (especially MRI), but staff will keep them informed.',
          ),
          _FAQItem(
            question: 'What should I wear?',
            answer:
                'Wear comfortable, loose clothing without metal (zips, buttons, underwire). You may be asked to change into a hospital gown. Remove jewellery, watches, and hearing aids before entering the scan room.',
          ),
          _FAQItem(
            question: 'Can I take my medication?',
            answer:
                'In most cases, yes. Continue taking your regular medication unless specifically told otherwise. If you\'re diabetic and need to fast, ask for an early appointment to minimise disruption to your medication schedule.',
          ),
        ],
      ),
    );
  }
}

/// Individual FAQ item with expandable answer.
///
/// Uses `ExpansionTile` for collapsible content.
/// ACCESSIBILITY: Screen readers will announce the question and expansion state.
class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.darkGrey.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
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
      color: AppColors.lightGrey,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search scans...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  tooltip: 'Clear search',
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
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
        // Category header with semantic label
        Semantics(
          header: true,
          child: Container(
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

/// Card widget displaying a scan summary with favourite button.
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
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final isFavourite = dataProvider.isFavourite(scan.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
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
                            color: AppColors.darkGrey.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Favourite button
                  Semantics(
                    label: isFavourite ? 'Remove from saved' : 'Save scan',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_outline,
                        color: isFavourite ? AppColors.red : AppColors.darkGrey,
                      ),
                      onPressed: () => dataProvider.toggleFavourite(scan.id),
                      tooltip: isFavourite ? 'Remove from saved' : 'Save',
                    ),
                  ),

                  // Arrow indicator
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.darkGrey.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
          CircularProgressIndicator(color: AppColors.primary),
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.red),
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
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.darkGrey),
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

/// Detail screen showing full scan information with share functionality.
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
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag and favourite button row
                  Row(
                    children: [
                      _buildCategoryTag(),
                      const Spacer(),
                      // Favourite button
                      Consumer<DataProvider>(
                        builder: (context, dataProvider, _) {
                          final isFavourite = dataProvider.isFavourite(scan.id);
                          return IconButton(
                            icon: Icon(
                              isFavourite
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: isFavourite
                                  ? AppColors.red
                                  : AppColors.darkGrey,
                              size: 28,
                            ),
                            onPressed: () =>
                                dataProvider.toggleFavourite(scan.id),
                            tooltip: isFavourite
                                ? 'Remove from saved'
                                : 'Save scan',
                          );
                        },
                      ),
                      // Share button
                      IconButton(
                        icon: const Icon(Icons.share, size: 26),
                        onPressed: () => _shareScan(context),
                        tooltip: 'Share scan information',
                      ),
                    ],
                  ),
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
                      color: AppColors.darkGrey.withValues(alpha: 0.8),
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
                    color: AppColors.primary,
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
                              color: AppColors.darkGrey.withValues(alpha: 0.8),
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
                    color: AppColors.secondary,
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

  Widget _buildSliverAppBar(BuildContext context) {
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
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: categoryColor.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.medical_services,
                    size: 64,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              )
            : Container(
                color: categoryColor.withValues(alpha: 0.3),
                child: Icon(
                  Icons.medical_services,
                  size: 64,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
      ),
    );
  }

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

  /// Shares scan information using the native share sheet.
  ///
  /// JAVA COMPARISON:
  /// Similar to Android's:
  /// ```java
  /// Intent shareIntent = new Intent(Intent.ACTION_SEND);
  /// shareIntent.setType("text/plain");
  /// shareIntent.putExtra(Intent.EXTRA_TEXT, text);
  /// startActivity(Intent.createChooser(shareIntent, "Share via"));
  /// ```
  void _shareScan(BuildContext context) {
    final shareText = '''
${scan.title}

${scan.shortSummary}

PREPARATION:
- Fasting: ${scan.preparation.requiresFasting ? '${scan.preparation.fastingHours} hours before' : 'Not required'}
- Bladder: ${scan.preparation.bladder}
${scan.preparation.instructions.isNotEmpty ? '- ${scan.preparation.instructions}' : ''}

WHAT TO EXPECT:
- Duration: ${scan.logistics.durationMinutes} minutes
- Noise Level: ${scan.logistics.noiseLevel}
- Claustrophobia Risk: ${scan.logistics.claustrophobiaRisk}

SAFETY:
- Radiation Level: ${scan.safety.radiationLevel}
${scan.safety.radiationNote.isNotEmpty ? '- ${scan.safety.radiationNote}' : ''}
- Contrast Dye: ${scan.safety.contrastRisk ? 'May be required' : 'Not required'}
- Pregnancy Safe: ${scan.safety.pregnancySafe ? 'Yes' : 'Consult your doctor'}

Shared from SimpleRad - Your Scan Explained
''';

    Share.share(
      shareText,
      subject: 'Scan Information: ${scan.title}',
    );
  }
}

// ============================================================================
// SAFETY INFO BOX (Traffic Light Widget)
// ============================================================================

/// Traffic light safety indicator widget.
class SafetyInfoBox extends StatelessWidget {
  final Safety safety;

  const SafetyInfoBox({super.key, required this.safety});

  @override
  Widget build(BuildContext context) {
    final radiationColor = _getRadiationColor(safety.radiationLevel);

    return Semantics(
      label:
          'Safety information. Radiation level: ${safety.radiationLevel}. ${safety.radiationNote}',
      child: Container(
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
                  color: AppColors.darkGrey.withValues(alpha: 0.8),
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
      ),
    );
  }

  Color _getRadiationColor(String level) {
    switch (level.toLowerCase()) {
      case 'green':
        return AppColors.green;
      case 'amber':
      case 'orange':
        return AppColors.amber;
      case 'red':
        return AppColors.red;
      default:
        return AppColors.green;
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
        color: AppColors.darkGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLight(AppColors.red, activeLevel.toLowerCase() == 'red'),
          const SizedBox(height: 4),
          _buildLight(AppColors.amber, activeLevel.toLowerCase() == 'amber'),
          const SizedBox(height: 4),
          _buildLight(AppColors.green, activeLevel.toLowerCase() == 'green'),
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

/// Individual safety indicator.
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
    final color = isRisk ? AppColors.red : AppColors.green;
    final statusText = isRisk ? 'Caution' : 'Safe';

    return Semantics(
      label: '$label: $statusText',
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
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
      ),
    );
  }
}

// ============================================================================
// INFO BLOCKS
// ============================================================================

/// Reusable info block container.
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
        color: AppColors.lightGrey,
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
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: AppColors.darkGrey.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGrey.withValues(alpha: 0.8),
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
      ),
    );
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Parses hex color string to Color object.
Color _parseColor(String hexString) {
  final hex = hexString.replaceFirst('#', '');

  try {
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  } catch (e) {
    // Return default color if parsing fails
  }
  return AppColors.primary;
}
