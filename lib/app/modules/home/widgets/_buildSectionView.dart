import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/category_controller.dart';
import 'package:mobiking/app/controllers/home_controller.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/modules/Product_page/product_page.dart';
import 'package:mobiking/app/modules/home/widgets/HomeCategoriesSection.dart';
import 'package:mobiking/app/modules/home/widgets/sub_category_screen.dart';
import 'package:mobiking/app/widgets/group_grid_section.dart';
import '../../../controllers/product_controller.dart';
import '../../../data/group_model.dart';
import '../../../data/product_model.dart';
import '../../../data/sub_category_model.dart';
import '../../../themes/app_theme.dart';
import '../../../utils/image_utils.dart';
import '../../../widgets/buildProductList.dart';
import '../loading/ShimmerBanner.dart';
import '../loading/ShimmerGroupSection.dart';
import '../loading/ShimmerProductGrid.dart';
import 'AllProductGridCard.dart';

class ProductGridViewSection extends StatefulWidget {
  final String bannerImageUrl;
  final List<SubCategory> subCategories;
  final List<SubCategory>? categoryGridItems;
  final List<GroupModel> groups;
  final int index;
  final ProductController productController;
  final String? categoryId;
  final bool isLoading; // 🚀 New: Category-level loading

  const ProductGridViewSection({
    super.key,
    required this.bannerImageUrl,
    required this.subCategories,
    this.categoryGridItems,
    required this.groups,
    required this.index,
    required this.productController,
    this.categoryId,
    this.isLoading = false, // 🚀 Default to false
  });

  @override
  State<ProductGridViewSection> createState() => _ProductGridViewSectionState();
}

class _ProductGridViewSectionState extends State<ProductGridViewSection> with AutomaticKeepAliveClientMixin {
  bool _isLoadingTriggered = false;
  double _lastScrollPosition = 0.0;
  bool _isScrollingUp = false;

  @override
  bool get wantKeepAlive => true; // 🚀 Keep this section's state (scroll, widgets) alive

  @override
  void initState() {
    super.initState();
    // ✅ No local ScrollController needed for NestedScrollView coordination
  }

  @override
  void dispose() {
    super.dispose();
  }

  // _onScroll removed as coordination is handled by NestedScrollView

