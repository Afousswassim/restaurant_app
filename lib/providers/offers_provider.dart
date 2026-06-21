import 'package:flutter/material.dart';
import '../models/offer.dart';

class OffersProvider with ChangeNotifier {
  List<Offer> _offers = [];
  bool _isLoading = false;
  String? _error;

  List<Offer> get offers => _offers;
  List<Offer> get featuredOffers => _offers.where((o) => o.isFeatured).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  OffersProvider() {
    loadOffers();
  }

  Future<void> loadOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Preload with professional visual mock offers
      _offers = [
        Offer(
          id: 'offer_burger_combo',
          title: 'Burger Combo',
          description: '2 Burgers + Fries + Drink. The ultimate meal for burger lovers.',
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
          discountPercentage: 35.0,
          oldPrice: 199.0,
          newPrice: 129.0,
          expiresAt: DateTime.now().add(const Duration(hours: 3, minutes: 24, seconds: 15)),
          couponCode: 'BURGERDEAL',
          isFeatured: true,
        ),
        Offer(
          id: 'offer_pizza_box',
          title: 'Family Pizza Box',
          description: '2 delicious medium pizzas + drinks. Perfect for a family night.',
          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600',
          discountPercentage: 28.0,
          oldPrice: 250.0,
          newPrice: 179.0,
          expiresAt: DateTime.now().add(const Duration(hours: 5, minutes: 45, seconds: 0)),
          couponCode: 'PIZZADEAL',
          isFeatured: true,
        ),
        Offer(
          id: 'offer_sweet_crepe',
          title: 'Sweet Crepe Offer',
          description: 'Buy 2 Sweet Crepes and get extra Nutella and banana toppings.',
          imageUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=600',
          discountPercentage: 33.3,
          oldPrice: 135.0,
          newPrice: 90.0,
          expiresAt: DateTime.now().add(const Duration(hours: 8, minutes: 12, seconds: 30)),
          couponCode: 'CREPEDEAL',
          isFeatured: true,
        ),
      ];
      _error = null;
    } catch (e) {
      _error = e.toString();
      _offers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
