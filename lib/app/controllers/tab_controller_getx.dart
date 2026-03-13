import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabControllerGetX extends GetxController
    with GetSingleTickerProviderStateMixin {

  late TabController controller;

  final RxInt selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    controller = TabController(
      length: 3,
      vsync: this,
    );

    _attachListener();
  }

  void _attachListener() {
    controller.addListener(() {
      if (!controller.indexIsChanging &&
          controller.index < controller.length) {
        selectedIndex.value = controller.index;
      }
    });
  }

  void changeTab(int index) {
    if (index < 0 || index >= controller.length) return;

    if (controller.index != index) {
      controller.animateTo(index);
      selectedIndex.value = index;
    }
  }

  void updateIndex(int index) {
    if (index < 0 || index >= controller.length) return;

    if (selectedIndex.value == index) return;

    selectedIndex.value = index;

    if (controller.index != index) {
      controller.animateTo(index);
    }
  }

  void resetWithLength(int length) {
    if (length <= 0) return;
    if (controller.length == length) return;

    print('[TabControllerGetX] Resetting with length: $length');

    final int newIndex = selectedIndex.value.clamp(0, length - 1);

    final oldController = controller;

    controller = TabController(
      length: length,
      vsync: this,
      initialIndex: newIndex,
    );

    _attachListener();

    selectedIndex.value = newIndex;

    update();

    oldController.dispose();
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}