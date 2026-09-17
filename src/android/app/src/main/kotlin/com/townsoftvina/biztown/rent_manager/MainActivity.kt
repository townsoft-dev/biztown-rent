package com.townsoftvina.biztown.rent_manager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDefaultNotificationChannel()
    }

    /**
     * Tạo kênh thông báo mặc định khớp đúng id khai trong AndroidManifest
     * (`com.google.firebase.messaging.default_notification_channel_id`).
     *
     * Từ Android 8 trở lên, thông báo KHÔNG có kênh sẽ không hiện. FCM có tự chế
     * một kênh dự phòng nếu thiếu, nhưng kênh đó không có tên tiếng Việt tử tế
     * trong phần Cài đặt của máy và độ ưu tiên/âm báo mỗi hãng một kiểu — test
     * push thật 17/09/2026 thấy log cảnh báo đúng chỗ này. Tạo tay ở đây để
     * kiểm soát được cả 3 thứ: id, tên hiện trong Cài đặt, và mức ưu tiên.
     *
     * Gọi lại nhiều lần vô hại: cùng id thì Android cập nhật chứ không nhân bản.
     */
    private fun createDefaultNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "biztown_default",
            "Thông báo BizTown",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Hoá đơn, nhắc thanh toán và cập nhật về nhà cho thuê."
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)
    }
}
