import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCOgS_d80TgjchVz1a56OTaGaXGrOuox_Y",
      authDomain: "labiales-4f8fc.firebaseapp.com",
      projectId: "labiales-4f8fc",
      storageBucket: "labiales-4f8fc.appspot.com",
      messagingSenderId: "754212501817",
      appId: "1:754212501817:web:9ad52e0d3e6675e50b50e8",
    ),
  );

  final productProvider = ProductProvider();
  await productProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => productProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ImageProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
        '/sales': (context) => SalesHistoryScreen(),
        '/users': (context) => UserManagementScreen(),
      },
    );
  }
}

// Model Classes
class Product {
  final String id;
  final String name;
  final String shade;
  int mattePrice;
  int glossPrice;
  int stock;
  final String imagePath;
  final Color color;

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

class ImagenProducto {
  final String id;
  final String productId;
  final String url;
  final String path;
  final bool isMain;
  final DateTime uploadDate;

  ImagenProducto({
    required this.id,
    required this.productId,
    required this.url,
    required this.path,
    this.isMain = false,
    required this.uploadDate,
  });
}

class Venta {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final DateTime fecha;
  final String estado;
  final String? direccionEnvio;
  final String metodoPago;
  bool notificada;

  Venta({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.fecha,
    this.estado = 'completada',
    this.direccionEnvio,
    this.metodoPago = 'efectivo',
    this.notificada = false,
  });
}

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? direccion;
  final DateTime fechaRegistro;
  DateTime ultimoAcceso;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.direccion,
    required this.fechaRegistro,
    required this.ultimoAcceso,
    this.rol = 'cliente',
  });
}

