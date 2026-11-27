import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/todo_item.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('Timezone init warning: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Android 13+ ve iOS izinlerini iste
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  /// Yapılacaklar listesini alır; bekleyen (tamamlanmamış) ve tarihi gelmemiş/bugünkü görevler
  /// için ilgili günün saat 09:00'ına ayrı lokal bildirimler planlar.
  Future<void> syncTodoNotifications(List<TodoItem> todos) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }

    try {
      await _plugin.cancelAll();
      final now = DateTime.now();

      for (final todo in todos) {
        if (todo.isCompleted || todo.id == null) continue;

        // Hedef zaman: Belirtilen günün sabah 09:00'ı
        final targetDateTime = DateTime(
          todo.dueDate.year,
          todo.dueDate.month,
          todo.dueDate.day,
          9,
          0,
        );

        // Eğer saat 09:00 geçmişse bildirim planlama
        if (targetDateTime.isBefore(now)) continue;

        final scheduledTz = tz.TZDateTime.from(targetDateTime, tz.local);
        final notificationId = todo.id.hashCode & 0x7FFFFFFF;

        final bodyText = todo.description.isNotEmpty
            ? todo.description
            : 'Bugün yapılması planlanan görev hatırlatması.';

        await _plugin.zonedSchedule(
          notificationId,
          '📌 ${todo.title}',
          bodyText,
          scheduledTz,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'nrt_todos_channel',
              'Yapılacaklar Hatırlatıcıları',
              channelDescription: 'Planlanan işler için sabah 09:00 bildirimleri',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Bildirim senkronizasyon uyarısı: $e');
    }
  }
}
