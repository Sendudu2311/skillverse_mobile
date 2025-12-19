import 'package:flutter/foundation.dart';

/// Mixin to manage loading state in ChangeNotifier providers
///
/// Usage:
/// ```dart
/// class MyProvider extends ChangeNotifier with LoadingProviderMixin {
///   Future<void> loadData() async {
///     await performAsync(() async {
///       // Your async operation
///       final data = await apiService.fetchData();
///       _data = data;
///       notifyListeners();
///     });
///   }
/// }
///
/// // In your widget:
/// Consumer<MyProvider>(
///   builder: (context, provider, child) {
///     if (provider.isLoading) {
///       return const CircularProgressIndicator();
///     }
///     return YourContent();
///   },
/// )
/// ```
mixin LoadingProviderMixin on ChangeNotifier {
  bool _isLoading = false;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Set loading state and notify listeners
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Perform async operation with loading state management
  ///
  /// Automatically sets loading to true before operation and false after.
  ///
  /// Example:
  /// ```dart
  /// await performAsync(() async {
  ///   await apiService.saveData();
  /// });
  /// ```
  Future<R?> performAsync<R>(Future<R> Function() operation) async {
    setLoading(true);
    try {
      final result = await operation();
      return result;
    } finally {
      setLoading(false);
    }
  }

  /// Perform async operation with error handling
  ///
  /// Example:
  /// ```dart
  /// await performAsyncWithError(
  ///   operation: () async {
  ///     await apiService.saveData();
  ///   },
  ///   onError: (error) {
  ///     _errorMessage = error.toString();
  ///     notifyListeners();
  ///   },
  /// );
  /// ```
  Future<R?> performAsyncWithError<R>({
    required Future<R> Function() operation,
    required void Function(dynamic error) onError,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      return result;
    } catch (e) {
      onError(e);
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Perform async operation with success callback
  ///
  /// Example:
  /// ```dart
  /// await performAsyncWithSuccess(
  ///   operation: () async {
  ///     return await apiService.saveData();
  ///   },
  ///   onSuccess: (result) {
  ///     _data = result;
  ///     notifyListeners();
  ///   },
  /// );
  /// ```
  Future<void> performAsyncWithSuccess<R>({
    required Future<R> Function() operation,
    required void Function(R result) onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      onSuccess(result);
    } catch (e) {
      onError?.call(e);
    } finally {
      setLoading(false);
    }
  }
}

/// Mixin for managing loading state with error tracking in providers
///
/// Usage:
/// ```dart
/// class MyProvider extends ChangeNotifier with LoadingStateProviderMixin {
///   Future<void> loadData() async {
///     await executeAsync(() async {
///       final data = await apiService.fetchData();
///       _data = data;
///       notifyListeners();
///     });
///   }
/// }
///
/// // In your widget:
/// Consumer<MyProvider>(
///   builder: (context, provider, child) {
///     if (provider.isLoading) {
///       return const CircularProgressIndicator();
///     }
///     if (provider.hasError) {
///       return ErrorWidget(error: provider.errorMessage);
///     }
///     return YourContent();
///   },
/// )
/// ```
mixin LoadingStateProviderMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Whether an error occurred
  bool get hasError => _errorMessage != null;

  /// Current error message
  String? get errorMessage => _errorMessage;

  /// Set loading state and notify listeners
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (loading) {
        _errorMessage = null; // Clear error when starting new operation
      }
      notifyListeners();
    }
  }

  /// Set error state and notify listeners
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    setError(null);
  }

  /// Execute async operation with automatic error handling
  ///
  /// Example:
  /// ```dart
  /// await executeAsync(
  ///   () async {
  ///     final data = await apiService.fetchData();
  ///     _data = data;
  ///     notifyListeners();
  ///   },
  ///   errorMessageBuilder: (error) {
  ///     if (error is DioException) {
  ///       return ErrorHandler.getErrorMessage(error);
  ///     }
  ///     return error.toString();
  ///   },
  /// );
  /// ```
  Future<R?> executeAsync<R>(
    Future<R> Function() operation, {
    String? Function(dynamic error)? errorMessageBuilder,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      setLoading(false);
      return result;
    } catch (e) {
      final message = errorMessageBuilder?.call(e) ?? e.toString();
      setError(message);
      return null;
    }
  }

  /// Reset all states
  void resetState() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

/// Advanced mixin with multiple loading states for providers
///
/// Use this when you need to track multiple loading operations independently.
///
/// Usage:
/// ```dart
/// class MyProvider extends ChangeNotifier with MultiLoadingProviderMixin {
///   Future<void> save() async {
///     await performAsyncFor('save', () async {
///       await apiService.save();
///     });
///   }
///
///   Future<void> delete() async {
///     await performAsyncFor('delete', () async {
///       await apiService.delete();
///     });
///   }
/// }
///
/// // In your widget:
/// Consumer<MyProvider>(
///   builder: (context, provider, child) {
///     return Column(
///       children: [
///         if (provider.isLoadingFor('save'))
///           const Text('Saving...'),
///         if (provider.isLoadingFor('delete'))
///           const Text('Deleting...'),
///       ],
///     );
///   },
/// )
/// ```
mixin MultiLoadingProviderMixin on ChangeNotifier {
  final Map<String, bool> _loadingStates = {};

  /// Check if a specific operation is loading
  bool isLoadingFor(String key) => _loadingStates[key] ?? false;

  /// Check if any operation is loading
  bool get isAnyLoading => _loadingStates.values.any((loading) => loading);

  /// Get all loading keys
  Set<String> get loadingKeys => _loadingStates.keys.toSet();

  /// Set loading state for a specific key
  void setLoadingFor(String key, bool loading) {
    if (_loadingStates[key] != loading) {
      _loadingStates[key] = loading;
      notifyListeners();
    }
  }

  /// Perform async operation for a specific key
  Future<R?> performAsyncFor<R>(
    String key,
    Future<R> Function() operation,
  ) async {
    setLoadingFor(key, true);
    try {
      final result = await operation();
      return result;
    } finally {
      setLoadingFor(key, false);
    }
  }

  /// Perform async operation with error handling for a specific key
  Future<R?> performAsyncForWithError<R>({
    required String key,
    required Future<R> Function() operation,
    required void Function(dynamic error) onError,
  }) async {
    setLoadingFor(key, true);
    try {
      final result = await operation();
      return result;
    } catch (e) {
      onError(e);
      return null;
    } finally {
      setLoadingFor(key, false);
    }
  }

  /// Clear all loading states
  void clearAllLoading() {
    _loadingStates.clear();
    notifyListeners();
  }

  /// Clear loading state for a specific key
  void clearLoadingFor(String key) {
    if (_loadingStates.remove(key) != null) {
      notifyListeners();
    }
  }
}
