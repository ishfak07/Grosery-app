import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firestore_service.dart';

void main() {
  test('new customers do not receive notifications from before registration',
      () {
    final registeredAt = DateTime.utc(2026, 6, 8, 10);
    final notifications = [
      _notification(
          'old-broadcast', registeredAt.subtract(const Duration(seconds: 1))),
      _notification('at-registration', registeredAt),
      _notification(
          'new-broadcast', registeredAt.add(const Duration(seconds: 1))),
    ];

    final visible = FirestoreService.notificationsCreatedOnOrAfter(
      notifications,
      registeredAt,
    );

    expect(
      visible.map((notification) => notification.notificationId),
      ['at-registration', 'new-broadcast'],
    );
  });
}

AppNotification _notification(String id, DateTime createdAt) {
  return AppNotification(
    notificationId: id,
    userId: '',
    recipientRole: 'broadcast',
    title: 'Title',
    body: 'Body',
    type: 'broadcast',
    relatedId: '',
    isRead: false,
    createdAt: createdAt,
  );
}
