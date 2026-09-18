import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_notification_service.dart';

class ScheduleStorageService {
  static const String _prefKey = 'saved_user_schedules_v4';
  static List<Map<String, dynamic>>? _cachedSchedules;

  /// Default baseline sample schedules
  static List<Map<String, dynamic>> _getDefaultSchedules() {
    final now = DateTime.now();
    return [
      {
        'id': 'default_1',
        'title': '전공 세미나 발표',
        'category': '발표',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오전 9:00',
        'isCompleted': true,
        'routineName': '4-7-8 호흡',
        'durationString': '05:04',
        'cycleCount': 16,
        'bgImagePath': 'assets/images/bg_breath_478.png',
        'aiHeadline': '전공 세미나 발표 전, 5분간의 4-7-8 호흡으로 완벽한 마인드셋을 갖췄어요',
        'aiQuote': '"깊은 숨을 내쉴 때마다 마음에 쌓인 부담은 아득히 멀어집니다."',
        'aiFeedbackText': '4-7-8 호흡은 날숨을 길게 유지하여 부교감신경을 활성화하는 데 탁월한 리듬이에요. 발표 전 복잡했던 머릿속을 차분하게 가라앉히고 긴장감을 진정시켰습니다.',
        'isAdaptiveRamp': true,
      },
      {
        'id': 'default_2',
        'title': '졸업논문 심사',
        'category': '시험',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오전 10:00',
        'isCompleted': true,
        'routineName': '생리학적 한숨',
        'durationString': '03:15',
        'cycleCount': 20,
        'bgImagePath': 'assets/images/bg_breath_sigh.png',
        'aiHeadline': '졸업논문 심사 전, 생리학적 한숨으로 긴장을 완화했어요',
        'aiQuote': '"두 번의 짧은 들이쉼과 긴 내쉼으로, 마음에 신선한 여유가 차오릅니다."',
        'aiFeedbackText': '생리학적 한숨은 폐포를 활짝 열어 뇌에 즉각적인 산소를 공급하고 급격한 자율신경계 긴장을 수 초 내에 가라앉히는 가장 빠른 리셋 호흡입니다.',
        'isAdaptiveRamp': true,
      },
      {
        'id': 'default_3',
        'title': '프로젝트 회의 일정',
        'category': '발표',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오후 2:30',
        'isCompleted': false,
      },
      {
        'id': 'default_4',
        'title': '중앙해커톤 본선 피칭',
        'category': '발표',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오후 6:30',
        'isCompleted': false,
      },
    ];
  }

  /// Parse time string (e.g. '오전 9:00', '오전 11:30', '오후 2:30') into minutes from midnight (0~1439)
  static int parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return 9999;
    final str = timeStr.trim();
    bool isPM = str.contains('오후') || str.toUpperCase().contains('PM');
    bool isAM = str.contains('오전') || str.toUpperCase().contains('AM');

    final parts = str.replaceAll(RegExp(r'[^\d:]'), '').split(':');
    if (parts.isEmpty || parts[0].isEmpty) return 9999;

    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (isPM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }

  /// Sorts schedules list chronologically by date and time (AM -> PM)
  static void sortSchedules(List<Map<String, dynamic>> schedules) {
    schedules.sort((a, b) {
      final dateA = a['date'];
      final dateB = b['date'];

      DateTime? dtA = dateA is DateTime ? dateA : (dateA is String ? DateTime.tryParse(dateA) : null);
      DateTime? dtB = dateB is DateTime ? dateB : (dateB is String ? DateTime.tryParse(dateB) : null);

      if (dtA != null && dtB != null) {
        final dateOnlyA = DateTime(dtA.year, dtA.month, dtA.day);
        final dateOnlyB = DateTime(dtB.year, dtB.month, dtB.day);
        final dateComp = dateOnlyA.compareTo(dateOnlyB);
        if (dateComp != 0) return dateComp;
      }

      final timeA = parseTimeToMinutes(a['time'] as String?);
      final timeB = parseTimeToMinutes(b['time'] as String?);
      return timeA.compareTo(timeB);
    });
  }

  /// Load all schedules from SharedPreferences
  static Future<List<Map<String, dynamic>>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonListStr = prefs.getString(_prefKey);

