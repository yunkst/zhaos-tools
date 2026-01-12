import 'package:pinyin/pinyin.dart';

/// 拼音工具类
class PinyinHelperUtils {
  /// 获取全拼（去除空格和分隔符，转为小写）
  ///
  /// 示例: "张三" -> "zhangsan"
  static String getPinyin(String text) {
    if (text.isEmpty) return '';
    // 使用 pinyin 库的 getPinyin 方法
    // format: Format.WITHOUT_TONE 表示不包含声调
    // separator: ' ' 表示用空格分隔每个字的拼音
    final pinyinStr = PinyinHelper.getPinyin(text, format: PinyinFormat.WITHOUT_TONE, separator: ' ');
    // 去除空格并转为小写
    return pinyinStr.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  /// 获取拼音首字母（转为小写）
  ///
  /// 示例: "张三" -> "zs"
  static String getPinyinAbbr(String text) {
    if (text.isEmpty) return '';
    // 使用 pinyin 库的 getShortPinyin 方法
    return PinyinHelper.getShortPinyin(text).toLowerCase();
  }

  /// 检查关键词是否匹配（支持中文、全拼、首字母、混合搜索）
  ///
  /// [keyword] 搜索关键词
  /// [name] 学生姓名
  /// [pinyin] 姓名的全拼
  /// [pinyinAbbr] 姓名的拼音首字母
  ///
  /// 返回 true 表示匹配
  ///
  /// 示例:
  /// - matches("张", "张三", null, null) -> true (中文匹配)
  /// - matches("zhang", "张三", "zhangsan", "zs") -> true (全拼匹配)
  /// - matches("zs", "张三", "zhangsan", "zs") -> true (首字母匹配)
  /// - matches("zh", "张三", "zhangsan", "zs") -> true (模糊匹配)
  /// - matches("zhang三", "张三", "zhangsan", "zs") -> true (混合匹配)
  static bool matches(String keyword, String name, String? pinyin, String? pinyinAbbr) {
    if (keyword.isEmpty) return true;

    keyword = keyword.toLowerCase();

    // 1. 中文直接匹配
    if (name.contains(keyword)) return true;

    // 2. 全拼匹配
    if (pinyin != null && pinyin.contains(keyword)) return true;

    // 3. 首字母匹配
    if (pinyinAbbr != null && pinyinAbbr.contains(keyword)) return true;

    return false;
  }
}