// Providers
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _username = 'admin';
  String _password = 'admin123';
  Usuario? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  Usuario? get currentUser => _currentUser;

  bool login(String username, String password) {
    if (username == _username && password == _password) {
      _isAuthenticated = true;
      _currentUser = Usuario(
        id: 'admin-001',
        nombre: 'Administrador',
        email: 'admin@labiales.com',
        fechaRegistro: DateTime.now(),
        ultimoAcceso: DateTime.now(),
        rol: 'admin',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _products = [];
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  List<Product> get products => [..._products];

  Future<void> initialize() async {
    await _setupFirestoreListener();
    await _uploadLocalProductsIfNeeded();
  }

  Future<void> _setupFirestoreListener() async {
    _firestoreSubscription = _firestore.collection('labiales').snapshots().listen((snapshot) {
      _products = snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          shade: data['shade'] ?? '',
          mattePrice: data['mattePrice'] ?? 0,
          glossPrice: data['glossPrice'] ?? 0,
          stock: data['stock'] ?? 0,
          imagePath: data['imagePath'] ?? '',
          color: Color(int.parse(data['color'] ?? '0xFFFF0000')),
        );
      }).toList();
      notifyListeners();
    }, onError: (e) => print("❌ Firestore error: $e"));
  }

  Future<void> _uploadLocalProductsIfNeeded() async {
    final snapshot = await _firestore.collection('labiales').limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (final product in _localProducts) {
        await _syncToFirestore(product);
      }
    }
  }

  Future<void> _syncToFirestore(Product product) async {
    try {
      await _firestore.collection('labiales').doc(product.id).set({
        'id': product.id,
        'name': product.name,
        'shade': product.shade,
        'mattePrice': product.mattePrice,
        'glossPrice': product.glossPrice,
        'stock': product.stock,
        'imagePath': product.imagePath,
        'color': '0x${product.color.value.toRadixString(16).padLeft(8, '0')}',
      }, SetOptions(merge: true));
    } catch (e) {
      print("❌ Sync error: $e");
    }
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
    _syncToFirestore(product);
  }

  void updateProduct(String id, Product newProduct) {
    final index = _products.indexWhere((prod) => prod.id == id);
    if (index >= 0) {
      _products[index] = newProduct;
      notifyListeners();
      _syncToFirestore(newProduct);
    }
  }

  void removeProduct(String id) {
    _products.removeWhere((prod) => prod.id == id);
    notifyListeners();
    _firestore.collection('labiales').doc(id).delete()
      .catchError((e) => print("❌ Delete error: $e"));
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
      _syncToFirestore(_products[index]);
    }
  }

  void decreaseStock(String id, int quantity) {
    final index = _products.indexWhere((prod) => prod.id == id);
    if (index >= 0) {
      _products[index].stock -= quantity;
      notifyListeners();
      _syncToFirestore(_products[index]);
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  static final List<Product> _localProducts = [
    Product(
      id: '1',
      name: "Saint",
      shade: "Rojo intenso",
      mattePrice: 200,
      glossPrice: 220,
      stock: 15,
      imagePath: "lib/assets/saint.jpeg",
      color: const Color(0xFFF44336),
    ),
    Product(
      id: '2',
      name: "Spice",
      shade: "Rosa suave",
      mattePrice: 180,
      glossPrice: 200,
      stock: 20,
      imagePath: "lib/assets/spice.jpeg",
      color: const Color(0xFFE91E63),
    ),
    Product(
      id: '3',
      name: "Brownie",
      shade: "Marrón chocolate",
      mattePrice: 190,
      glossPrice: 210,
      stock: 10,
      imagePath: "lib/assets/brownie.jpeg",
      color: const Color(0xFF795548),
    ),
    Product(
      id: '4',
      name: "Sweet chocolate",
      shade: "Chocolate dulce",
      mattePrice: 220,
      glossPrice: 240,
      stock: 12,
      imagePath: "lib/assets/sweet chocolate.jpeg",
      color: const Color(0xFF4E342E),
    ),
    Product(
      id: '5',
      name: "Maroon",
      shade: "Granate oscuro",
      mattePrice: 210,
      glossPrice: 230,
      stock: 8,
      imagePath: "lib/assets/maroon.jpeg",
      color: const Color(0xFF673AB7),
    ),
    Product(
      id: '6',
      name: "Hazelnut",
      shade: "Avellana",
      mattePrice: 175,
      glossPrice: 195,
      stock: 18,
      imagePath: "lib/assets/hazelnut.jpeg",
      color: const Color(0xFFFF5722),
    ),
  ];
}

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => [..._cartItems];

  void addToCart(Product product, bool isMatte) {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id && item.isMatte == isMatte,
    );

    if (existingItemIndex >= 0) {
      _cartItems[existingItemIndex].quantity += 2;
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

  int get itemCount => _cartItems.length;

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

  void completePurchase(BuildContext context) {
  final productProvider = Provider.of<ProductProvider>(context, listen: false);
  final salesProvider = Provider.of<SalesProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  final itemsToPurchase = _cartItems.where((item) => item.isSelected).toList();
  final purchaseTotal = itemsToPurchase.fold(0, (sum, item) => sum + (item.price * item.quantity));
  
  if (itemsToPurchase.isNotEmpty && authProvider.currentUser != null) {
    final nuevaVenta = Venta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authProvider.currentUser!.id,
      items: itemsToPurchase,
      total: purchaseTotal.toDouble(),
      fecha: DateTime.now(),
    );
    
    salesProvider.addSale(nuevaVenta);
    
    for (var item in itemsToPurchase) {
      productProvider.decreaseStock(item.productId, item.quantity);
    }
    
    _cartItems.removeWhere((item) => item.isSelected);
    notifyListeners();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Compra realizada por \$${purchaseTotal.toStringAsFixed(2)}"),
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
}
}

class ImageProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ImagenProducto> _imagenes = [];

  List<ImagenProducto> get imagenes => [..._imagenes];

  Future<void> uploadImage(String productId, String imagePath) async {
    try {
      // Implementar subida a Firebase Storage aquí
      final downloadURL = 'https://example.com/image.jpg'; // URL temporal
      
      final nuevaImagen = ImagenProducto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        url: downloadURL,
        path: imagePath,
        uploadDate: DateTime.now(),
      );

      await _firestore.collection('imagenes').doc(nuevaImagen.id).set({
        'id': nuevaImagen.id,
        'productId': nuevaImagen.productId,
        'url': nuevaImagen.url,
        'path': nuevaImagen.path,
        'isMain': nuevaImagen.isMain,
        'uploadDate': Timestamp.fromDate(nuevaImagen.uploadDate),
      });

      _imagenes.add(nuevaImagen);
      notifyListeners();
    } catch (e) {
      print("Error al subir imagen: $e");
    }
  }

  Future<void> fetchImagesForProduct(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('imagenes')
          .where('productId', isEqualTo: productId)
          .get();

      _imagenes = snapshot.docs.map((doc) {
        final data = doc.data();
        return ImagenProducto(
          id: doc.id,
          productId: data['productId'],
          url: data['url'],
          path: data['path'],
          isMain: data['isMain'] ?? false,
          uploadDate: (data['uploadDate'] as Timestamp).toDate(),
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print("Error al obtener imágenes: $e");
    }
  }
}

class SalesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Venta> _ventas = [];

  List<Venta> get ventas => [..._ventas];

  Future<void> addSale(Venta venta) async {
    try {
      await _firestore.collection('ventas').doc(venta.id).set({
        'id': venta.id,
        'userId': venta.userId,
        'items': venta.items.map((item) => {
          'id': item.id,
          'productId': item.productId,
          'name': item.name,
          'isMatte': item.isMatte,
          'price': item.price,
          'imagePath': item.imagePath,
          'quantity': item.quantity,
        }).toList(),
        'total': venta.total,
        'fecha': Timestamp.fromDate(venta.fecha),
        'estado': venta.estado,
        'direccionEnvio': venta.direccionEnvio,
        'metodoPago': venta.metodoPago,
        'notificada': venta.notificada,
      });

      _ventas.add(venta);
      notifyListeners();
      
      await _sendEmailNotification(venta);
    } catch (e) {
      print("Error al registrar venta: $e");
    }
  }

  Future<void> _sendEmailNotification(Venta venta) async {
    try {
      // Configura tus credenciales de EmailJS aquí
      const emailjsUserId = '8hwknZmr5OEcD0vpq';
      const serviceId = 'service_pdrhhyg';
      const templateId = 'template_kno7jhg';
      
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': emailjsUserId,
          'template_params': {
            'to_email': 'admin@labiales.com',
            'to_name': 'Administrador',
            'sale_id': venta.id,
            'total': venta.total.toStringAsFixed(2),
            'items': venta.items.map((item) => 
              '${item.quantity}x ${item.name} (${item.isMatte ? "Mate" : "Gloss"}) - \$${item.price}'
            ).join('\n'),
            'date': venta.fecha.toString(),
          }
        }),
      );

      if (response.statusCode == 200) {
        venta.notificada = true;
        await _firestore.collection('ventas').doc(venta.id).update({
          'notificada': true,
        });
      } else {
        print("Error al enviar email: ${response.body}");
      }
    } catch (e) {
      print("Error al enviar email: $e");
    }
  }

  Future<void> fetchSales() async {
    try {
      final snapshot = await _firestore.collection('ventas').get();
      _ventas = snapshot.docs.map((doc) {
        final data = doc.data();
        return Venta(
          id: doc.id,
          userId: data['userId'],
          items: (data['items'] as List).map((item) => CartItem(
            id: item['id'],
            productId: item['productId'],
            name: item['name'],
            isMatte: item['isMatte'],
            price: item['price'],
            imagePath: item['imagePath'],
            quantity: item['quantity'],
          )).toList(),
          total: data['total'],
          fecha: (data['fecha'] as Timestamp).toDate(),
          estado: data['estado'],
          direccionEnvio: data['direccionEnvio'],
          metodoPago: data['metodoPago'],
          notificada: data['notificada'] ?? false,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print("Error al obtener ventas: $e");
    }
  }
}

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Usuario> _usuarios = [];

  List<Usuario> get usuarios => [..._usuarios];

  Future<void> addUser(Usuario usuario) async {
    try {
      await _firestore.collection('usuarios').doc(usuario.id).set({
        'id': usuario.id,
        'nombre': usuario.nombre,
        'email': usuario.email,
        'telefono': usuario.telefono,
        'direccion': usuario.direccion,
        'fechaRegistro': Timestamp.fromDate(usuario.fechaRegistro),
        'ultimoAcceso': Timestamp.fromDate(usuario.ultimoAcceso),
        'rol': usuario.rol,
      });

      _usuarios.add(usuario);
      notifyListeners();
    } catch (e) {
      print("Error al agregar usuario: $e");
    }
  }

  Future<Usuario?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Usuario(
          id: doc.id,
          nombre: data['nombre'],
          email: data['email'],
          telefono: data['telefono'],
          direccion: data['direccion'],
          fechaRegistro: (data['fechaRegistro'] as Timestamp).toDate(),
          ultimoAcceso: (data['ultimoAcceso'] as Timestamp).toDate(),
          rol: data['rol'],
        );
      }
      return null;
    } catch (e) {
      print("Error al obtener usuario: $e");
      return null;
    }
  }

  Future<void> fetchUsers() async {
    try {
      final snapshot = await _firestore.collection('usuarios').get();
      _usuarios = snapshot.docs.map((doc) {
        final data = doc.data();
        return Usuario(
          id: doc.id,
          nombre: data['nombre'],
          email: data['email'],
          telefono: data['telefono'],
          direccion: data['direccion'],
          fechaRegistro: (data['fechaRegistro'] as Timestamp).toDate(),
          ultimoAcceso: (data['ultimoAcceso'] as Timestamp).toDate(),
          rol: data['rol'],
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print("Error al obtener usuarios: $e");
    }
  }
}

// Screens
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            Consumer<CartProvider>(
              builder: (context, cart, _) => Badge(
                label: Text(cart.itemCount.toString()),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    if (Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
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
              existingItem.quantity + 2,
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
      "lib/assets/sweet chocolate.jpeg",
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
              itemCount: availableImages.length + 1,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/sales');
            },
          ),
        ],
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
                          cartProvider.completePurchase(context);
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

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Ventas"),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
      ),
      body: FutureBuilder(
        future: salesProvider.fetchSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            itemCount: salesProvider.ventas.length,
            itemBuilder: (context, index) {
              final venta = salesProvider.ventas[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Venta #${venta.id.substring(0, 8)}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total: \$${venta.total.toStringAsFixed(2)}"),
                      Text("Fecha: ${venta.fecha.toString().substring(0, 16)}"),
                      Text("Estado: ${venta.estado}"),
                      Text("Productos: ${venta.items.length}"),
                    ],
                  ),
                  trailing: Icon(
                    venta.notificada ? Icons.email : Icons.email_outlined,
                    color: venta.notificada ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    _showSaleDetails(context, venta, userProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSaleDetails(BuildContext context, Venta venta, UserProvider userProvider) async {
    final usuario = await userProvider.getUser(venta.userId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Detalles de Venta #${venta.id.substring(0, 8)}"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Cliente: ${usuario?.nombre ?? 'Desconocido'}"),
                Text("Email: ${usuario?.email ?? 'No disponible'}"),
                Text("Fecha: ${venta.fecha.toString()}"),
                Text("Total: \$${venta.total.toStringAsFixed(2)}"),
                Text("Método de pago: ${venta.metodoPago}"),
                const SizedBox(height: 16),
                const Text("Productos:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...venta.items.map((item) => 
                  Text("${item.quantity}x ${item.name} (${item.isMatte ? "Mate" : "Gloss"}) - \$${item.price}")
                ).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
      ),
      body: FutureBuilder(
        future: userProvider.fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            itemCount: userProvider.usuarios.length,
            itemBuilder: (context, index) {
              final usuario = userProvider.usuarios[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(usuario.nombre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${usuario.email}"),
                      Text("Rol: ${usuario.rol}"),
                      Text("Registro: ${usuario.fechaRegistro.toString().substring(0, 10)}"),
                    ],
                  ),
                  trailing: Icon(
                    usuario.rol == 'admin' ? Icons.admin_panel_settings : Icons.person,
                    color: usuario.rol == 'admin' ? Colors.pinkAccent : Colors.blue,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddUserDialog(context);
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();
    String selectedRol = 'cliente';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Agregar Usuario"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(labelText: "Nombre"),
                        validator: (value) => value!.isEmpty ? "Requerido" : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (value) => value!.isEmpty ? "Requerido" : null,
                      ),
                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(labelText: "Teléfono"),
                        keyboardType: TextInputType.phone,
                      ),
                      TextFormField(
                        controller: direccionController,
                        decoration: const InputDecoration(labelText: "Dirección"),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedRol,
                        items: ['cliente', 'admin'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value == 'admin' ? 'Administrador' : 'Cliente'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedRol = newValue!;
                          });
                        },
                        decoration: const InputDecoration(labelText: "Rol"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final nuevoUsuario = Usuario(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nombre: nombreController.text,
                        email: emailController.text,
                        telefono: telefonoController.text,
                        direccion: direccionController.text,
                        fechaRegistro: DateTime.now(),
                        ultimoAcceso: DateTime.now(),
                        rol: selectedRol,
                      );
                      
                      userProvider.addUser(nuevoUsuario);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class Badge extends StatelessWidget {
  final Widget child;
  final Widget label;

  const Badge({required this.child, required this.label});

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
            child: Center(child: label),
          ),
        )
      ],
    );
  }
}
