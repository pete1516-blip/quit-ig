# เลิก IG — แอพ iOS

แอพเช็คอินรายวันว่าวันนี้เลิก IG ได้ไหม ใช้งานออฟไลน์ มีนาฬิกาปลุกทุกเย็น (AlarmKit, iOS 26+)

## สร้างไฟล์ .ipa
ทุกครั้งที่อัปโหลดโค้ดขึ้น GitHub ระบบจะสร้างไฟล์ให้เองที่แท็บ **Actions → Build IPA → Artifacts → QuitIG-ipa**

## ติดตั้งบน iPhone จาก Windows
1. ลง iTunes จากเว็บ Apple (ไม่ใช่ Microsoft Store) และ Sideloadly จาก sideloadly.io
2. เสียบสาย iPhone → เปิด Sideloadly → ลากไฟล์ `QuitIG.ipa` ใส่ → ใส่ Apple ID → Start
3. บน iPhone: ตั้งค่า → ความเป็นส่วนตัวและความปลอดภัย → โหมดนักพัฒนา (Developer Mode) → เปิด แล้วรีสตาร์ท
4. ตั้งค่า → ทั่วไป → VPN และการจัดการอุปกรณ์ → แตะ Apple ID ของคุณ → เชื่อถือ
5. Apple ID ฟรีใช้ได้ 7 วัน ติดตั้งซ้ำหรือเปิด auto-refresh ใน Sideloadly
