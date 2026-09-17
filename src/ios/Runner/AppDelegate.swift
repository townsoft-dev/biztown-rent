import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // NGUYÊN NHÂN GỐC của việc push iOS không bao giờ lấy được token
    // (17/09/2026): app chưa bao giờ ĐĂNG KÝ với Apple, nên Apple chẳng có lý
    // do gì để cấp APNs token — không phải Apple từ chối.
    //
    // Bình thường plugin `firebase_messaging` tự gọi hàm này trong hook
    // `didFinishLaunchingWithOptions` của chính nó. Nhưng bản Flutter này
    // (3.47) dùng mẫu AppDelegate mới: plugin được đăng ký trong
    // `didInitializeImplicitFlutterEngine` — CHẠY SAU
    // `didFinishLaunchingWithOptions` — nên hook đó của plugin không bao giờ
    // được gọi, và lời gọi đăng ký APNs biến mất không dấu vết.
    //
    // Đã từng có 2 override callback APNs ở đây để lấy nguyên văn lỗi Apple —
    // chính chúng khoanh ra được lỗi này (cả hai im lặng = chưa từng gọi đăng
    // ký). Gỡ đi sau khi vá xong; cách dựng lại ghi ở docs/DECISIONS.md Đợt 56.
    //
    // Gọi tay ở đây là đúng chuẩn Apple và KHÔNG cần quyền thông báo: đăng ký
    // nhận remote notification và xin quyền hiển thị là hai việc tách rời —
    // Apple vẫn cấp device token dù người dùng chưa bấm Allow, quyền chỉ quyết
    // định có được hiện banner hay không.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
