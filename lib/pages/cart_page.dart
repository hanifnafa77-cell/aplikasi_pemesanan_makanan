import 'package:flutter/material.dart';
import '../models/food.dart';

class CartPage extends StatelessWidget {
  final List<Food> cart;

  const CartPage({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    int total = cart.fold(0, (sum, item) => sum + item.price);

    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: cart.isEmpty
          ? const Center(child: Text("Keranjang kosong"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(cart[index].name),
                        trailing: Text("Rp ${cart[index].price}"),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Total: Rp $total",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
    );
  }
}
