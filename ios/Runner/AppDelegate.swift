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

  // 앱이 포그라운드에 있을 때 푸시 알림 수신.
  //
  // 반드시 super 로 넘긴다. 여기서 completionHandler 를 직접 부르고 끝내면
  // FirebaseMessaging 이 이 알림을 보지 못해 Dart 쪽 onMessage 가 오지 않는다.
  // 배너를 띄울지 말지는 Dart 에서
  // setForegroundNotificationPresentationOptions 로 정한다.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  // 사용자가 푸시 알림을 탭할 때.
  //
  // 여기도 반드시 super 로 넘긴다. 이 화살표가 끊겨 있으면 탭이
  // FirebaseMessaging 까지 가지 못해서
  //   - 앱이 떠 있다 눌린 경우: onMessageOpenedApp 이 울리지 않고
  //   - 앱이 꺼져 있다 눌린 경우: getInitialMessage() 가 계속 nil 을 준다.
  // 즉 iOS 에서만 '알림을 눌러도 아무 데도 가지 않는' 상태가 된다.
  // (2026-08-30 실기기 검증에서 이 증상으로 발견했다)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  // FCM Token 업데이트 시
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🥳 FCM Token Updated:", fcmToken ?? "nil")
  }
}
