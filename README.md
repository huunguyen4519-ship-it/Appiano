# Appiano

Ứng dụng luyện piano. Hiện tại là bản demo bàn phím ảo 2 quãng tám, chạy trên Android.

## Cách tạo và build APK

Repo này chỉ chứa phần `pubspec.yaml`, `lib/`, `assets/`. Cần tạo khung Android bằng Flutter trước:

```bash
flutter create --platforms=android --org com.example appiano_tmp
# Copy thư mục android/ từ appiano_tmp vào repo này, rồi xóa appiano_tmp
mv appiano_tmp/android ./android
rm -rf appiano_tmp

flutter pub get
flutter run                       # chạy thử trên máy đang cắm
flutter build apk --release       # tạo APK
```

File APK nằm ở `build/app/outputs/flutter-apk/app-release.apk`. Chép file này sang điện thoại và cài đặt (cần bật "Cài đặt ứng dụng không rõ nguồn gốc").

## Ghi chú

- Âm thanh `assets/piano_c4.wav` là file tổng hợp đơn giản (sinh bằng script), chỉ để demo. Khi làm thật, thay bằng mẫu piano thu thật (ví dụ bộ Salamander Grand Piano, giấy phép CC-BY).
- Các nốt khác được tạo bằng cách đổi tốc độ phát của mẫu C4, nên nốt xa C4 sẽ nghe lệch.
- Thư viện `flutter_soloud` cần kiểm tra lại API trên pub.dev trước khi build, vì API thay đổi theo phiên bản.
