import 'package:flutter/material.dart';

class HomeHeroBanner extends StatelessWidget {
  final VoidCallback onExplore;

  const HomeHeroBanner({super.key, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            image: const DecorationImage(
              image: ResizeImage(
                NetworkImage(
                  'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&auto=format&fit=crop&q=80',
                ),
                width: 800,
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8D4B38).withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 20 : 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Legendary Flavor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 11 : 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 14),
                  Text(
                    'The Magic of Fresh Food',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 24 : 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 12),
                  Text(
                    'Discover our delicious burgers, pizzas, crepes and desserts prepared with love.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: isCompact ? 12 : 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isCompact ? 18 : 22),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8D4B38), Color(0xFF6E392A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8D4B38).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onExplore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 20 : 26,
                          vertical: isCompact ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Explore Menu Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 13 : 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
