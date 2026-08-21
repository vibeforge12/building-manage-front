import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class AuthStatusWidget extends ConsumerWidget {
  const AuthStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Auth Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('State: ${authState.name}'),
          Text('Authenticated: $isAuthenticated'),
          if (currentUser != null) ...[
            Text('User: ${currentUser.name}'),
            Text('Type: ${currentUser.userType.displayName}'),
          ],
        ],
      ),
    );
  }
}