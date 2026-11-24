import 'package:flutter/material.dart';
import '../models/food.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Food> menu = [
    Food(name: "Nasi Goreng", price: 15000),
    Food(name: "Mie Ayam", price: 12000),
    Food(name: "Ayam Bakar", price: 20000),
    Food(name: "Es Teh", price: 5000),
  ];

  List<Food> cart = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Makanan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartPage(cart: cart),
                ),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: menu.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(menu[index].name),
              subtitle: Text("Rp ${menu[index].price}"),
              trailing: ElevatedButton(
                child: const Text("Pesan"),
                onPressed: () {
                  setState(() {
                    cart.add(menu[index]);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ditambahkan ke keranjang")),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
