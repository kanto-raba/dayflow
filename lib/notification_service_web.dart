import 'dart:html' as html;

Future<bool> requestNotificationPermission() async {
  if (!notificationsSupported) return false;
  if (html.Notification.permission == 'granted') return true;
  final permission = await html.Notification.requestPermission();
  return permission == 'granted';
}

bool get notificationsSupported => html.Notification.supported;

void showNotification(String title, String body) {
  if (notificationsSupported && html.Notification.permission == 'granted') {
    html.Notification(title, body: body);
  }
}
