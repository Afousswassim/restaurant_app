import 'package:flutter/material.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faqs = [
      {
        'q': 'How can I place an order?',
        'a': 'Choose your branch, browse the menu, add items to the cart, then confirm your order from checkout.'
      },
      {
        'q': 'Can I choose the nearest branch?',
        'a': 'Yes, you can select one of our Casablanca branches before browsing the menu.'
      },
      {
        'q': 'How are delivery fees calculated?',
        'a': 'Delivery fees depend on the selected branch and are added automatically to the total.'
      },
      {
        'q': 'Can I track my order status?',
        'a': 'Yes, you can follow your order status: pending, preparing, delivering, and delivered.'
      }
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Frequently Asked Questions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...faqs.map((faq) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    faq['q']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  iconColor: Colors.deepOrange,
                  collapsedIconColor: Colors.grey,
                  children: [
                    Text(
                      faq['a']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
