/// SimpleMed Radiology - Data Service
///
/// JAVA DEVELOPER NOTES:
///
/// 1. `Future<T>` in Dart is equivalent to `CompletableFuture<T>` in Java.
///    - `await` keyword pauses execution until Future completes (like .get() but non-blocking)
///    - `async` marks a function that returns a Future and can use `await`
///
/// 2. `async/await` pattern:
///    ```dart
///    Future<String> fetchData() async {
///      final response = await http.get(url);  // Pauses here
///      return response.body;  // Continues after response received
///    }
///    ```
///    Java equivalent would be:
///    ```java
///    CompletableFuture<String> fetchData() {
///      return httpClient.sendAsync(request, BodyHandlers.ofString())
///          .thenApply(HttpResponse::body);
///    }
///    ```
///
/// 3. `try-catch` works the same as Java, but Dart doesn't have checked exceptions.
///
/// 4. `ChangeNotifier` is part of Flutter's Provider pattern - similar to
///    Android's `ViewModel` with `LiveData`. UI widgets can listen for changes.
///
/// 5. String interpolation: `'Value: $variable'` or `'Value: ${expression}'`
///    Java equivalent: `"Value: " + variable` or `String.format("Value: %s", variable)`

library;

import 'dart:convert'; // For jsonDecode - like Java's Jackson/Gson
import 'package:flutter/foundation.dart'; // For debugPrint, ChangeNotifier
import 'package:flutter/services.dart'; // For loading local assets
import 'package:http/http.dart' as http; // HTTP client
import 'package:shared_preferences/shared_preferences.dart'; // Local storage
import 'models.dart';

/// The remote URL for the radiology data JSON.
/// In production, this would be your actual API endpoint.
const String _remoteJsonUrl = 'https://simplemed.co.uk/api/radiology_data.json';

/// Key used to store cached JSON in SharedPreferences.
const String _cacheKey = 'cached_radiology_json';

// ============================================================================
// DATA SERVICE - Fetching and Caching Logic
// ============================================================================

/// Service class for fetching and caching radiology data.
///
/// Implements "offline-first" pattern:
/// 1. Try to fetch fresh data from remote URL
/// 2. If successful, cache it locally and return
/// 3. If network fails, load cached data
/// 4. If no cache exists, load bundled fallback from assets
///
/// JAVA COMPARISON:
/// This is similar to a Repository class in Android Architecture Components,
/// but Dart uses `async/await` instead of RxJava or Coroutines.
class DataService {
  /// Singleton instance - ensures only one DataService exists.
  /// Java equivalent: private static final DataService INSTANCE = new DataService();
  static final DataService _instance = DataService._internal();

  /// Factory constructor returns the singleton.
  /// When you call `DataService()`, you always get the same instance.
  factory DataService() => _instance;

  /// Private constructor for singleton pattern.
  /// The underscore prefix makes it private in Dart.
  DataService._internal();

  // ---------------------------------------------------------------------------
  // Main Public Method
  // ---------------------------------------------------------------------------

  /// Loads radiology data with offline-first strategy.
  ///
  /// Returns: `Future<AppData>` - the parsed data (async operation).
  ///
  /// JAVA EQUIVALENT:
  /// ```java
  /// public CompletableFuture<AppData> loadData() { ... }
  /// ```
  ///
  /// Usage:
  /// ```dart
  /// final data = await DataService().loadData();
  /// // or without await:
  /// DataService().loadData().then((data) => doSomething(data));
  /// ```
  Future<AppData> loadData() async {
    // Try to fetch from network first
    try {
      debugPrint('[DataService] Attempting to fetch from network...');
      final jsonString = await _fetchFromNetwork();
      debugPrint('[DataService] Network fetch successful, caching data...');
      await _cacheJsonString(jsonString);
      return _parseJson(jsonString);
    } catch (networkError) {
      // Network failed - try loading from cache
      debugPrint('[DataService] Network error: $networkError');
      debugPrint('[DataService] Attempting to load from cache...');

      try {
        final cachedJson = await _loadFromCache();
        if (cachedJson != null && cachedJson.isNotEmpty) {
          debugPrint('[DataService] Cache loaded successfully.');
          return _parseJson(cachedJson);
        }
      } catch (cacheError) {
        debugPrint('[DataService] Cache error: $cacheError');
      }

      // No cache available - load bundled fallback
      debugPrint('[DataService] Loading bundled fallback data...');
      return _loadFallbackData();
    }
  }

  // ---------------------------------------------------------------------------
  // Private Helper Methods
  // ---------------------------------------------------------------------------

  /// Fetches JSON string from the remote URL.
  ///
  /// JAVA COMPARISON:
  /// Similar to `HttpURLConnection` or OkHttp's `client.newCall(request).execute()`.
  ///
  /// The `await` keyword pauses execution until the HTTP response is received,
  /// but doesn't block the main thread (unlike Java's synchronous HTTP calls).
  Future<String> _fetchFromNetwork() async {
    // `Uri.parse()` is like Java's `new URI(string)` or `URL.toURI()`
    final uri = Uri.parse(_remoteJsonUrl);

    // http.get returns Future<Response>, await unwraps it to Response
    final response = await http.get(uri).timeout(
          // Timeout similar to Java's HttpURLConnection.setConnectTimeout()
          const Duration(seconds: 10),
        );

    // Check HTTP status code
    if (response.statusCode == 200) {
      return response.body;
    } else {
      // Throwing exception - same as Java
      throw HttpException(
        'Failed to load data: HTTP ${response.statusCode}',
      );
    }
  }