    if (jsonListStr == null || jsonListStr.isEmpty) {
      _cachedSchedules = _getDefaultSchedules();
      await _saveToPrefs();
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(jsonListStr);
        _cachedSchedules = decoded.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          if (map['date'] is String) {
            try {
              map['date'] = DateTime.parse(map['date'] as String);
            } catch (_) {}
          }
          return map;
        }).toList();
      } catch (_) {
        _cachedSchedules = _getDefaultSchedules();
        await _saveToPrefs();
      }
    }

    sortSchedules(_cachedSchedules!);
    return List<Map<String, dynamic>>.from(_cachedSchedules!);
  }

  /// Add a new schedule
  static Future<void> addSchedule(Map<String, dynamic> schedule) async {
    final current = await loadSchedules();
    final newSchedule = Map<String, dynamic>.from(schedule);

    if (newSchedule['id'] == null) {
      newSchedule['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    newSchedule['isCompleted'] = false; // Always false when newly created!

    current.add(newSchedule);
    sortSchedules(current);
    _cachedSchedules = current;
    await _saveToPrefs();
    _scheduleReminderIfValid(newSchedule);
  }

  /// Complete a schedule by title or ID (when breathing ritual is completed via schedule flow)
  static Future<void> completeSchedule(
    String? titleOrId, {
    String? routineName,
    String? durationString,
    int? cycleCount,
    String? bgImagePath,
    String? aiHeadline,
    String? aiQuote,
    String? aiFeedbackText,
  }) async {
    if (titleOrId == null || titleOrId.trim().isEmpty) return;

    final current = await loadSchedules();
    bool updated = false;
    for (var s in current) {
      if (s['id'] == titleOrId || s['title'] == titleOrId) {
        s['isCompleted'] = true;
        if (routineName != null) s['routineName'] = routineName;
        if (durationString != null) s['durationString'] = durationString;
        if (cycleCount != null) s['cycleCount'] = cycleCount;
        if (bgImagePath != null) s['bgImagePath'] = bgImagePath;
        if (aiHeadline != null) s['aiHeadline'] = aiHeadline;
        if (aiQuote != null) s['aiQuote'] = aiQuote;
        if (aiFeedbackText != null) s['aiFeedbackText'] = aiFeedbackText;
        updated = true;
      }
    }

    if (updated) {
      _cachedSchedules = current;
      await _saveToPrefs();
    }
  }

  /// Update an existing schedule
  static Future<void> updateSchedule(String id, Map<String, dynamic> updated) async {
    final current = await loadSchedules();
    for (int i = 0; i < current.length; i++) {
      if (current[i]['id'] == id || current[i]['title'] == updated['title']) {
        final map = Map<String, dynamic>.from(updated);
        current[i] = map;
        _scheduleReminderIfValid(map);
        break;
      }
    }
    sortSchedules(current);
    _cachedSchedules = current;
    await _saveToPrefs();
  }

  /// Delete schedule
  static Future<void> deleteSchedule(String id) async {
    final current = await loadSchedules();
    current.removeWhere((s) => s['id'] == id || s['title'] == id);
    _cachedSchedules = current;
    await _saveToPrefs();
    LocalNotificationService.instance.cancelReminder(id);
  }

  static void _scheduleReminderIfValid(Map<String, dynamic> s) {
    try {
      final id = s['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final title = s['title'] as String? ?? '일정';
      final dateRaw = s['date'];
      final timeStr = s['time'] as String? ?? '오후 2:30';

      DateTime? date;
      if (dateRaw is DateTime) {
        date = dateRaw;
      } else if (dateRaw is String) {
        date = DateTime.tryParse(dateRaw);
      }

      if (date != null) {
        LocalNotificationService.instance.schedule30MinReminder(
          id: id,
          title: title,
          scheduleDate: date,
          timeStr: timeStr,
        );
      }
    } catch (_) {}
  }

  static Future<void> _saveToPrefs() async {
    if (_cachedSchedules == null) return;
    final prefs = await SharedPreferences.getInstance();
    final serializable = _cachedSchedules!.map((s) {
      final copy = Map<String, dynamic>.from(s);
      if (copy['date'] is DateTime) {
        copy['date'] = (copy['date'] as DateTime).toIso8601String();
      }
      return copy;
    }).toList();

    await prefs.setString(_prefKey, jsonEncode(serializable));
  }
}
