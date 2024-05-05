import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  Future writeCache({required String key, required String value}) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();

    bool isSaved = await pref.setString(key, value);

  }

  Future<String?> readCache({required String key}) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? value = await pref.getString(key);
    return value;
  }

  Future removeCache() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool isCleared = await pref.clear();
    print(isCleared);
  }





}
