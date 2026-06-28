import 'package:shared_preferences/shared_preferences.dart';

class FirstHomeExperience {
  const FirstHomeExperience();

  static const requiredDisplays = 2;

  Future<int?> pendingDisplayCount(String authUserId) async {
    if (authUserId.isEmpty) return null;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool('new_account_$authUserId') != true) return null;
    final count = preferences.getInt('people_prompt_count_$authUserId') ?? 0;
    return count >= requiredDisplays ? null : requiredDisplays - count;
  }

  Future<void> recordDisplay(String authUserId) async {
    final preferences = await SharedPreferences.getInstance();
    final key = 'people_prompt_count_$authUserId';
    final count = (preferences.getInt(key) ?? 0) + 1;
    await preferences.setInt(key, count);
    if (count >= requiredDisplays) {
      await preferences.remove('new_account_$authUserId');
    }
  }
}
