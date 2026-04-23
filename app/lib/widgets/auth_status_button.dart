import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStatusButton extends StatelessWidget {
  const AuthStatusButton({
    super.key,
    required this.onSignOut,
  });

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Cuenta';

    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      onSelected: (value) async {
        if (value == 'logout') {
          await onSignOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          value: 'email',
          child: Text(
            email,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Cerrar sesión'),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: const Icon(Icons.person_outline_rounded, size: 20),
      ),
    );
  }
}
