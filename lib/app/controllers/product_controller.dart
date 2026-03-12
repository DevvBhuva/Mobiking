import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/product_model.dart';
import '../services/product_service.dart';
import '../utils/image_utils.dart';

class ProductController extends GetxController {
  final ProductService _productService = ProductService();

  // 🚀 OPTIMIZED: Separate observables for different data types
  var allProducts = <ProductModel>[].obs;
  var isLoading = false.obs;
  var selectedProduct = Rxn<ProductModel>();
  var searchResults = <ProductModel>[].obs;
  var frequentlyBoughtTogetherProducts = <ProductModel>[].obs;
  var isFetchingFrequentlyBoughtTogether = false.obs;
  var relatedProducts = <ProductModel>[].obs;
  var isFetchingRelatedProducts = false.obs;

  // 🚀 LAZY LOADING: Advanced pagination states
  var isFetchingMore = false.obs;
  var hasMoreProducts = true.obs;
  var initialLoadCompleted = false.obs;

  // 🚀 OPTIMIZATION: Configurable pagination
  final int _productsPerPage = 12; // Increased for better UX
  int _currentPage = 0; // Start from 0 for cleaner logic
  int _totalProductsLoaded = 0;

  // 🚀 LAZY LOADING: Cache management
  final int _maxCacheSize = 200; // Limit memory usage
  var _lastFetchTime = DateTime.now();

