import Flutter
import UIKit
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase 설정
    FirebaseApp.configure()

    // Firebase Messaging 설정
    Messaging.messaging().delegate = self

    // 앱 실행 시 사용자에게 알림 허용 권한을 받는다
    UNUserNotificationCenter.current().delegate = self

    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { _, _ in }
    )

    // 원격 알림 등록
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 원격 알림 등록 실패 시
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("😭 Failed to register for remote notifications:", error)
  }

  // 앱이 포그라운드에 있을 때 푸시 알림 수신
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("😎 Received notification in foreground")

    // 푸시 알림 데이터가 userInfo에 담겨있다
    let userInfo = notification.request.content.userInfo
    print("Notification data:", userInfo)

    if #available(iOS 14.0, *) {
      completionHandler([.sound, .banner, .list])
    } else {
      completionHandler([])
    }
  }

  // 사용자가 푸시 알림을 탭할 때
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("👆 User tapped notification")

    let userInfo = response.notification.request.content.userInfo
    print("Tapped notification data:", userInfo)

    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  // FCM Token 업데이트 시
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🥳 FCM Token Updated:", fcmToken ?? "nil")
  }
}
