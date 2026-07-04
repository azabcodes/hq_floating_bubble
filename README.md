# HQ Floating Bubble

A premium, highly customizable, and fully featured Flutter plugin for creating system-level floating overlay windows (bubbles) on Android.

---

### [📄 على العربية (Arabic Version)](#arabic-version)

---

## 🌟 Key Features

- **System-Level Floating Windows**: Create system-level overlays that float over other applications.
- **Magnet Snapping (Horizontal)**: Automatically and smoothly slides the bubble to the nearest horizontal edge (left or right) when dragging ends.
- **Screen Boundary Constraints**: Restricts overlay movement to prevent dragging it off the visible screen area.
- **Micro-Animations**: Smooth Scale & Fade transitions when showing or hiding the overlay.
- **Reactive Stream Event System**: Real-time event broadcasting globally via `HQFloatingService().onEvent` or window-specific via `window.onEvent`.
- **Foreground Service Control**: Custom Foreground Notifications (custom title, description, subText, ticker, and mipmap/drawable icon resource resolution).
- **CPU WakeLock Management**: Dynamically enable or disable WakeLocks to prevent CPU sleep, with clean garbage collection on service destroy.
- **Custom Exceptions**: Structured exceptions (`HQFloatingPermissionException`, `HQFloatingWindowException`) for reliable error-handling.
- **Modular Core Structure**: Organized codebase split into enums, extensions, constants, typedefs, models, and services.

---

## 🚀 Getting Started

### 1. Add Android Configuration

Add the following permissions and service declaration inside your client app's `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Required permissions -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

<!-- Add inside the <application> tag -->
<service
    android:name="hq.floating.bubble.HQFloatingService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="specialUse">
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="Floating bubble window overlay service" />
</service>
```


### 2. Basic Setup and Initialize

```dart
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the service and sync active windows
  await HQFloatingService().initialize();

  runApp(const MyApp());
}
```

### 3. Create and Show Floating Window

```dart
// Check and request overlay permission
bool hasPermission = await HQFloatingService().checkPermission();
if (!hasPermission) {
  await HQFloatingService().openPermissionSetting();
  return;
}

// Define window configuration
final config = HQFloatingWindowConfig(
  entry: "main",
  route: "/overlay_view",
  width: 300,
  height: 300,
  draggable: true,
  magnet: true, // Enables magnet edge snapping
);

try {
  // Create and display the window immediately
  HQFloatingWindow? window = await HQFloatingService().createWindow(
    'my_bubble_id',
    config,
    start: true,
  );
} on HQFloatingPermissionException catch (e) {
  print("Permission missing: $e");
} catch (e) {
  print("Failed to create bubble: $e");
}
```

---

## ⚡ Advanced Configurations

### Stream Event Broadcasting

Listen to events in real time anywhere in your app:

```dart
// Globally listen to all window events
HQFloatingService().onEvent.listen((event) {
  print("Global Event: ${event.name} for Window: ${event.id} with data: ${event.data}");
});

// Or listen to events of a specific window
myWindow.onEvent.listen((event) {
  if (event.name == 'window.drag_end') {
    print("Window snapped to: ${event.data}");
  }
});
```

### Foreground Service & Notification Customization

Promote your service to the foreground with a customized notification layout and custom icon drawable resource:

```dart
await HQFloatingService().promoteService(
  title: "Active Chat Bubble",
  description: "Chat overlay is currently active",
  icon: "ic_custom_bubble_notification", // resolved from drawables/mipmaps
  showWhen: true,
  subText: "Running",
);
```

### Battery and CPU WakeLock

Ensure your bubble updates smoothly in the background by managing CPU WakeLocks:

```dart
// Keep CPU awake
await HQFloatingService().setWakeLock(true);

