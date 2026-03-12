import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import '../data/Home_model.dart';
import '../data/group_model.dart';
import '../services/home_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:get_storage/get_storage.dart'; // Import GetStorage
import 'package:flutter/widgets.dart'; // For precacheImage
import 'package:cached_network_image/cached_network_image.dart'; // For CachedNetworkImageProvider
import '../utils/image_utils.dart'; // For getResizedImageUrl
import 'tab_controller_getx.dart';

class HomeController extends GetxController {
  final GetStorage _box = GetStorage(); // GetStorage instance
  late final HomeService _service = HomeService(
    _box,
  ); // Pass GetStorage to HomeService
  final ConnectivityController _connectivityController = Get.find();

  /// Only expose loading state when needed for UI
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  /// Expose categories
  final RxList<CategoryModel> _categories = <CategoryModel>[].obs;
  List<CategoryModel> get categories => _categories;

  /// Expose groups per category
  final RxMap<String, List<GroupModel>> _categoryGroups = <String, List<GroupModel>>{}.obs;
  Map<String, List<GroupModel>> get categoryGroups => _categoryGroups;

  /// Loading state per category
  final RxMap<String, bool> _categoryLoading = <String, bool>{}.obs;
  bool isCategoryLoading(String categoryId) => _categoryLoading[categoryId] ?? false;

  /// DEPRECATED: Expose final home data (kept for layout model compatibility if needed)
  final Rxn<HomeLayoutModel> _homeData = Rxn<HomeLayoutModel>();
  HomeLayoutModel? get homeData => _homeData.value;
  
  /// Timer for auto-refresh
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    // 🚀 NEW FLOW: Fetch categories first
    fetchAppCategories();
    _startAutoRefresh();

    // Listen to tab changes to fetch groups on demand
    // We use a small delay to ensure TabController is fully initialized if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<TabControllerGetX>()) {
        final tabController = Get.find<TabControllerGetX>();
        ever(tabController.selectedIndex, (int index) {
          if (_categories.isNotEmpty && index < _categories.length) {
            final categoryId = _categories[index].id;
            fetchGroupsForCategory(categoryId);
          }
        });
      }
    });

    // Only refetch on reconnection
    ever<bool>(_connectivityController.isConnected, (isConnected) {
      if (isConnected) _handleConnectionRestored();
    });
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      print('[HomeController] 🔄 Silent Auto-refresh triggered');
      fetchAppCategories(forceRefresh: true, silent: true);
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> _handleConnectionRestored() async {
    print('[HomeController] ✅ Re-connected. Refreshing...');
    await fetchAppCategories();
  }

  /// 1. Fetch Categories and Banners with Silent Update Support
  Future<void> fetchAppCategories({bool forceRefresh = false, bool silent = false}) async {
    // 🚀 Check if we already have data to prevent UI flicker
    final bool hasMemory = _categories.isNotEmpty;
    final bool hasCache = _service.hasCachedCategories();

    if (_isLoading.value) return;

    try {
      // 🚀 ONLY show shimmer if it's the VERY FIRST time (no memory AND no cache)
      // AND we are NOT in silent mode.
      if (!hasMemory && !hasCache && !silent) {
        _isLoading.value = true;
      }

      final result = await _service.getAppCategories(forceRefresh: forceRefresh);
      
      if (result.isNotEmpty) {
        // Only update memory if data actually changed to avoid UI jump
        if (_categories.isEmpty || _isCategoryListDifferent(_categories, result)) {
          _categories.assignAll(result);
          
          // Sync with legacy homeData model (only if different)
          _homeData.value = HomeLayoutModel(
            id: 'app_home',
            active: true,
            banners: [],
            groups: [],
            categories: result,
          );
        }
        
        // ✅ Sync TabController length
        if (Get.isRegistered<TabControllerGetX>()) {
          Get.find<TabControllerGetX>().resetWithLength(result.length);
        }

        // 🚀 BLINKIT-LEVEL BOOT: Parallel fetch ALL categories and ALL groups
        // We don't wait for these, they happen silently in background
        Future.wait(result.map((cat) async {
          _precacheCategoryBanners(cat);
          return fetchGroupsForCategory(cat.id, forceRefresh: forceRefresh, silent: true);
        }));
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  bool _isCategoryListDifferent(List<CategoryModel> oldList, List<CategoryModel> newList) {
    if (oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].id != newList[i].id || oldList[i].name != newList[i].name) return true;
    }
    return false;
  }

  /// 2. Fetch Groups for a specific category ON DEMAND
  Future<void> fetchGroupsForCategory(String categoryId, {bool forceRefresh = false, bool silent = false}) async {
    // 🚀 Check cache status
    final bool hasCache = _service.hasCachedGroups(categoryId);
    final bool hasDataMemory = _categoryGroups.containsKey(categoryId) && _categoryGroups[categoryId]!.isNotEmpty;
    
    // If we have it in memory and not forcing refresh, skip entirely
    if (!forceRefresh && hasDataMemory) return;

    // Silent mode: No loading state changes, just fetch and update
    if (silent || (!forceRefresh && hasCache)) {
       final groups = await _service.getGroupsByCategoryId(categoryId, forceRefresh: forceRefresh);
       if (groups.isNotEmpty) {
         _categoryGroups[categoryId] = groups;
         _categoryLoading[categoryId] = false;
       }
       return;
    }

    // Standard Loading Flow
    if (_categoryLoading[categoryId] == true) return;

    try {
      _categoryLoading[categoryId] = true;
      final groups = await _service.getGroupsByCategoryId(categoryId, forceRefresh: forceRefresh);
      _categoryGroups[categoryId] = groups;
    } catch (e) {
      print("❌ Error fetching groups for $categoryId: $e");
    } finally {
      _categoryLoading[categoryId] = false;
    }
  }

  void _precacheCategoryBanners(CategoryModel category) {
    if (Get.context == null) return;
    
    if (category.upperBanner?.isNotEmpty == true) {
      precacheImage(CachedNetworkImageProvider(getResizedImageUrl(category.upperBanner!, 600)), Get.context!);
    }
    if (category.lowerBanner?.isNotEmpty == true) {
      precacheImage(CachedNetworkImageProvider(getResizedImageUrl(category.lowerBanner!, 600)), Get.context!);
    }
  }

  /// ✅ Keep for compatibility
  Future<void> fetchHomeLayout({bool forceRefresh = false}) async {
    await fetchAppCategories(forceRefresh: forceRefresh);
  }

  void clearAllGroups() {
    _categoryGroups.clear();
    _categoryLoading.clear();
  }

  Future<void> refreshAllData() async {
    await fetchAppCategories(forceRefresh: true);
  }
}
