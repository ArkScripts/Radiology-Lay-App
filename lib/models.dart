/// SimpleMed Radiology - Data Models
///
/// JAVA DEVELOPER NOTES:
///
/// 1. Dart uses `final` similar to Java's `final` - the variable cannot be reassigned.
///    Unlike Java, Dart final fields can be initialized in the constructor.
///
/// 2. `required` keyword: In Dart, named parameters are optional by default.
///    `required` makes them mandatory (like non-nullable params in Java).
///    Syntax: `ClassName({required this.field})` - named parameter
///    vs Java: `ClassName(String field)` - positional parameter
///
/// 3. `factory` keyword: A factory constructor can return an existing instance
///    or a subtype. Here we use it for JSON parsing (similar to static factory
///    methods in Java like `MyClass.fromJson()`).
///
/// 4. Null safety: `?` after type means nullable (e.g., `String?`).
///    Without `?`, the variable cannot be null (like @NonNull in Java).
///
/// 5. Cascade operator `..`: Allows chaining method calls on same object.
///    `list..add(1)..add(2)` is like `list.add(1); list.add(2); return list;`

library;

// ============================================================================
// ROOT DATA MODEL
// ============================================================================

/// Root container for all app data fetched from JSON.
/// Similar to a Java POJO/DTO class.
class AppData {
  final Meta meta;
  final List<Section> sections;

  // Constructor using named parameters with `required` keyword
  // Java equivalent: public AppData(Meta meta, List<Section> sections) { ... }
  AppData({required this.meta, required this.sections});

  /// Factory constructor to parse JSON into AppData object.
  /// In Java, this would be: public static AppData fromJson(Map<String, Object> json)
  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      meta: Meta.fromJson(json['meta'] ?? {}),
      // Casting and mapping list - similar to Java streams:
      // json.get("sections").stream().map(Section::fromJson).collect(toList())
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((item) => Section.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============================================================================
// META DATA
// ============================================================================

/// Metadata about the JSON content (version, contact info).
class Meta {
  final String version;
  final String contactEmail;

  Meta({required this.version, required this.contactEmail});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      version: json['version'] ?? '1.0',
      contactEmail: json['contact_email'] ?? '',
    );
  }
}

// ============================================================================
// SECTION (Category of Scans)
// ============================================================================

/// A category/section grouping related scans (e.g., "CT Scans", "MRI Scans").
class Section {
  final String categoryName;
  final String colorHex; // Hex color string like "#005EB8"
  final List<Scan> scans;

  Section({
    required this.categoryName,
    required this.colorHex,
    required this.scans,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      categoryName: json['category_name'] ?? 'Unknown Category',
      colorHex: json['category_color_hex'] ?? '#005EB8',
      scans: (json['scans'] as List<dynamic>? ?? [])
          .map((item) => Scan.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============================================================================
// SCAN (Individual Scan Type)
// ============================================================================

/// Represents a single scan type (e.g., CT Abdomen, MRI Brain).
/// This is the main content model shown in the detail screen.
class Scan {
  final String id;
  final String title;
  final String shortSummary;
  final String fullDescription;
  final Preparation preparation;
  final Logistics logistics;
  final Safety safety;
  final Media media;

  Scan({
    required this.id,
    required this.title,
    required this.shortSummary,
    required this.fullDescription,
    required this.preparation,
    required this.logistics,
    required this.safety,
    required this.media,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Scan',
      shortSummary: json['short_summary'] ?? '',
      fullDescription: json['full_description'] ?? '',
      preparation: Preparation.fromJson(
        json['preparation'] as Map<String, dynamic>? ?? {},
      ),
      logistics: Logistics.fromJson(
        json['logistics'] as Map<String, dynamic>? ?? {},
      ),
      safety: Safety.fromJson(
        json['safety'] as Map<String, dynamic>? ?? {},
      ),
      media: Media.fromJson(
        json['media'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

// ============================================================================
// PREPARATION
// ============================================================================

/// Patient preparation requirements before the scan.
class Preparation {
  final int fastingHours;
  final String bladder; // e.g., "Empty", "Full", "N/A"
  final String instructions;

  Preparation({
    required this.fastingHours,
    required this.bladder,
    required this.instructions,
  });

  factory Preparation.fromJson(Map<String, dynamic> json) {
    return Preparation(
      // Dart `as int?` is a type cast with null safety
      // Java equivalent: (Integer) json.get("fasting_hours")
      fastingHours: (json['fasting_hours'] as int?) ?? 0,
      bladder: json['bladder'] ?? 'N/A',
      instructions: json['instructions'] ?? 'No specific instructions.',
    );
  }

  /// Check if any fasting is required
  bool get requiresFasting => fastingHours > 0;
}

// ============================================================================
// LOGISTICS
// ============================================================================

/// Logistical information about the scan experience.
class Logistics {
  final String durationMinutes;
  final String noiseLevel; // "Low", "Moderate", "High"
  final String claustrophobiaRisk; // "Low", "Moderate", "High"

  Logistics({
    required this.durationMinutes,
    required this.noiseLevel,
    required this.claustrophobiaRisk,
  });

  factory Logistics.fromJson(Map<String, dynamic> json) {
    return Logistics(
      // Handle both int and String from JSON
      durationMinutes: json['duration_minutes']?.toString() ?? '0',
      noiseLevel: json['noise_level'] ?? 'Low',
      claustrophobiaRisk: json['claustrophobia_risk'] ?? 'Low',
    );
  }
}

// ============================================================================
// SAFETY
// ============================================================================

/// Safety information including radiation levels and pregnancy warnings.
class Safety {
  final String radiationLevel; // "Green", "Amber", "Red"
  final String radiationNote;
  final bool contrastRisk;
  final bool pregnancySafe;

  Safety({
    required this.radiationLevel,
    required this.radiationNote,
    required this.contrastRisk,
    required this.pregnancySafe,
  });

  factory Safety.fromJson(Map<String, dynamic> json) {
    return Safety(
      radiationLevel: json['radiation_level'] ?? 'Green',
      radiationNote: json['radiation_note'] ?? '',
      // `as bool? ?? false` - cast to nullable bool, default to false
      contrastRisk: json['contrast_risk'] as bool? ?? false,
      pregnancySafe: json['pregnancy_safe'] as bool? ?? true,
    );
  }
}

// ============================================================================
// MEDIA
// ============================================================================

/// Media assets for the scan (icon, hero image).
class Media {
  final String iconUrl;
  final String heroImageUrl;
  final double heroAspectRatio; // width / height for layout reservation

  Media({
    required this.iconUrl,
    required this.heroImageUrl,
    required this.heroAspectRatio,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      iconUrl: json['icon_url'] ?? '',
      heroImageUrl: json['hero_image_url'] ?? '',
      // `toDouble()` ensures we get a double even if JSON has an int
      // Similar to Java's Number.doubleValue()
      heroAspectRatio: (json['hero_aspect_ratio'] as num?)?.toDouble() ?? 1.5,
    );
  }
}
