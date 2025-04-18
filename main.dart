import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Georgia',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.pinkAccent),
          bodyMedium: TextStyle(color: Colors.pinkAccent),
        ),
      ),
      home: MainScreen(),
      routes: {
        '/home': (context) => MainScreen(),
        '/cart': (context) => CartScreen(),
        '/auth': (context) => AuthScreen(),
      },
    );
  }
}

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _username = 'admin';
  String _password = 'admin123';

  bool get isAuthenticated => _isAuthenticated;

  bool login(String username, String password) {
    if (username == _username && password == _password) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}

class Product {
  String id;
  String name;
  String shade;
  int mattePrice;
  int glossPrice;
  int stock;
  String imagePath;
  Color color;

  Product({
    required this.id,
    required this.name,
    required this.shade,
    required this.mattePrice,
    required this.glossPrice,
    required this.stock,
    required this.imagePath,
    required this.color,
  });

  Product.empty()
      : id = '',
        name = '',
        shade = '',
        mattePrice = 0,
        glossPrice = 0,
        stock = 0,
        imagePath = '',
        color = Colors.pink;

  Product copyWith({
    String? id,
    String? name,
    String? shade,
    int? mattePrice,
    int? glossPrice,
    int? stock,
    String? imagePath,
    Color? color,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      shade: shade ?? this.shade,
      mattePrice: mattePrice ?? this.mattePrice,
      glossPrice: glossPrice ?? this.glossPrice,
      stock: stock ?? this.stock,
      imagePath: imagePath ?? this.imagePath,
      color: color ?? this.color,
    );
  }
}

class ProductProvider with ChangeNotifier {
  List<Product> _products = [
    Product(
      id: '1',
      name: "Saint",
      shade: "Rojo intenso",
      mattePrice: 200,
      glossPrice: 220,
      stock: 15,
      imagePath: "lib/assets/saint.jpeg",
      color: Colors.red,
    ),
    Product(
      id: '2',
      name: "Spice",
      shade: "Rosa suave",
      mattePrice: 180,
      glossPrice: 200,
      stock: 20,
      imagePath: "lib/assets/spice.jpeg",
      color: Colors.pink,
    ),
    Product(
      id: '3',
      name: "Brownie",
      shade: "Marrón chocolate",
      mattePrice: 190,
      glossPrice: 210,
      stock: 10,
      imagePath: "lib/assets/brownie.jpeg",
      color: Colors.brown,
    ),
    Product(
      id: '4',
      name: "Sweet chocolate",
      shade: "Chocolate dulce",
      mattePrice: 220,
      glossPrice: 240,
      stock: 12,
      imagePath: "lib/assets/sweet chocolate.jpeg",
      color: Colors.brown[800]!,
    ),
    Product(
      id: '5',
      name: "Maroon",
      shade: "Granate oscuro",
      mattePrice: 210,
      glossPrice: 230,
      stock: 8,
      imagePath: "lib/assets/maroon.jpeg",
      color: Colors.deepPurple,
    ),
    Product(
      id: '6',
      name: "Hazelnut",
      shade: "Avellana",
      mattePrice: 175,
      glossPrice: 195,
      stock: 18,
      imagePath: "lib/assets/hazelnut.jpeg",
      color: Colors.deepOrange,
    ),
  ];

  List<Product> get products => [..._products];

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(String id, Product newProduct) {
    final index = _products.indexWhere((prod) => prod.id == id);
    if (index >= 0) {
      _products[index] = newProduct;
      notifyListeners();
    }
  }

  void removeProduct(String id) {
    _products.removeWhere((prod) => prod.id == id);
    notifyListeners();
  }

  Product findById(String id) {
    return _products.firstWhere((prod) => prod.id == id);
  }

  void updateProductPrices(String id, int newMattePrice, int newGlossPrice) {
    final index = _products.indexWhere((prod) => prod.id == id);
    if (index >= 0) {
      _products[index].mattePrice = newMattePrice;
      _products[index].glossPrice = newGlossPrice;
      notifyListeners();
    }
  }

  void decreaseStock(String id, int quantity) {
    final index = _products.indexWhere((prod) => prod.id == id);
    if (index >= 0) {
      _products[index].stock -= quantity;
      notifyListeners();
    }
  }
}

