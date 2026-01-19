import 'package:isar/isar.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Isar isar;
  AuthRepository(this.isar);

  Future<void> registerUser(String name, String email, String password) async {
    final newUser = UserModel()
      ..name = name
      ..email = email
      ..password = password
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.userModels.put(newUser);
    });
  }
}