  void _triggerLoadMore() {
    // ✅ Enhanced conditions for better UX
    if (_isLoadingTriggered ||
        widget.productController.isFetchingMore.value ||
        !widget.productController.hasMoreProducts.value) {
      return;
    }

    _isLoadingTriggered = true;
    // Removed print

    // ✅ Add a small delay to ensure smooth UX
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.productController.fetchMoreProducts();
    });
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutralBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Container(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Products Available',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All products are currently out of stock.\nCheck back later for new arrivals!',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialLoadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const ShimmerBanner(
            width: double.infinity,
            height: 160,
            borderRadius: 12,
          ),
          const SizedBox(height: 8),
          const ShimmerGroupSection(),
          const ShimmerProductGrid(),
        ],
      ),
    );
  }

  List<ProductModel> _getOptimizedInStockProducts(List<ProductModel> products) {
    return products.where((product) {
      if (product.active == false) return false;
      // Fast check - return early if any variant has stock
      for (final variant in product.variants.entries) {
        if (variant.value > 0) return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🚀 Required for AutomaticKeepAlive
    final TextTheme textTheme = Theme.of(context).textTheme;

    // 🚀 NEW: Improved loading state handling to prevent white flashes
    if (widget.isLoading && widget.groups.isEmpty) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            if (widget.bannerImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: getResizedImageUrl(widget.bannerImageUrl, 600),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              const ShimmerBanner(
                width: double.infinity,
                height: 160,
                borderRadius: 12,
              ),
            const SizedBox(height: 8),
            const ShimmerGroupSection(),
            const ShimmerProductGrid(),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          final ScrollMetrics metrics = notification.metrics;
          final double scrollPercentage =
              metrics.pixels / metrics.maxScrollExtent;

          // ✅ Detect direction from delta
          _isScrollingUp = notification.scrollDelta! > 0;

          // ✅ Trigger at 50% with smooth detection
          if (scrollPercentage >= 0.5 &&
              _isScrollingUp &&
              !_isLoadingTriggered &&
              widget.productController.hasMoreProducts.value &&
              !widget.productController.isFetchingMore.value) {
            _triggerLoadMore();
          }
        }
        return false;
      },
      child: CustomScrollView(
        key: PageStorageKey<String>('tab_scroll_view_${widget.index}'),
        // controller: _scrollController, // ✅ Removed to sync with outer NestedScrollView
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Banner Section
          if (widget.bannerImageUrl.isNotEmpty)
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: getResizedImageUrl(widget.bannerImageUrl, 600),
                    fit: BoxFit.cover,
                    // Use a very fast fade for a more professional feel
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.neutralBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: ShimmerBanner(
                          width: double.infinity,
                          height: 160,
                          borderRadius: 12,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.neutralBackground,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppColors.textLight,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Group Sections (if available)
          if (widget.groups.isNotEmpty)
            SliverToBoxAdapter(
              child: GroupWithProductsSection(groups: widget.groups),
            ),

          // ✅ Integrated Products Grid Section
          Obx(() {
            final products = widget.productController.allProducts;
            final isLoading = widget.productController.isLoading.value;
            final isLoadingMore =
                widget.productController.isFetchingMore.value;
            final hasMoreProducts =
                widget.productController.hasMoreProducts.value;

            if (isLoading && products.isEmpty) {
              return SliverToBoxAdapter(child: _buildInitialLoadingState());
            } else if (products.isEmpty && !isLoading) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'We couldn\'t find any items at the moment.\n'
                    'Please check back later.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              // Filter in-stock products
              final inStockProducts = _getOptimizedInStockProducts(products);

              if (inStockProducts.isEmpty && !isLoadingMore) {
                return SliverToBoxAdapter(child: _buildEmptyState(context, textTheme));
              }

              return SliverMainAxisGroup(
                slivers: [
                  // Title Section with scroll progress indicator
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Row(
                        children: [
                          Text(
                            "All Products",
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${inStockProducts.length}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),

                  // ✅ Products Grid optimized with RepaintBoundary and better builder settings
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 0,
                            crossAxisSpacing: 0,
                            childAspectRatio: 0.5,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Show loading shimmer
                          if (index >= inStockProducts.length) {
                            return _buildShimmerCard();
                          }

                          final product = inStockProducts[index];
                          return GestureDetector(
                            onTap: () => Get.to(
                              ProductPage(
                                product: product,
                                heroTag: 'product_${product.id}_$index',
                              ),
                            ),
                            child: AllProductGridCard(
                              product: product,
                              heroTag: 'product_${product.id}_$index',
                            ),
                          );
                        },
                        childCount:
                            inStockProducts.length + (isLoadingMore ? 3 : 0),
                      ),
                    ),
                  ),

                  // ✅ Enhanced Loading Indicator with animation
                  if (isLoadingMore)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primaryPurple,
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Loading more products...',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ✅ Enhanced End Message
                  if (!hasMoreProducts && inStockProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppColors.primaryPurple,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '✨ You\'ve seen all products!',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 40), // Extra space for better scroll feels
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }
          }),
        ],
      ),
    );
  }
}

Widget buildSectionView({
  Key? key,
  required String bannerImageUrl,
  required List<SubCategory> subCategories,
  required List<SubCategory>? categoryGridItems,
  required List<GroupModel> groups,
  required int index,
  required ProductController productController,
  String? categoryId,
  bool isLoading = false, // 🚀 New: Receive loading status
}) {
  return ProductGridViewSection(
    key: key,
    bannerImageUrl: bannerImageUrl,
    subCategories: subCategories,
    categoryGridItems: categoryGridItems,
    groups: groups,
    index: index,
    productController: productController,
    categoryId: categoryId,
    isLoading: isLoading, // 🚀 Pass it through
  );
}
