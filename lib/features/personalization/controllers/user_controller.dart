import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:med/data/repositories/user/user_repository.dart';
import 'package:med/features/personalization/models/user_model.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final Rx<UserModel> user = UserModel.empty().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserRecord();
  }

  Future<void> fetchUserRecord() async {
    try {
      isLoading.value = true;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final fetched = await UserRepository.instance.fetchUserDetails();
      user.value = fetched;
    } catch (e) {
      user.value = UserModel.empty();
    } finally {
      isLoading.value = false;
    }
  }

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
}
