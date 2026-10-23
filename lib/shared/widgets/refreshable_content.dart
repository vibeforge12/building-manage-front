import 'package:flutter/material.dart';

/// Status states stay scrollable too, so a failed or empty response can be
/// retried with the same pull gesture as a populated list.
class RefreshableContent extends StatelessWidget {
  const RefreshableContent({
    super.key,
    required this.onRefresh,
    required this.child,
    this.isLoading = false,
    this.error,
    this.isEmpty = false,
    this.emptyMessage = '',
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading || error != null || isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : error != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(error!),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: onRefresh,
                                child: const Text('다시 시도'),
                              ),
                            ],
                          )
                        : Text(emptyMessage),
                  ),
                ),
              ],
            )
          : child,
    ),
  );
}
