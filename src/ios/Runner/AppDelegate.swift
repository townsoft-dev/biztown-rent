import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Khoá lưu kết quả đăng ký APNs. Tiền tố `flutter.` là bắt buộc để gói
  /// `shared_preferences` bên Dart đọc được cùng giá trị (nó tự thêm tiền tố
  /// này cho mọi khoá).
  private static let apnsStatusKey = "flutter.push.apnsNativeStatus"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - Chẩn đoán APNs
  //
  // Ghi lại kết quả đăng ký APNs để Dart đọc và hiện ở cuối tab Hồ sơ.
  //
  // Lý do phải làm vòng này (17/09/2026): trên iPhone thật, app báo "chưa lấy
  // được mã APNs của Apple" nhưng Dart KHÔNG có cách nào biết vì sao — Apple
  // trả lỗi qua callback của UIApplicationDelegate, không đi qua Firebase. Mà
  // log của máy thì không đọc được: bản TestFlight không có console, và macOS
  // đời mới đã bỏ `log stream --device-udid`. Không có 2 hàm dưới đây thì chỉ
  // còn nước đoán mò.
  //
  // Cả 2 đều gọi `super` để KHÔNG chắn đường Firebase — Firebase nhận APNs
  // token bằng cách swizzle đúng 2 hàm này; nuốt mất là hỏng hẳn push.

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    UserDefaults.standard.set("ok", forKey: AppDelegate.apnsStatusKey)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let nsError = error as NSError
    UserDefaults.standard.set(
      "\(nsError.domain) \(nsError.code): \(nsError.localizedDescription)",
      forKey: AppDelegate.apnsStatusKey)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