// Release WakeLock to save battery
await HQFloatingService().setWakeLock(false);
```

---

<br/>
<br/>

---

<a id="arabic-version"></a>

# HQ Floating Bubble (النسخة العربية)

مكتبة فلاتر (Flutter Plugin) احترافية وعالية الأداء لإنشاء وإدارة النوافذ العائمة (الفقاعات) على مستوى نظام أندرويد مع ميزات حركة متقدمة وتخصيص كامل.

---

### [📄 Back to English Version](#hq-floating-bubble)

---

## 🌟 الميزات الرئيسية

- **نوافذ عائمة على مستوى النظام**: إنشاء نوافذ تطفو فوق التطبيقات الأخرى وتعمل في الخلفية.
- **الانجذاب المغناطيسي (Magnet Snapping)**: انزلاق انسيابي ناعم ومتحرك للفقاعة لتلتصق تلقائياً بأقرب حافة أفقية للشاشة (يمين أو يسار) عند إفلاتها.
- **حماية حدود الشاشة**: حظر حركة النافذة لمنع سحبها بالكامل خارج حدود الشاشة المرئية.
- **حركات الدخول والخروج التعبيرية (Scale & Fade)**: تأثير زوم وتلاشي ناعم وجميل عند إظهار وإخفاء النافذة.
- **نظام أحداث تفاعلي تفصيلي (Streams)**: بث الأحداث لحظياً على مستوى التطبيق عبر `HQFloatingService().onEvent` أو للنافذة نفسها عبر `window.onEvent`.
- **تخصيص إشعارات أندرويد**: تحكم كامل بنصوص وأيقونة إشعار الـ Foreground Service من فلاتر (العنوان، الوصف، الأيقونة المخصصة من drawable/mipmap).
- **إدارة قفل المعالج (WakeLock)**: تفعيل وإلغاء تفعيل قفل المعالج ديناميكياً للحفاظ على نشاط الخلفية أو توفير طاقة البطارية.
- **معالجة منظمة للاستثناءات**: استثناءات مخصصة (`HQFloatingPermissionException`, `HQFloatingWindowException`) لتسهيل كشف ومعالجة الأخطاء.
- **هيكلية برمجية منظمة**: تنظيم كود الـ Core وتقسيمه إلى مجلدات فرعية للموديلات، الأحداث، الإعدادات، والخدمات.

---

## 🚀 بدء الاستخدام

### 1. إعدادات الأندرويد (AndroidManifest.xml)

أضف الصلاحيات وتعريف الخدمة التالية داخل ملف `AndroidManifest.xml` الخاص بتطبيقك:

<div dir="ltr">

```xml
<!-- Required permissions -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

<!-- Add inside the <application> tag -->
<service
    android:name="hq.floating.bubble.HQFloatingService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="specialUse">
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="Floating bubble window overlay service" />
</service>
```

</div>


### 2. التثبيت والتهيئة

<div dir="ltr">

```dart
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HQFloatingService().initialize();

  runApp(const MyApp());
}
```

</div>

### 3. إنشاء وإظهار النافذة العائمة

<div dir="ltr">

```dart
bool hasPermission = await HQFloatingService().checkPermission();
if (!hasPermission) {
  await HQFloatingService().openPermissionSetting();
  return;
}

final config = HQFloatingWindowConfig(
  entry: "main",
  route: "/overlay_view",
  width: 300,
  height: 300,
  draggable: true,
  magnet: true,
);

try {
  HQFloatingWindow? window = await HQFloatingService().createWindow(
    'my_bubble_id',
    config,
    start: true,
  );
} on HQFloatingPermissionException catch (e) {
  print("Missing permission: $e");
} catch (e) {
  print("Failed to create bubble: $e");
}
```

</div>

---

## ⚡ الاستخدام المتقدم

### الاستماع للأحداث عبر الـ Streams

يمكنك الاستماع للتفاعل مع النافذة في أي مكان داخل تطبيقك:

<div dir="ltr">

```dart
HQFloatingService().onEvent.listen((event) {
  print("Event: ${event.name} on window ${event.id} with data: ${event.data}");
});

myWindow.onEvent.listen((event) {
  if (event.name == 'window.drag_end') {
    print("Snapped coordinates: ${event.data}");
  }
});
```

</div>

### تخصيص إشعارات الخلفية (Foreground Notifications)

ترقية الخدمة للعمل في الواجهة وإضافة إشعار خاص مخصص:

<div dir="ltr">

```dart
await HQFloatingService().promoteService(
  title: "Active Chat Bubble",
  description: "Chat overlay is currently active",
  icon: "ic_custom_bubble_notification",
  showWhen: true,
  subText: "Running",
);
```

</div>

### قفل معالج الهاتف (WakeLock)

لمنع الهاتف من الدخول في وضع النوم وإيقاف تحديثات الفقاعة:

<div dir="ltr">

```dart
await HQFloatingService().setWakeLock(true);

await HQFloatingService().setWakeLock(false);
```

</div>
