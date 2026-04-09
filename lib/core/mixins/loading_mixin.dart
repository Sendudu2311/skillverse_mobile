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
