import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/services/favorite_service.dart';

class FavoriteFarmersScreen extends StatelessWidget {
  const FavoriteFarmersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view favorites'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Favorite Farmers'),
        backgroundColor: const Color.fromARGB(255, 53, 177, 94),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FavoriteService.streamFavoriteFarmers(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading favorites'));
          }

          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'You have no favorite farmers yet.\nTap the heart icon on a farmer\'s page to add them!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              final farmerName = favorite['farmerName'] as String? ?? 'Farmer';
              final farmerId = favorite['farmerId'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.person, color: Colors.green),
                  ),
                  title: Text(
                    farmerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Tap to view profile'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      FavoriteService.toggleFavorite(
                        user.uid,
                        farmerId,
                        farmerName,
                        false, // remove favorite
                      );
                    },
                  ),
                  onTap: () {
                    // Navigate to farmer profile if needed,
                    // or just show a message for now.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing $farmerName\'s profile')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