  /// Caches the JSON string to SharedPreferences.
  ///
  /// JAVA COMPARISON:
  /// Equivalent to Android's:
  /// ```java
  /// SharedPreferences prefs = getSharedPreferences("app", MODE_PRIVATE);
  /// prefs.edit().putString("key", value).apply();
  /// ```
  ///
  /// The `await` keyword is needed because SharedPreferences operations
  /// are asynchronous in Flutter (unlike Android where they're sync).
  Future<void> _cacheJsonString(String jsonString) async {
    // `await getInstance()` - SharedPreferences is loaded asynchronously
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonString);
  }

  /// Loads cached JSON string from SharedPreferences.
  ///
  /// Returns `null` if no cached data exists (nullable return type: `String?`).
  Future<String?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    // getString returns null if key doesn't exist (like Map.get in Java)
    return prefs.getString(_cacheKey);
  }

  /// Parses JSON string into AppData object.
  ///
  /// JAVA COMPARISON:
  /// Similar to Jackson's `objectMapper.readValue(json, AppData.class)`
  /// or Gson's `gson.fromJson(json, AppData.class)`.
  ///
  /// Dart's `jsonDecode()` parses JSON into `Map<String, dynamic>`,
  /// then we use our factory constructor to create the typed object.
  AppData _parseJson(String jsonString) {
    // jsonDecode converts JSON string to dynamic (Map or List)
    // Similar to JSONObject/JSONArray in Java or Jackson's JsonNode
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return AppData.fromJson(jsonMap);
  }

  /// Loads fallback data from bundled assets.
  ///
  /// This is used when both network and cache fail.
  /// Assets are bundled with the app (defined in pubspec.yaml).
  ///
  /// JAVA COMPARISON:
  /// Similar to loading from Android's `res/raw/` folder:
  /// ```java
  /// InputStream is = getResources().openRawResource(R.raw.data);
  /// ```
  Future<AppData> _loadFallbackData() async {
    try {
      // rootBundle is Flutter's asset loader
      final jsonString = await rootBundle.loadString(
        'assets/radiology_data.json',
      );
      return _parseJson(jsonString);
    } catch (e) {
      debugPrint('[DataService] Fallback load failed: $e');
      // Return empty data as last resort
      return AppData(
        meta: Meta(version: '0.0', contactEmail: ''),
        sections: [],
      );
    }
  }
}

// ============================================================================
// DATA PROVIDER - State Management with ChangeNotifier
// ============================================================================

/// State management class for the app's data.
///
/// JAVA COMPARISON:
/// This is similar to Android's `ViewModel` with `LiveData`:
/// - `ChangeNotifier` is like `ViewModel`
/// - `notifyListeners()` is like `LiveData.setValue()` which triggers observers
/// - UI widgets use `Consumer<DataProvider>` to observe changes
///
/// In Java/Android:
/// ```java
/// class MyViewModel extends ViewModel {
///     private MutableLiveData<AppData> data = new MutableLiveData<>();
///
///     public void loadData() {
///         repository.loadData().thenAccept(result -> data.setValue(result));
///     }
/// }
/// ```
class DataProvider extends ChangeNotifier {
  final DataService _dataService = DataService();

  AppData? _appData;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters - similar to Java getter methods
  // The `=>` syntax is shorthand for `{ return _appData; }`
  AppData? get appData => _appData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasData => _appData != null && _appData!.sections.isNotEmpty;

  /// Get all scans across all sections as a flat list.
  /// Useful for search functionality.
  List<Scan> get allScans {
    if (_appData == null) return [];
    // `expand` flattens nested lists - like Java's `flatMap`
    return _appData!.sections.expand((section) => section.scans).toList();
  }

  /// Loads data and notifies listeners when complete.
  ///
  /// Call this in the app's initialization (e.g., in main.dart).
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify UI that loading started

    try {
      _appData = await _dataService.loadData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      debugPrint('[DataProvider] Error: $_errorMessage');
    } finally {
      // `finally` block executes regardless of success/failure (same as Java)
      _isLoading = false;
      notifyListeners(); // Notify UI that loading finished
    }
  }

  /// Refreshes data from network (for pull-to-refresh).
  Future<void> refreshData() async {
    await loadData();
  }

  /// Searches scans by title or summary (case-insensitive).
  ///
  /// Returns matching scans along with their category information.
  List<SearchResult> searchScans(String query) {
    if (query.isEmpty || _appData == null) {
      return [];
    }

    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    for (final section in _appData!.sections) {
      for (final scan in section.scans) {
        // `.contains()` works like Java's String.contains()
        if (scan.title.toLowerCase().contains(lowerQuery) ||
            scan.shortSummary.toLowerCase().contains(lowerQuery)) {
          results.add(SearchResult(
            scan: scan,
            categoryName: section.categoryName,
            categoryColor: section.colorHex,
          ));
        }
      }
    }

    return results;
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Search result wrapper that includes category info for display.
class SearchResult {
  final Scan scan;
  final String categoryName;
  final String categoryColor;

  SearchResult({
    required this.scan,
    required this.categoryName,
    required this.categoryColor,
  });
}

/// Custom exception for HTTP errors.
/// Dart exceptions don't need to extend a specific class,
/// but implementing Exception is conventional.
class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() => message;
}
