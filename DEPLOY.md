# English Core TaP — دليل النشر (Deployment Guide)

النظام الحالي يعمل بالكامل على **GitHub Pages + Firebase Auth** (مجاني، بدون فيزا).

| المكوّن | مزوّد | الوظيفة |
|---|---|---|
| الموقع (الواجهة) | GitHub Pages | يعرض التطبيق للطلاب |
| اللوجن واليوزرز | Firebase Auth | دخول الطلاب (100+ حساب) |
| الكود | GitHub (public) | `ahmedabdelsalam07/english-core-tap` |

---

## الرابط النهائي

```
https://ahmedabdelsalam07.github.io/english-core-tap/
```

## كيف يتحدّث الموقع عند أي تعديل؟

- أي `git push` إلى فرع `main` يبني الموقع تلقائيًا وينشره (ملف `.github/workflows/deploy-web.yml`).

## إضافة/تغيير/حذف طلاب

البيانات على Firebase (وليست في الكود). يوجد سكربت إنشاء:
```powershell
.\create_firebase_users.ps1 -ApiKey "AIzaSyCXNjgt9sKFfINHawhrqDyCEQF3uAGxyLE"
```
- الملفات `firebase_users.csv` / `مستخدمين_الطلاب.csv` مستثناة من الرفع (لا تُحمَّل على GitHub).

## إعدادات مهمة في Firebase
- **Authentication → Sign-in method**: Email/Password مُفعّل.
- **Authentication → Settings → Authorized domains**: أضِف `ahmedabdelsalam07.github.io`.

## بنية اللوجن
- الطالب يدخل **اسم مستخدم** (مثل `student1`) ويُحوَّل تلقائيًا إلى إيميل `student1@englishcore.app` في `lib/data/services/backend_client.dart`.
- لا توجد أي كلمة سر في كود الموقع — كل الفحص على Firebase.

## التشغيل محليًا
```
flutter run -d chrome
```
أو دبل كليك على `شغّل-التطبيق.bat`.

## ملاحظات
- الإصدار الأصلي القديم (سيرفر Node على Render) لم يعد مستخدمًا؛ `server/` محفوظ كمرجع فقط.
- بناء Android/iOS يتطلب لاحقًا `flutterfire configure` لربط Firebase بالأجهزة.