  // 🚀 OPTIMIZATION: Request debouncing
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeLazyLoading();
  }

  /// 🚀 LAZY LOADING: Initialize but don't fetch data immediately
  void _initializeLazyLoading() {
    print("🎯 ProductController initialized - Ready for lazy loading");
    // Don't fetch data here - let the UI components request it when needed
  }

  /// 🚀 LAZY LOADING: Fetch products only when UI requests them
  Future<void> loadProductsOnDemand() async {
    if (initialLoadCompleted.value && allProducts.isNotEmpty) {
      print("📋 Products already loaded, skipping initial fetch");
      return;
    }

    await fetchInitialProducts();
  }

  /// 🔰 OPTIMIZED: Fetch first batch of products
  Future<void> fetchInitialProducts() async {
    if (isLoading.value) {
      print("⏳ Already loading, skipping duplicate request");
      return;
    }

    try {
      print("🚀 Starting initial product fetch...");
      isLoading.value = true;
      _currentPage = 1;
      _totalProductsLoaded = 0;

      final products = await _productService.getAllProducts(
        page: _currentPage,
        limit: _productsPerPage,
      );

      // Filter for active products
      final activeProducts = products.where((p) => p.active == true).toList();

      print("✅ Fetched ${activeProducts.length} initial active products");

      allProducts.assignAll(activeProducts);
      _totalProductsLoaded = activeProducts.length;
      hasMoreProducts.value = products.length == _productsPerPage;
      initialLoadCompleted.value = true;
      _lastFetchTime = DateTime.now();

      // 🚀 OPTIMIZATION: Pre-cache images in background
      _preCacheProductImages(activeProducts);
    } catch (e) {
      print('❌ Error fetching initial products: $e');
      hasMoreProducts.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 🚀 LAZY LOADING: Smart fetch more with debouncing
  Future<void> fetchMoreProducts() async {
    // 🚀 OPTIMIZATION: Prevent duplicate requests
    if (isFetchingMore.value || !hasMoreProducts.value || isLoading.value) {
      print(
        "⏸ Skipping fetch more - isFetching: ${isFetchingMore.value}, hasMore: ${hasMoreProducts.value}",
      );
      return;
    }

    try {
      isFetchingMore.value = true;
      _currentPage++;

      final products = await _productService.getAllProducts(
        page: _currentPage,
        limit: _productsPerPage,
      );

      final activeProducts = products.where((p) => p.active == true).toList();

      if (activeProducts.isEmpty) {
        hasMoreProducts.value = false;
        return;
      }

      allProducts.addAll(activeProducts);
      _totalProductsLoaded += activeProducts.length;
      hasMoreProducts.value = products.length == _productsPerPage;

      // 🚀 OPTIMIZATION: Pre-cache new images
      _preCacheProductImages(activeProducts);
      
      print("✅ Completed loading page $_currentPage (Total: $_totalProductsLoaded products)");
    } catch (e) {
      print('❌ Error fetching more products: $e');
      hasMoreProducts.value = false;
    } finally {
      isFetchingMore.value = false;
    }
  }

  /// 🚀 OPTIMIZATION: Pre-cache images for a list of products
  void _preCacheProductImages(List<ProductModel> products) {
    if (Get.context == null) return;

    // We pre-cache both original and 200px (standard grid size) for instant display
    for (var product in products) {
      if (product.images.isNotEmpty && product.images[0].isNotEmpty) {
        final originalUrl = product.images[0];
        final resizedUrl = getResizedImageUrl(originalUrl, 200);

        try {
          // Pre-cache original (for product detail page and some cards)
          precacheImage(
            CachedNetworkImageProvider(originalUrl),
            Get.context!,
          );
          
          // Pre-cache 200px (for the main product grid scroll performance)
          precacheImage(
            CachedNetworkImageProvider(resizedUrl),
            Get.context!,
          );
        } catch (e) {
          // Ignore pre-cache errors
        }
      }
    }
  }

  /// 🚀 LAZY LOADING: Get products for specific category (lazy loaded)
  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    int limit = 6,
  }) async {
    // First check if we have products in memory
    final categoryProducts = allProducts
        .where((product) => product.category?.id == categoryId)
        .take(limit)
        .toList();

    if (categoryProducts.length >= limit || !hasMoreProducts.value) {
      print(
        "📋 Using cached products for category $categoryId: ${categoryProducts.length} items",
      );
      return categoryProducts;
    }

    // If not enough in cache, fetch more data
    print("🔄 Need more products for category $categoryId, fetching...");
    await loadProductsOnDemand();

    // Return updated results
    return allProducts
        .where((product) => product.category?.id == categoryId)
        .take(limit)
        .toList();
  }

  /// 🚀 LAZY LOADING: Optimized search with caching
  Future<void> searchProducts(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty || trimmedQuery.length < 2) {
      searchResults.clear();
      return;
    }

    await _executeSearch(trimmedQuery);
  }

  Future<void> _executeSearch(String query) async {
    try {
      print("🔍 Searching products for: '$query'");
      isLoading.value = true;

      final results = await _productService.searchProducts(query);

      // Filter for active products
      final activeResults = results.where((p) => p.active == true).toList();

      searchResults.assignAll(activeResults);
      print("🎯 Found ${activeResults.length} active search results");
      
      // 🚀 OPTIMIZATION: Pre-cache search results
      _preCacheProductImages(activeResults);
    } catch (e) {
      print('❌ Search error: $e');
      searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 🚀 LAZY LOADING: Smart product by slug with caching
  Future<void> fetchProductBySlug(String slug) async {
    try {
      // Check if product is already in cache
      final cachedProduct = allProducts.firstWhereOrNull(
        (product) => product.slug == slug,
      );

      if (cachedProduct != null) {
        print("⚡ Using cached product for slug: $slug");
        selectedProduct.value = cachedProduct;
        return;
      }

      print("🔄 Fetching product by slug: $slug");
      isLoading.value = true;
      selectedProduct.value = null;

      final product = await _productService.fetchProductBySlug(slug);
      selectedProduct.value = product;

      // 🚀 OPTIMIZATION: Add to cache if not exists
      if (!allProducts.any((p) => p.id == product.id)) {
        allProducts.add(product);
      }
    } catch (e) {
      print('❌ Error fetching product by slug: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🆕 OPTIMIZED: Add new product with smart cache update
  Future<void> addProduct(ProductModel product) async {
    try {
      isLoading.value = true;
      final newProduct = await _productService.createProduct(product);

      // 🚀 OPTIMIZATION: Add to front of list for immediate visibility
      allProducts.insert(0, newProduct);
      _totalProductsLoaded++;

      print("✅ Product added successfully: ${newProduct.name}");
    } catch (e) {
      print('❌ Error adding product: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🚀 LAZY LOADING: Get related products with smart caching
  List<ProductModel> getProductsInSameParentCategory(
    String currentProductId,
    String? parentCategory,
  ) {
    if (parentCategory == null || parentCategory.isEmpty) {
      return [];
    }

    final relatedProducts = allProducts
        .where((product) {
          return product.active == true &&
              product.id != currentProductId &&
              product.category != null &&
              product.category!.id == parentCategory;
        })
        .take(6)
        .toList(); // Limit to 6 for performance

    print(
      "🔗 Found ${relatedProducts.length} related products for category $parentCategory",
    );
    return relatedProducts;
  }

  /// 🚀 LAZY LOADING: Get related products by group
  List<ProductModel> getProductsInSameGroup(
    String currentProductId,
    List<String> groupIds,
  ) {
    print("DEBUG: currentProductId = $currentProductId");
    print("DEBUG: groupIds = $groupIds");
    print("DEBUG: allProducts.length = ${allProducts.length}");

    if (groupIds.isEmpty) {
      return [];
    }

    final relatedProducts = allProducts
        .where((product) {
          if (product.active == false) {
            return false;
          }
          if (product.id == currentProductId) {
            return false;
          }
          if (product.groupIds.isEmpty) {
            return false;
          }
          // Check if there is any intersection between the product's groups and the current product's groups.
          return product.groupIds.any((groupId) => groupIds.contains(groupId));
        })
        .take(6)
        .toList();

    print("DEBUG: found ${relatedProducts.length} related products");
    print(
      "🔗 Found ${relatedProducts.length} related products for groups $groupIds",
    );
    return relatedProducts;
  }

  /// 🚀 OPTIMIZATION: Force refresh data
  Future<void> refreshProducts() async {
    print("🔄 Refreshing all products...");
    allProducts.clear();
    _currentPage = 0;
    _totalProductsLoaded = 0;
    hasMoreProducts.value = true;
    initialLoadCompleted.value = false;

    await fetchInitialProducts();
  }

  /// 🚀 OPTIMIZATION: Clear cache and reset state
  void clearCache() {
    print("🧹 Clearing product cache...");
    allProducts.clear();
    searchResults.clear();
    selectedProduct.value = null;
    _currentPage = 0;
    _totalProductsLoaded = 0;
    hasMoreProducts.value = true;
    initialLoadCompleted.value = false;
  }

  /// 🚀 OPTIMIZATION: Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalProductsLoaded': _totalProductsLoaded,
      'currentPage': _currentPage,
      'hasMoreProducts': hasMoreProducts.value,
      'cacheSize': allProducts.length,
      'lastFetchTime': _lastFetchTime.toIso8601String(),
      'initialLoadCompleted': initialLoadCompleted.value,
    };
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// Fetch related products by slug
  Future<void> fetchRelatedProducts(String slug) async {
    if (isFetchingRelatedProducts.value) return;

    try {
      isFetchingRelatedProducts.value = true;
      final products = await _productService.fetchRelatedProducts(slug);
      relatedProducts.assignAll(products);
      
      // 🚀 OPTIMIZATION: Pre-cache related products
      _preCacheProductImages(products);
    } catch (e) {
      print('Error fetching related products: $e');
    } finally {
      isFetchingRelatedProducts.value = false;
    }
  }
}
