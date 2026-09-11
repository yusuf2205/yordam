import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for Yordam reminders (Phase 4, section
/// 15 of yordam.md). Local notifications only for now — no push/FCM. Exact
/// alarms survive a reboot via ScheduledNotificationBootReceiver (see
/// AndroidManifest.xml) — Android itself re-delivers them once the app has
/// been opened again after boot to re-arm AlarmManager, which is how the
/// plugin's boot receiver works.
///
/// Same fixed-timezone simplification as the backend (see AiService):
/// everyone is Asia/Tashkent until real per-user timezone exists.
class NotificationService {
  static const String _timezoneName = 'Asia/Tashkent';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_timezoneName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    // Auto-granted at install on Android 12-12L; only Android 13+ shows the
    // user a toggle for this. Requesting it is a no-op on the versions
    // where it's already granted.
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// Deterministic int id for flutter_local_notifications (it requires a
  /// 32-bit int, reminders use uuid strings) — same reminder id always maps
  /// to the same notification id, so re-scheduling replaces rather than
  /// duplicates it.
  int _notificationIdFor(String reminderId) => reminderId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime remindAt,
  }) async {
    if (!_initialized) await init();
    if (remindAt.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(remindAt, tz.local);
    await _plugin.zonedSchedule(
      id: _notificationIdFor(reminderId),
      title: 'Yordam напоминает',
      body: title,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'yordam_reminders',
          'Напоминания',
          channelDescription: 'Напоминания Yordam о делах и встречах',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(id: _notificationIdFor(reminderId));
  }
}
