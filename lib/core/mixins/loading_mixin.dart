import 'package:flutter/material.dart';

/// Mixin to manage loading state in StatefulWidget
///
/// Usage:
/// ```dart
/// class MyPage extends StatefulWidget {
///   const MyPage({super.key});
///
///   @override
///   State<MyPage> createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage> with LoadingMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: isLoading
///           ? const Center(child: CircularProgressIndicator())
///           : YourContent(),
///     );
///   }
///
///   Future<void> _loadData() async {
///     await performAsync(() async {
///       // Your async operation
///       await apiService.fetchData();
///     });
///   }
/// }
/// ```
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Set loading state
  void setLoading(bool loading) {
    if (mounted && _isLoading != loading) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  /// Perform async operation with loading state management
  ///
  /// Automatically sets loading to true before operation and false after.
  /// Handles mounted check to prevent setState on unmounted widget.
  ///
  /// Example:
  /// ```dart
  /// await performAsync(() async {
  ///   await apiService.saveData();
  /// });
  /// ```
  Future<T?> performAsync<T>(Future<T> Function() operation) async {
    if (!mounted) return null;

    setLoading(true);
    try {
      final result = await operation();
      return result;
    } finally {
      if (mounted) {
        setLoading(false);
      }
    }
  }

  /// Perform async operation with custom error handling
  ///
  /// Example:
  /// ```dart
  /// await performAsyncWithError(
  ///   operation: () async {
  ///     await apiService.saveData();
  ///   },
  ///   onError: (error) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(content: Text('Error: $error')),
  ///     );
  ///   },
  /// );
  /// ```
  Future<T?> performAsyncWithError<T>({
    required Future<T> Function() operation,
    required void Function(dynamic error) onError,
  }) async {
    if (!mounted) return null;

    setLoading(true);
    try {
      final result = await operation();
      return result;
    } catch (e) {
      if (mounted) {
        onError(e);
      }
      return null;
    } finally {
      if (mounted) {
        setLoading(false);
      }
    }
  }

  /// Perform async operation with success callback
  ///
  /// Example:
  /// ```dart
  /// await performAsyncWithSuccess(
  ///   operation: () async {
  ///     await apiService.saveData();
  ///   },
  ///   onSuccess: () {
  ///     Navigator.pop(context);
  ///   },
  /// );
  /// ```
  Future<void> performAsyncWithSuccess<T>({
    required Future<T> Function() operation,
    required void Function(T result) onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    if (!mounted) return;

    setLoading(true);
    try {
      final result = await operation();
      if (mounted) {
        onSuccess(result);
      }
    } catch (e) {
      if (mounted && onError != null) {
        onError(e);
      }
    } finally {
      if (mounted) {
        setLoading(false);
      }
    }
  }
}

/// Advanced mixin with multiple loading states
///
/// Use this when you need to track multiple loading operations independently.
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with MultiLoadingMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         if (isLoadingFor('save'))
///           const CircularProgressIndicator(),
///         if (isLoadingFor('delete'))
///           const Text('Deleting...'),
///       ],
///     );
///   }
///
///   Future<void> _save() async {
///     await performAsyncFor('save', () async {
///       await apiService.save();
///     });
///   }
///
///   Future<void> _delete() async {
///     await performAsyncFor('delete', () async {
///       await apiService.delete();
///     });
///   }
/// }
/// ```
mixin MultiLoadingMixin<T extends StatefulWidget> on State<T> {
  final Map<String, bool> _loadingStates = {};

  /// Check if a specific operation is loading
  bool isLoadingFor(String key) => _loadingStates[key] ?? false;

  /// Check if any operation is loading
  bool get isAnyLoading => _loadingStates.values.any((loading) => loading);

  /// Set loading state for a specific key
  void setLoadingFor(String key, bool loading) {
    if (mounted && _loadingStates[key] != loading) {
      setState(() {
        _loadingStates[key] = loading;
      });
    }
  }

  /// Perform async operation for a specific key
  Future<T?> performAsyncFor<T>(
    String key,
    Future<T> Function() operation,
  ) async {
    if (!mounted) return null;

    setLoadingFor(key, true);
    try {
      final result = await operation();
      return result;
    } finally {
      if (mounted) {
        setLoadingFor(key, false);
      }
    }
  }

  /// Clear all loading states
  void clearAllLoading() {
    if (mounted) {
      setState(() {
        _loadingStates.clear();
      });
    }
  }
}

/// Mixin for managing loading state with error tracking
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with LoadingStateMixin {
///   @override
///   Widget build(BuildContext context) {
///     if (isLoading) {
///       return const Center(child: CircularProgressIndicator());
///     }
///     if (hasError) {
///       return ErrorWidget(error: errorMessage);
///     }
///     return YourContent();
///   }
///
///   Future<void> _loadData() async {
///     await executeAsync(() async {
///       await apiService.fetchData();
///     });
///   }
/// }
/// ```
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Whether an error occurred
  bool get hasError => _errorMessage != null;

  /// Current error message
  String? get errorMessage => _errorMessage;

  /// Set loading state
  void setLoading(bool loading) {
    if (mounted && _isLoading != loading) {
      setState(() {
        _isLoading = loading;
        if (loading) {
          _errorMessage = null; // Clear error when starting new operation
        }
      });
    }
  }

  /// Set error state
  void setError(String? error) {
    if (mounted && _errorMessage != error) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  /// Clear error state
  void clearError() {
    setError(null);
  }

  /// Execute async operation with automatic error handling
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? Function(dynamic error)? errorMessageBuilder,
  }) async {
    if (!mounted) return null;

    setLoading(true);
    try {
      final result = await operation();
      if (mounted) {
        setLoading(false);
      }
      return result;
    } catch (e) {
      if (mounted) {
        final message = errorMessageBuilder?.call(e) ?? e.toString();
        setError(message);
      }
      return null;
    }
  }

  /// Reset all states
  void resetState() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    }
  }
}
