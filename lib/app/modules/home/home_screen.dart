import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart' show CartController;
import '../../controllers/category_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/sub_category_controller.dart';
import '../../controllers/tab_controller_getx.dart';

import '../../themes/app_theme.dart';
import '../../widgets/SearchTabSliverAppBar.dart';
import 'widgets/HomeShimmer.dart';
import 'widgets/_buildSectionView.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {

  final CategoryController categoryController = Get.find();
  final SubCategoryController subCategoryController = Get.find();
  final TabControllerGetX tabController = Get.find();
  final ProductController productController = Get.find();
  final HomeController homeController = Get.find();

  late ScrollController _scrollController;

  final RxBool _showScrollToTopButton = false.obs;

  int _lastCategoryLength = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    productController.loadProductsOnDemand();
    categoryController.fetchCategories();
    subCategoryController.loadSubCategories();
    homeController.fetchHomeLayout();

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {

    if (_scrollController.offset >= 200 && !_showScrollToTopButton.value) {
      _showScrollToTopButton.value = true;
    }
    else if (_scrollController.offset < 200 && _showScrollToTopButton.value) {
      _showScrollToTopButton.value = false;
    }

    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.75) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (productController.isFetchingMore.value ||
        !productController.hasMoreProducts.value) {
      return;
    }

    print("🚀 Infinite scroll triggered from HomeScreen");
    productController.fetchMoreProducts();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onRefresh() async {

    print("🔄 Manual refresh triggered");

    await Future.wait([
      productController.refreshProducts(),
      categoryController.refreshCategories(),
      subCategoryController.refreshSubCategories(),
      homeController.refreshAllData(),
    ]);

    print("✅ All data refreshed");
  }

  void _handleTabController(List categories) {

    if (categories.isEmpty) return;

    if (_lastCategoryLength != categories.length) {

      _lastCategoryLength = categories.length;

      WidgetsBinding.instance.addPostFrameCallback((_) {

        tabController.resetWithLength(categories.length);

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,

      body: Stack(
        children: [

          Obx(() {

            if (homeController.isLoading &&
                homeController.homeData == null) {
              return const HomeShimmer();
            }

            final categories = homeController.categories;

            _handleTabController(categories);

            return NestedScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),

              headerSliverBuilder: (context, innerBoxIsScrolled) {

                return [
                  SearchTabSliverAppBar(
                    onSearchChanged: (value) {},
                  ),
                ];
              },

              body: TabBarView(
                controller: tabController.controller,
                physics: const NeverScrollableScrollPhysics(),

                children: List.generate(categories.length, (index) {

                  final category = categories[index];

                  final categoryId = category.id;

                  final groups =
                      homeController.categoryGroups[categoryId] ?? [];

                  final isCategoryLoading =
                  homeController.isCategoryLoading(categoryId);

                  return ProductGridViewSection(
                    key: ValueKey('tab_${category.id}'),

                    productController: productController,

                    index: index,

                    groups: groups,

                    bannerImageUrl: category.lowerBanner ?? '',

                    categoryGridItems:
                    subCategoryController.subCategories,

                    subCategories:
                    subCategoryController.subCategories,

                    categoryId: categoryId,

                    isLoading: isCategoryLoading,
                  );
                }),
              ),
            );
          }),

          Positioned(
            bottom: 20,
            right: 20,

            child: Obx(() => AnimatedOpacity(

              opacity: _showScrollToTopButton.value ? 1 : 0,

              duration: const Duration(milliseconds: 300),

              child: _showScrollToTopButton.value
                  ? FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.darkPurple,
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_upward,
                    color: Colors.white),
              )
                  : const SizedBox.shrink(),
            )),
          ),
        ],
      ),
    );
  }
}