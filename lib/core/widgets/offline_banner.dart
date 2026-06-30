import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jowar_disease_detection/core/services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          color: Theme.of(context).colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Theme.of(context).colorScheme.onError,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "No Internet Connection. Working Offline Mode.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
