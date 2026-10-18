import 'package:flutter/material.dart';

import '../data/clinic_store.dart';

class ClinicConnection extends StatelessWidget {
  const ClinicConnection({super.key, required this.store, required this.child});
  final ClinicStore store;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      if (store.isLoaded && store.branches.isNotEmpty) return child;
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (store.isLoading)
                    const CircularProgressIndicator()
                  else
                    const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 20),
                  Text(
                    store.isLoading
                        ? 'Connecting to your clinic'
                        : store.loadError != null
                        ? 'Connection unavailable'
                        : 'No branches available',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    store.loadError ??
                        (store.isLoading
                            ? 'Loading reports and inventory.'
                            : 'Your administrator needs to set up the clinic branches.'),
                    textAlign: TextAlign.center,
                  ),
                  if (!store.isLoading) ...[
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: store.load,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
