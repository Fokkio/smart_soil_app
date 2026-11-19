# Smart Soil — Flutter UI Prototype

แอปต้นแบบ (เฟส UI) ของ **Smart Soil Quality Mapping System** — ทีม Precision Farming, MSU BCG Hackathon รุ่นที่ 4
ทำตาม `smart_soil_ui_final_revised.svg` (39 หน้า) ฟาร์ม แปลง และผลวัด **เก็บจริงในเครื่อง** (ดูหัวข้อ "ข้อมูล") หน้าอื่นยังใช้ข้อมูลตัวอย่าง ยังไม่เชื่อมฮาร์ดแวร์ / GPS / คลาวด์

## เริ่มรันครั้งแรก (Windows / PowerShell)

```powershell
cd "D:\BCG project\smart_soil_app"
flutter create --platforms=android --org th.ac.msu.precisionfarming .   # สร้างโฟลเดอร์ android/ (ไม่ทับไฟล์ใน lib/)
flutter pub get
flutter analyze
flutter test
flutter run            # เลือก emulator หรือมือถือ Android ที่เปิด USB debugging
```

> โฟลเดอร์ `android/` ยังไม่มีในโปรเจกต์ เพราะสร้างจากเครื่องมือของ Flutter บนเครื่องคุณได้ถูกต้องกว่า (ตรงกับเวอร์ชัน SDK/Gradle ที่ติดตั้ง)

## โครงสร้าง

```
lib/
  main.dart                  จุดเริ่มแอป → WelcomeScreen
  theme.dart                 สี / ตัวอักษร / ปุ่ม ตาม mockup
  data/mock_data.dart        ข้อมูลตัวอย่าง (หน้าที่ยังไม่ต่อข้อมูลจริง + seed ครั้งแรก)
  data/models.dart           FarmRecord, PlotRecord, MeasurementRound + JSON, formatWhen
  data/farm_store.dart       เก็บ snapshot ลงไฟล์ JSON (เขียนแบบ atomic, กู้คืนเมื่อไฟล์เสีย)
  data/farm_repository.dart  ค้น/เพิ่ม/แก้/ลบ ฟาร์ม แปลง ผลวัด (ChangeNotifier)
  data/app_scope.dart        AppScope.of(context) / AppScope.read(context)
  data/seed.dart             ข้อมูลตัวอย่างตอนเปิดแอปครั้งแรก
  widgets/common.dart        การ์ด, Pill, InfoBox, Segmented, ScreenScaffold ฯลฯ
  widgets/plot_map.dart      แผนที่แปลงวาดด้วย CustomPaint + กราฟแนวโน้ม
  screens/
    main_tabs.dart           AppShell (4 แท็บ + ปุ่มวัดดิน), Home, แผนที่ดิน, ผู้ช่วย AI, เพิ่มเติม
    farm_screens.dart        ฟาร์ม แปลง รายละเอียดแปลง สร้าง/แก้ไข วาดขอบเขต
    measure_screens.dart     วัดดิน: เชื่อมต่อ → พร้อม → รับข้อมูล x3 → สรุปวัดซ้ำ → ผล, ออฟไลน์, error
    data_screens.dart        จุดตรวจ, ข้อสังเกต AI, ประวัติ, เปรียบเทียบ, แจ้งเตือน, ซิงก์
    device_screens.dart      อุปกรณ์, บำรุงรักษา, ผลสอบเทียบ, กรอกค่าอ้างอิง, ส่งออกรายงาน, ตั้งค่า
    plan_screens.dart        แผนจุดวัด, เดินวัดตามแผน, ทบทวนข้อสังเกต (ผู้เชี่ยวชาญ)
    onboarding_screens.dart  Welcome, Login, เลือกบทบาท, ตั้งค่าเริ่มต้น, สิทธิ์การเข้าถึง
    state_screens.dart       Empty / Loading states
    catalog.dart             แคตตาล็อกเปิดทุกหน้าตามรหัส MAIN/FLOW/STATE/NEW (ไว้ใช้นำเสนอ)
```

ทางลัดตอนนำเสนอ: หน้า Welcome → **(Demo) ข้ามไปหน้าหลัก** → แท็บ **เพิ่มเติม** → **แคตตาล็อกหน้าจอ**

## ข้อมูล

- เก็บที่ `smart_soil.json` ในโฟลเดอร์เอกสารของแอป (Android: `/data/data/th.ac.msu.precisionfarming.smart_soil_app/app_flutter/`)
- เปิดครั้งแรกใส่ข้อมูลตัวอย่าง 3 ฟาร์ม 3 แปลง ผลวัด 14 จุด; ลบไฟล์นี้เพื่อเริ่มใหม่
- ไฟล์เสีย → แอปเก็บไว้เป็น `smart_soil.json.corrupt-<เวลา>` แล้วเริ่มด้วยข้อมูลว่าง (ไม่ crash)
- หน้าที่ใช้ข้อมูลจริงแล้ว: ฟาร์มของฉัน, แปลงในฟาร์ม, รายละเอียดแปลง (ยกเว้นแท็บแผนที่/AI), สร้าง/แก้ไขฟาร์ม, เพิ่มแปลง, วาดขอบเขต, แก้ไขแปลง
- ใช้ได้บน Android / iOS / desktop เท่านั้น (ใช้ `dart:io`) — **ยังไม่รองรับ web**

**สำหรับทีมเครื่องวัดดิน** — บันทึกผลวัดหนึ่งรอบ:

```dart
final repo = AppScope.read(context);
await repo.addRound(plotId: plot.id, points: [SoilPoint('#01', pos, status, reading, zone), ...]);
```

## หลักที่ UI ยึดตามข้อเสนอโครงการ

- ไม่ให้คำแนะนำปุ๋ย / ชนิดพืช — AI ให้เฉพาะ "ข้อสังเกต" เพื่อคัดกรอง
- N-P-K แสดงเป็น "ค่าประมาณ ยังไม่สอบเทียบ" และไม่มีสถานะ ปกติ/เฝ้าดู
- วัดซ้ำ 3 ครั้งต่อจุด, แผนจุดวัดขั้นต่ำ 20 จุด, ค่าอ้างอิง/ผลแล็บ, รายงานสอบเทียบ, ส่งออกแบบตรวจสอบย้อนกลับได้
- ข้อสังเกตต้องผ่านผู้เชี่ยวชาญก่อนส่งถึงผู้ดูแลฟาร์ม

## เฟสถัดไป (ยังไม่ทำ)

| งาน | แพ็กเกจที่แนะนำ |
|---|---|
| BLE กับตัวอ่านค่า | `flutter_blue_plus` |
| USB OTG serial (Android) | `usb_serial` |
| แผนที่จริง | `flutter_map` + `latlong2` |
| GPS | `geolocator` |
| ส่งออก PDF / CSV | `pdf`, `csv`, `share_plus` |
