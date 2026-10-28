# Ninja Blossom — ตำนานนินจาซากุระ (Godot 4.7.2)

**ผู้จัดทำ:** ภูริชญา โมรา (Purichaya Mora) — แบบฝึกหัดที่ 5 First 3D Game

เกม 3D Platformer ต่อยอดจาก **3D Platformer Starter Kit** (The Silver Demons / SD Studios, CC0)

## วิธีเปิด
1. เปิด Godot 4.7.2 → **Import** → เลือกไฟล์ `project.godot` ในโฟลเดอร์นี้
2. กด ▶ (F5) — เริ่มที่หน้าเมนู `Scenes/UI/MainMenu.tscn`

## วิธีเล่น
- เก็บ **อัญมณีวิญญาณ** ให้ครบทุกเม็ด → ประตูโทริอิจะเปิด → เดินเข้าไปเพื่อไปด่านต่อไป
- หลบกับดัก: หนามผุด, แท่งหนามหมุน, ลูกตุ้มหนาม, แท่นหินถล่ม, ตกน้ำ/ตกเหว
- มีหัวใจ 3 ดวงต่อด่าน, โคมหิน = จุดเช็กพอยต์, ดอกบัวชมพู = แท่นดีดตัว
- ปุ่ม: WASD เดิน • Space กระโดด (กดซ้ำกลางอากาศ = ตีลังกา) • เมาส์ / Q E หมุนกล้อง • R เริ่มด่านใหม่ • Esc ปล่อยเมาส์

## ฉาก
| ฉาก | ไฟล์ |
|---|---|
| เมนูหลัก | `Scenes/UI/MainMenu.tscn` |
| ด่าน 1 หุบเขาซากุระ (กลางวัน, 9 อัญมณี) | `Scenes/Levels/Level1_SakuraValley.tscn` |
| ด่าน 2 วิหารจันทรา (กลางคืน, 10 อัญมณี) | `Scenes/Levels/Level2_MoonTemple.tscn` |
| ฉากชนะ | `Scenes/UI/Victory.tscn` |

## สิ่งที่แก้จาก Starter Kit
- **เปลี่ยน Player** จาก Gobot เป็น **Ninja** (Quaternius, poly.pizza, CC0) — `Scenes/Objects/NinjaModel.tscn`
- **แก้ Animation ให้ตรงชื่อเดิม**: สร้าง `Assets/Models/Characters/ninja_animations.res` แมปท่า Ninja → `Idle / Run / Jump / Flip / Fall` (+ Hurt, Land, VictorySign) เหมือนของ Gobot, ทำท่า **Flip** ตีลังกา 360° ใหม่, แก้กระดูกแขนที่หายจาก glb (ท่า T-pose) และผูก Skin เข้ากับ Skeleton ใหม่
- `player.gd` ยังเป็นโครงเดิมของ Kit + เพิ่มบาดเจ็บ/เกิดใหม่, coyote time, แท่นดีด, ท่าชนะ, SpringArm กันกล้องทะลุ
- ระบบเก็บเหรียญเดิม → อัญมณี + ประตูล็อก, หัวใจ, เช็กพอยต์, HUD ภาษาไทย, เพลง/เสียงใหม่
- ฉากสร้างด้วย Low-Poly: เกาะ/แท่นสร้างด้วยโค้ด (`Scripts/Platform.gd`) + โมเดล glb เล็ก ๆ จาก poly.pizza → ทั้งโปรเจกต์ไม่กี่ MB

## เครดิต
- Starter Kit: The Silver Demons (CC0)
- Ninja, Torii, Bamboo, Rocks, Spikes, Spiky ball, Gems, Bush: Quaternius / Kay & Isa Lousberg / iPoly3D (CC0) via poly.pizza
- Sakura tree: konta johanna (CC-BY 3.0), Stone lamp: Flopsi (CC-BY 3.0), Red lantern: Sophie Kim (CC-BY 3.0) via poly.pizza
- ฟอนต์ Kanit (SIL OFL) • เพลงและเสียงประกอบสร้างขึ้นเอง

`tools/` = สคริปต์ที่ใช้สร้างฉาก/ทดสอบ (ไม่จำเป็นต่อการเล่น)
