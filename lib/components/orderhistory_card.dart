import 'package:flutter/material.dart';

class OrderHistoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String orderDate;
  final int rating;
  final bool isRated;
  final int ratingCount; // Add this
  final Function(int) onRatingChanged;

  const OrderHistoryCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.orderDate,
    this.rating = 0,
    this.isRated = false,
    this.ratingCount = 0, // Add this
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRated ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Food Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),

              // Food Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isRated ? Colors.grey[700] : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ordered on $orderDate',
                      style: TextStyle(
                        fontSize: 13,
                        color: isRated ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isRated ? Colors.red[300] : Colors.red,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isRated ? Colors.red[100] : Colors.red)
                                ?.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'x$quantity',
                            style: TextStyle(
                              color: isRated
                                  ? Colors.red[300]
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: isRated ? null : () => onRatingChanged(index + 1),
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: isRated ? Colors.amber[300] : Colors.amber,
                      size: 24,
                    ),
                  );
                }),
              ),
              if (isRated)
                Text(
                  '$ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