class CartItem {
  final String id;
  final String productId;
  final String name;
  final bool isMatte;
  int price;
  final String imagePath;
  int quantity;
  bool isSelected;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.isMatte,
    required this.price,
    required this.imagePath,
    this.quantity = 1,
    this.isSelected = true,
  });
}

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => [..._cartItems];

  void addToCart(Product product, bool isMatte) {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id && item.isMatte == isMatte,
    );

    if (existingItemIndex >= 0) {
      _cartItems[existingItemIndex].quantity += 2; // Incrementa en 2
    } else {
      _cartItems.add(CartItem(
        id: DateTime.now().toString(),
        productId: product.id,
        name: product.name,
        isMatte: isMatte,
        price: isMatte ? product.mattePrice : product.glossPrice,
        imagePath: product.imagePath,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cartItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      notifyListeners();
    }
  }

  void toggleSelection(String itemId) {
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _cartItems[index].isSelected = !_cartItems[index].isSelected;
      notifyListeners();
    }
  }

  int get totalPrice {
    return _cartItems.fold(
      0, 
      (sum, item) => item.isSelected ? sum + (item.price * item.quantity) : sum,
    );
  }

  int get itemCount {
    return _cartItems.length;
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void updatePricesFromInventory(ProductProvider productProvider) {
    for (var item in _cartItems) {
      final product = productProvider.findById(item.productId);
      item.price = item.isMatte ? product.mattePrice : product.glossPrice;
    }
    notifyListeners();
  }

  void completePurchase(ProductProvider productProvider) {
    final itemsToPurchase = _cartItems.where((item) => item.isSelected).toList();
    
    for (var item in itemsToPurchase) {
      productProvider.decreaseStock(item.productId, item.quantity);
    }
    
    _cartItems.removeWhere((item) => item.isSelected);
    notifyListeners();
  }
}

class AuthScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final String? redirectRoute;

  AuthScreen({this.redirectRoute});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.face_retouching_natural,
                          size: 80,
                          color: Colors.pinkAccent,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Belleza en tus labios',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person, color: Colors.pink),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu usuario';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock, color: Colors.pink),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                bool isAuthenticated = authProvider.login(
                                  _usernameController.text,
                                  _passwordController.text,
                                );
                                if (isAuthenticated) {
                                  if (redirectRoute != null) {
                                    Navigator.pushReplacementNamed(context, redirectRoute!);
                                  } else {
                                    Navigator.pushReplacementNamed(context, '/home');
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Credenciales incorrectas'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tienda de Labiales"),
          centerTitle: true,
          backgroundColor: Colors.pinkAccent,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                authProvider.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            Consumer<CartProvider>(
              builder: (_, cart, __) => Badge(
                label: cart.itemCount.toString(),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    if (authProvider.isAuthenticated) {
                      Navigator.pushNamed(context, '/cart');
                    } else {
                      Navigator.pushNamed(context, '/auth', arguments: '/cart');
                    }
                  },
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store), text: "Compras"),
              Tab(icon: Icon(Icons.inventory), text: "Inventario"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.isAuthenticated) {
                  return const ProductGridScreen();
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Debes iniciar sesión para ver las compras'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/auth', arguments: '/home');
                          },
                          child: const Text('Iniciar Sesión'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.isAuthenticated) {
                  return const InventoryScreen();
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Debes iniciar sesión para ver el inventario'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/auth', arguments: '/home');
                          },
                          child: const Text('Iniciar Sesión'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductGridScreen extends StatelessWidget {
  const ProductGridScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products;
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      color: Colors.pink[50],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'product-${product.id}',
              child: Image.asset(
                product.imagePath,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Tono: ${product.shade}",
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPriceButton("Mate", product.mattePrice, true, context),
                _buildPriceButton("Gloss", product.glossPrice, false, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceButton(
      String label, int price, bool isMatte, BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final product = this.product;

    final existingItem = cartProvider.cartItems.firstWhere(
      (item) => item.productId == product.id && item.isMatte == isMatte,
      orElse: () => CartItem(
        id: '',
        productId: '',
        name: '',
        isMatte: false,
        price: 0,
        imagePath: '',
        quantity: 0,
      ),
    );

    final isInCart = existingItem.quantity > 0;

    return ElevatedButton(
      onPressed: () {
        if (product.stock > 0) {
          if (isInCart) {
            cartProvider.updateQuantity(
              existingItem.id, 
              existingItem.quantity + 2, // Incrementa en 2
            );
          } else {
            cartProvider.addToCart(product, isMatte);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isInCart 
                  ? "+2 ${product.name} ($label) en carrito"
                  : "${product.name} ($label) agregado al carrito",
              ),
              duration: Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Producto agotado"),
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 800),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isInCart ? Colors.green : product.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 5,
        shadowColor: Colors.pink.withOpacity(0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInCart) 
            const Icon(Icons.check, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isInCart ? "Agregado (${existingItem.quantity})" : "$label: \$$price",
            style: const TextStyle(
              fontSize: 12, 
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products;
    return Scaffold(
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Image.asset(products[index].imagePath, width: 50, height: 50),
            title: Text(products[index].name),
            subtitle: Text(
              "Tono: ${products[index].shade}\n"
              "Mate: \$${products[index].mattePrice} | Gloss: \$${products[index].glossPrice}\n"
              "Stock: ${products[index].stock}",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showEditProductDialog(context, products[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddProductDialog(context);
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    Product newProduct = Product.empty();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Agregar nuevo producto"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Nombre"),
                    onSaved: (value) => newProduct = newProduct.copyWith(name: value),
                    validator: (value) => value!.isEmpty ? "Requerido" : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Tono"),
                    onSaved: (value) => newProduct = newProduct.copyWith(shade: value),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Precio Mate"),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => newProduct =
                        newProduct.copyWith(mattePrice: int.parse(value!)),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Precio Gloss"),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => newProduct =
                        newProduct.copyWith(glossPrice: int.parse(value!)),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Stock"),
                    keyboardType: TextInputType.number,
                    onSaved: (value) =>
                        newProduct = newProduct.copyWith(stock: int.parse(value!)),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Ruta de imagen"),
                    onSaved: (value) =>
                        newProduct = newProduct.copyWith(imagePath: value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  newProduct = newProduct.copyWith(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
                  );
                  productProvider.addProduct(newProduct);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    Product editedProduct = product.copyWith();
    String originalImagePath = product.imagePath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Editar producto"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: product.name,
                        decoration: const InputDecoration(labelText: "Nombre"),
                        onSaved: (value) => editedProduct = editedProduct.copyWith(name: value),
                      ),
                      TextFormField(
                        initialValue: product.shade,
                        decoration: const InputDecoration(labelText: "Tono"),
                        onSaved: (value) => editedProduct = editedProduct.copyWith(shade: value),
                      ),
                      TextFormField(
                        initialValue: product.mattePrice.toString(),
                        decoration: const InputDecoration(labelText: "Precio Mate"),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => editedProduct =
                            editedProduct.copyWith(mattePrice: int.parse(value!)),
                      ),
                      TextFormField(
                        initialValue: product.glossPrice.toString(),
                        decoration: const InputDecoration(labelText: "Precio Gloss"),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => editedProduct =
                            editedProduct.copyWith(glossPrice: int.parse(value!)),
                      ),
                      TextFormField(
                        initialValue: product.stock.toString(),
                        decoration: const InputDecoration(labelText: "Stock"),
                        keyboardType: TextInputType.number,
                        onSaved: (value) =>
                            editedProduct = editedProduct.copyWith(stock: int.parse(value!)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Imagen actual:",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      Image.asset(
                        editedProduct.imagePath,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showImageSelectionDialog(context, (newImagePath) {
                            setState(() {
                              editedProduct = editedProduct.copyWith(imagePath: newImagePath);
                            });
                          }, originalImagePath);
                        },
                        child: const Text("Cambiar Imagen"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text("Guardar"),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      productProvider.updateProduct(product.id, editedProduct);
                      cartProvider.updatePricesFromInventory(productProvider);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    productProvider.removeProduct(product.id);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImageSelectionDialog(BuildContext context, Function(String) onImageSelected, String originalImagePath) {
    final List<String> availableImages = [
      "lib/assets/saint.jpeg",
      "lib/assets/spice.jpeg",
      "lib/assets/brownie.jpeg",
      "lib/assets/sweet_chocolate.jpeg",
      "lib/assets/maroon.jpeg",
      "lib/assets/hazelnut.jpeg",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Seleccionar Imagen"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: availableImages.length + 1, // +1 para la opción original
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () {
                      onImageSelected(originalImagePath);
                      Navigator.of(context).pop();
                    },
                    child: Column(
                      children: [
                        const Icon(Icons.restore, size: 40),
                        const SizedBox(height: 5),
                        const Text("Original"),
                      ],
                    ),
                  );
                }
                
                final imagePath = availableImages[index - 1];
                return GestureDetector(
                  onTap: () {
                    onImageSelected(imagePath);
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Carrito"),
          centerTitle: true,
          backgroundColor: Colors.pinkAccent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Debes iniciar sesión para ver el carrito'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/auth', arguments: '/cart');
                },
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carrito"),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartProvider.cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: cartItem.isSelected,
                      onChanged: (value) {
                        cartProvider.toggleSelection(cartItem.id);
                      },
                    ),
                    title: Text(cartItem.name),
                    subtitle: Text(
                        "${cartItem.isMatte ? "Mate" : "Gloss"} - \$${cartItem.price} x ${cartItem.quantity}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (cartItem.quantity > 1) {
                              cartProvider.updateQuantity(
                                  cartItem.id, cartItem.quantity - 1);
                            } else {
                              cartProvider.removeFromCart(cartItem.id);
                            }
                          },
                        ),
                        Text("${cartItem.quantity}"),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            cartProvider.updateQuantity(
                                cartItem.id, cartItem.quantity + 1);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total:",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "\$${cartProvider.totalPrice}",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        cartProvider.clearCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Carrito vaciado")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Vaciar Carrito"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (cartProvider.cartItems.any((item) => item.isSelected)) {
                          cartProvider.completePurchase(productProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Compra realizada por \$${cartProvider.totalPrice}",
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selecciona al menos un producto"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Pagar",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Badge extends StatelessWidget {
  final Widget child;
  final String label;

  const Badge({
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.red,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
        )
      ],
    );
  }
}
