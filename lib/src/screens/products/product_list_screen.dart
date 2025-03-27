import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/Product_controller.dart';
import 'package:sample/src/screens/products/product_registration_screen.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool isDeleteSuccess = false;
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;
  late ProductController _productListController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
      _productListController = Provider.of<ProductController>(
        context,
        listen: false,
      );
      _productListController.getProductData().then((_) {
        setState(() {
          _isInitialLoad = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        if (!_productListController.isLoading &&
            _productListController.hasMore) {
          _productListController.loadMore();
          showInfoSnack('Loading...');
        }
      }
    });
  }

  void _deleteProduct(int index) {
    final productId = _productListController.productData?[index]['id'];
    print('productId $productId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Product"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Are you sure you want to delete this product?"),

              SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for deletion',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {
                String reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  if (productId != null) {
                    await _productListController.deleteProduct(
                      productId,
                      reason,
                    );
                  }
                  Navigator.pop(context);
                  showSuccessSnack("Customer Deleted successfully");
                } else {
                  showErrorSnack("Please enter a reason for deletion");
                }
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Debounce search logic
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<ProductController>();
    final products =
        watch.productData != null
            ? (watch.productData ?? [])
                .where(
                  (product) => (product['Name'] ?? '').toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList()
            : [];
    return Consumer<ProductController>(
      builder: (context, productController, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Products List')),
          body:
              watch.isLoading && _isInitialLoad
                  ? Center(child: CircularProgressIndicator())
                  : watch.productData != null
                  ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Search Box
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name...',
                              hintStyle: TextStyle(
                                color: Appcolors.textLightGrayColor(context),
                              ),
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),

                            onChanged: _onSearchChanged,
                          ),
                        ),
                        // Customer List
                        Expanded(
                          child:
                              products.isEmpty
                                  ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'No products registered yet.'
                                          : 'No results found.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    // padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return Column(
                                        children: [
                                          ListTile(
                                            // contentPadding: EdgeInsets.all(
                                            //   8.0,
                                            // ),
                                            leading: Icon(
                                              Icons.person,
                                              size: 30,
                                            ),
                                            title: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 2,
                                              ),
                                              child: Text(
                                                product['Name'] ?? '',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge!.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    NavigationService()
                                                        .pushNavigation(
                                                          Screenroutes
                                                              .productEdit,
                                                          arguments: product,
                                                        );
                                                  },

                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () async {
                                                    _deleteProduct(index);
                                                  },
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            child: Divider(
                                              color: Colors.grey,
                                              thickness: .5,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  )
                  : SizedBox.shrink(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductRegistrationScreen(),
                ),
              );
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
