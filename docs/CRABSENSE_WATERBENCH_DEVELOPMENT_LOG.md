# CrabSense — Nhật ký triển khai WaterBench

**Cập nhật:** 27/11/2026 (UTC+7) · **Mốc hiện tại:** P2.4.6.1  
**Phạm vi:** hardware-water-quality-analysis, CrabSenseKiosk, CrabSenseBE, CrabSenseAIWaterQualityAnalysis, CrabSenseFE, CrabSenseApp.  
**Nguồn:** nội dung cuộc trao đổi hiện có, PR/commit/workflow GitHub đã đối chiếu ngày 27/11/2026. Các giai đoạn trước phần lịch sử hội thoại còn truy xuất được được ghi ở mức tổng hợp, không khẳng định đã tái dựng đầy đủ từng thao tác. Các kết quả CI lịch sử không thay thế nghiệm thu thiết bị thật.

## 1. Mục tiêu và nguyên tắc

- Hệ thống phân tích nước RAS cho cua lột: NO2 (Sera), NO3 (VASTOCEAN), NH3/NH4 (Thủy Phước). Định kỳ ba kênh song song; thủ công theo kênh hoặc cả ba.
- Luồng: ESP32 Master/Slave → Kiosk nhận/lưu biên nhận và ảnh riêng tư → BE/PostgreSQL → Water AI → Farm Admin đối chứng, xét duyệt và công bố → Manager Desktop, Staff Mobile đọc kết quả. System Admin Web chỉ giám sát kỹ thuật.
- Không đồng nhất kết quả AI ước tính, hồ sơ đối chứng đã công bố, và phép đo cảm biến production. Không tự động ghi kết quả AI vào WaterMeasurement, không tự phát lệnh xử lý nước.
- Phân biệt thiếu dữ liệu với số 0 thật; không tạo timestamp, ảnh, số đo giả; không suy ra đơn vị hóa học, trạng thái trực tuyến hoặc hoàn tất vật lý từ biên nhận.
- Giữ phạm vi dữ liệu theo role/khu nuôi; không nới quyền để làm CI PASS.
- Mỗi PR một Conventional Commit; không force-push main. Chỉ merge khi CI cần thiết đã PASS đúng head SHA; kiểm tra CI main/deployment sau merge.
- Không chuyển sang P3 trước khi hoàn tất toàn bộ P2.4.6; chemical accuracy, cleaning, sample alignment, physical execution và chạy liên tục cần nghiệm thu thật.

## 2. Trạng thái lộ trình

| Mốc | Phạm vi | Trạng thái tại lần kiểm tra này |
|---|---|---|
| P0 | Firmware, liên kết Master/Slave | PASS theo nghiệm thu phần mềm trước đó; thiết bị thật chưa nghiệm thu |
| P1 | Xả/rửa và an toàn firmware | PASS theo nghiệm thu phần mềm trước đó; chưa xác minh vật lý |
| P2.1 | Kiosk đồng bộ cấu hình, bằng chứng | Đã triển khai |
| P2.2 | BE/DB và khôi phục an toàn | Đã triển khai |
| P2.3 | AI và tích hợp liên repo | PASS CI, cập nhật pin theo main đang hoàn tất |
| P2.4.1 | Nền tảng API | PASS CI/CD |
| P2.4.2 | Farm Admin Web | PASS CI/CD |
| P2.4.3 | Farm Manager Desktop | PASS CI/CD |
| P2.4.4 | Farm Staff Mobile | PASS CI/CD |
| P2.4.5 | System Admin Web | PASS CI/CD |
| P2.4.6.1 | Rà soát hợp đồng, DB, repo | ĐANG LÀM — lịch sử/cached dữ liệu thật và bảo mật chưa hoàn tất |
| P2.4.6.2 | JWT thật và phân quyền bốn role | CHƯA NGHIỆM THU |
| P2.4.6.3 | Hardware–Kiosk–BE–AI | CHƯA NGHIỆM THU toàn diện; CI mô phỏng đã có |
| P2.4.6.4 | Đồng bộ kết quả Web/Desktop/Mobile | CHƯA NGHIỆM THU xuyên nền tảng |
| P2.4.6.5 | Mất kết nối/retry/khôi phục | CHƯA NGHIỆM THU toàn diện; CI có kịch bản hồi phục |
| P2.4.6.6 | Bảo mật và nghiệm thu CI/CD | CHƯA LÀM |
| P3.1–P3.4 | Thiết bị thật, hiệu chuẩn, đối chứng, vận hành liên tục | CHƯA LÀM |

## 3. Nhật ký theo thứ tự triển khai

### 01 — Nền tảng firmware, Kiosk, BE, AI (bối cảnh trước P2.4)
- Firmware v2: nhận diện station/boot/batch/session/capture, sự kiện biên nhận, xử lý theo kênh; tài liệu v2-integration/v2-gateway. Firmware main rà soát: b552498. Legacy PR #1 không được tự merge theo tài liệu v2.
- Kiosk: cấu hình lịch/trạm, spool bằng chứng, đồng bộ idempotent, mất phản hồi và gửi lại không upload trùng. [Kiosk #27](https://github.com/CrabSense/CrabSenseKiosk/pull/27), head 150f9d5 → main ceb194a; CI #71/#72 PASS.
- Water AI: mô hình hiệu chuẩn đơn điệu, QC ảnh/ROI, truy vết calibration/media, NH3 equilibrium và bảng tra Thủy Phước. [AI #5](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/pull/5) → main 51de29a; Water AI CI #20/#21 và Private Cross Integration #1/#2 PASS. CI dùng dữ liệu tổng hợp, chưa phải độ chính xác hóa học.
- Không có đủ chi tiết để tái dựng mọi commit P0–P2.3; đọc tài liệu và lịch sử Git của từng repo khi cần.

### 02 — P2.4.1: Hoàn thiện Backend cho quản trị phân tích
- [BE #108](https://github.com/CrabSense/CrabSenseBE/pull/108), 75bcab4 → 5954075, 1 commit, merge 27/11.
- Thêm lưu RequestJson cho retry bền vững (migration 20261127080000_WaterBenchRetryRequest), endpoint retry-request, danh sách độ mặn hợp lệ và ảnh camera riêng tư; xét duyệt độc lập và công bố hồ sơ đối chứng.
- Phạm vi FarmManage và khu nuôi, hash/idempotency, khóa session; kết quả công bố không được tự đưa vào sensor production.
- [CI #416](https://github.com/CrabSense/CrabSenseBE/actions/runs/45956436011), [main #417](https://github.com/CrabSense/CrabSenseBE/actions/runs/45956898440), [VPS #223](https://github.com/CrabSense/CrabSenseBE/actions/runs/45957368251) PASS. Chưa kiểm tra migration production trực tiếp.

### 03 — P2.4.2: Farm Admin Web
- API/media picker, ROI trực quan, bộ chọn độ mặn, khôi phục request retry, duyệt/công bố. Gate role FarmAdministrator; dữ liệu theo khu.
- [FE #29](https://github.com/CrabSense/CrabSenseFE/pull/29): Chromium #4 lỗi ammonia payload not submitted; tách refresh station/batch, giữ identity và nội dung form khi response calibration đến muộn, validate ammonia payload rõ ràng.
- Head ban đầu a9c0e8e → bản sửa b603c52 → main 5c7ba9c. 1 commit. Sonar #131/#132, [Chromium #5](https://github.com/CrabSense/CrabSenseFE/actions/runs/45961559086), Pages #119/#120 PASS. Workflow deploy bắt buộc browser test.
- Chromium kiểm thử API giả lập; chưa thay thế smoke production.

### 04 — P2.4.3: Farm Manager Desktop
- [App #37](https://github.com/CrabSense/CrabSenseApp/pull/37), 5ea91b5 → main 283a24c; một commit.
- Theo dõi trạm/lịch, danh sách 50 batch, biên nhận, timeline, NO2/NO3/NH3, AI/retry/review và đối chứng đã công bố; đọc theo khu được cấp, refresh 30 giây, không có thao tác quản trị.
- Sonar #147/#148, Desktop Hosted #48/#49, Desktop Local #24, App Pages #52/#53, Mobile Hosted #35 PASS theo các lần kiểm tra trước.
- Kiểm thử liên nền tảng thật còn lại P2.4.6.

### 05 — P2.4.4: Farm Staff Mobile
- [App #38](https://github.com/CrabSense/CrabSenseApp/pull/38): trang Phân tích nước read-only, danh sách khu theo BE, identity batch nghiêm ngặt, dữ liệu cũ/chưa có, yêu cầu đo lại, kết quả đối chứng.
- Commit 873e656: Sonar #149 FAIL do test import tương đối ../../../lib trùng định danh User/UserRole với package imports. Lỗi getter canUseMobile và incompatible User.
- Sửa sang package:crabsensemobile/, giữ nguyên quyền; thêm widget test deep-link sai khu, revoked area, stale/retest, publication và nút trái quyền. Commit cedf802 → main ae93674, một commit.
- [Sonar #150](https://github.com/CrabSense/CrabSenseApp/actions/runs/45966759649), Mobile #37, main Sonar #151, Mobile #38, Desktop #50, Pages #55/#56 PASS. Log báo 36 test Mobile PASS, gồm 5 WaterBench mới.
- Chưa nghiệm thu trên thiết bị thật.

### 06 — P2.4.5: System Admin Web
- [BE #109](https://github.com/CrabSense/CrabSenseBE/pull/109), 121b467 → main 14ccffd; một commit. GET /api/system/water-bench/stations phân trang, platform-only, chỉ metadata Kiosk/ESP32/config, biên nhận kỹ thuật, camera/clock và bộ đếm AI 24h. Không payload/ảnh/nồng độ/khóa/điều khiển; không migration.
- [CI #418](https://github.com/CrabSense/CrabSenseBE/actions/runs/45967322827), main #419, [VPS #224](https://github.com/CrabSense/CrabSenseBE/actions/runs/45968218436) PASS.
- [FE #30](https://github.com/CrabSense/CrabSenseFE/pull/30): /system/water-bench, danh sách trạm, freshness, lịch sử lỗi, phân trang, refresh 30 giây. FE draft chờ BE. Head b74fc5f: Chromium #6 FAIL do test mong /login trong khi guard chuyển System Admin về /system.
- Sửa test chuyển hướng /system và /dashboard, đo số request trái quyền bằng 0, giữ phiên đăng nhập, chụp đúng trang lỗi. Head 40d6ab8 → main 0e1178d, một commit.
- Sonar #133/#134/#135, Build #121/#122, [Chromium #7](https://github.com/CrabSense/CrabSenseFE/actions/runs/45969632724), [Deploy Web #123](https://github.com/CrabSense/CrabSenseFE/actions/runs/45969931825) PASS.
- System Admin chỉ kỹ thuật. Số lỗi 24h không đồng nghĩa sự cố đang mở; biên nhận gần đây không chứng minh phần cứng hoạt động.

### 07 — P2.4.6.1: Rà soát sáu repo và xử lý drift CI/biểu đồ giả
- Baseline: firmware b552498, Kiosk ceb194a, BE 14ccffd, AI 51de29a, FE 0e1178d, App ae93674. Main CI riêng lẻ PASS nhưng chưa đảm bảo tương thích.
- [Kiosk #28](https://github.com/CrabSense/CrabSenseKiosk/pull/28), 8947507 → main 65b781d. Pin BE từ a9d62d0 lên 14ccffd. [Sonar #73](https://github.com/CrabSense/CrabSenseKiosk/actions/runs/45971603978), [main #74](https://github.com/CrabSense/CrabSenseKiosk/actions/runs/45971972536) PASS.
- [AI #6](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/pull/6), ban đầu 576534d: cập nhật Kiosk/BE, Water AI CI #23 PASS nhưng [Private Cross Integration #3](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45971633941) FAIL HTTP 502 tại NH3/ammonia-reference equilibrium, dòng 435 test tích hợp. Xử lý ở mục 08.
- [App #39](https://github.com/CrabSense/CrabSenseApp/pull/39), 150ea36 → main 575f5cf. Xóa _mockChartHistory sinh sin/cos, tạm hiển thị thông báo lịch sử chưa xác minh; chặn response metrics cũ. Sonar #152/#153, Mobile #39/#40, Pages #57/#58, Desktop #51 PASS.
- Audit phát hiện thêm thiếu/zero, race BLoC, cache không đủ provenance, history chưa bảo toàn quality/units/pagination, 19 cảnh báo npm (10 high/9 moderate tại log cũ), chưa test JWT thật, geometry QC của fixture tích hợp chưa bắt buộc. Chi tiết: docs/water-bench-cross-repo-audit-p2.4.6.1.md.

### 08 — P2.4.6.1: Sửa NH3 HTTP 502
- Nguyên nhân xác nhận qua tích hợp: .NET tick 100ns, Python datetime microsecond; BE trước đây đòi echo timestamp nguyên bản tuyệt đối. Sửa tại ranh giới wire, chuẩn UTC microsecond, giữ nguyên timestamp evidence gốc và kiểm tra echo chính xác. Không đổi công thức hóa học/DB/phân quyền.
- [BE #110](https://github.com/CrabSense/CrabSenseBE/pull/110), 3a24a73 → main 59ce2c5; một commit. Bổ sung test TAN-N, NH4, printed_table và tamper timestamp. [CI #420](https://github.com/CrabSense/CrabSenseBE/actions/runs/45972569075), [main #421](https://github.com/CrabSense/CrabSenseBE/actions/runs/45973297739), [VPS #225](https://github.com/CrabSense/CrabSenseBE/actions/runs/45973758294) PASS.
- AI #6 sửa pin Kiosk main 65b781d và BE candidate 3a24a73; fixture bắt buộc chữ số phần giây thứ 7, assert evidence gốc. Head b85f379 → main 18ae0de; Water AI #24/#25/#26, [Private Cross #4](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45972646433) và [main #5](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45973263596) PASS.
- BE candidate và main cùng tree 7c8679ab7f52563f9c841563c1b4955f0d727eaf. [AI #7](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/pull/7), f918915: pin chính xác BE main 59ce2c5. [Water AI #28](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45974908159) và [Private Cross #6](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45974908026) PASS. PR #7 còn OPEN tại lần kiểm tra tạo nhật ký; chưa merge trong lượt này.

### 09 — P2.4.6.1: Model dữ liệu cảm biến và request Mobile
- [App #40](https://github.com/CrabSense/CrabSenseApp/pull/40), 091ecff → bản cuối 89e97f1 → main 83e7eec; 1 commit, 12 file.
- Chuyển WaterQuality sang nullable, giữ zero thật, bỏ giá trị thiếu/sai/nonfinite và timestamp giả; live per-sensor với Realtime, đơn vị và khu/dãy. Không trộn snapshot nhiều cảm biến; giữ WaterBench độc lập với lab cũ.
- BLoC generation mới nhất thắng, bỏ refresh chồng, retry giữ khu/dãy; chặn response cũ, không dùng Home summary sai phạm vi; không suy diễn toàn khu online từ một sensor. Ngưỡng mặc định ghi rõ tham khảo.
- Tạm vô hiệu hóa lịch sử và SQLite cache legacy để tránh mất presence/provenance. Đây là biện pháp an toàn tạm thời, chưa hoàn thiện chart và offline; chưa migration.
- Test missing vs zero, sai đơn vị/khu/dãy, request cũ, retry. [Sonar #155](https://github.com/CrabSense/CrabSenseApp/actions/runs/45975358393), [Mobile #42](https://github.com/CrabSense/CrabSenseApp/actions/runs/45975358401), [Pages #60](https://github.com/CrabSense/CrabSenseApp/actions/runs/45975358363) PASS. PR đã merge. [Sonar main #156](https://github.com/CrabSense/CrabSenseApp/actions/runs/45975788829) PASS.
- Main [Pages #61](https://github.com/CrabSense/CrabSenseApp/actions/runs/45975788695), [Desktop #52](https://github.com/CrabSense/CrabSenseApp/actions/runs/45975788644), [Mobile #43](https://github.com/CrabSense/CrabSenseApp/actions/runs/45975788676) IN_PROGRESS lúc kiểm tra. Chưa nghiệm thu UI production.
- Tài liệu chi tiết: docs/water-quality-mobile-data-integrity-p2.4.6.1.md.

### 10 — Khởi tạo nhật ký chung (27/11/2026)
- Đối chiếu PR/commit/main/workflow và ghi lại các mốc ở trên theo yêu cầu người dùng.
- Không thay đổi chức năng trong lượt lập nhật ký; không merge AI #7 trong lượt này.
- File này là nhật ký duy nhất cần cập nhật xuyên suốt. Các tài liệu kỹ thuật chuyên biệt cũ giữ nguyên làm bằng chứng bổ trợ.

## 4. Bảng phân quyền mục tiêu

| Chức năng | System Admin Web | Farm Admin Web | Manager Desktop | Staff Mobile |
|---|---|---|---|---|
| Giám sát kỹ thuật toàn hệ thống | Có | Không | Không | Không |
| Đọc WaterBench nghiệp vụ theo khu | Không | Có | Có | Có |
| Cấu hình trạm/lịch, hiệu chuẩn, retry | Không | Có | Không | Không |
| Xét duyệt, công bố đối chứng | Không | Có | Không | Không |
| Xem hồ sơ đối chứng đã công bố | Không | Có | Có | Có |
| Tự động đưa estimate vào cảm biến production/điều khiển nước | Không | Không | Không | Không |

Đây là quyền mục tiêu theo thiết kế và mã đã kiểm tra. Cần xác nhận thật bằng JWT và API/DB, kể cả truy cập khu ngoài phạm vi và thu hồi quyền, trong P2.4.6.2.

## 5. Snapshot mã nguồn và các việc còn lại

| Repo | Main mới nhất ghi nhận | Ghi chú |
|---|---|---|
| hardware-water-quality-analysis | b552498 | Mốc audit; chưa flash/test thật |
| CrabSenseKiosk | 3fc897c | PR #29 merged, CI #75/#76 PASS |
| CrabSenseBE | 40464ce | PR #111 merged; CI #424/#425 và VPS #226 PASS |
| CrabSenseAIWaterQualityAnalysis | 2c63944 | PR #8 merged; AI CI #32/#33 và private cross #8/#9 PASS |
| CrabSenseFE | 0e1178d | Main deployment #123 PASS |
| CrabSenseApp | d6f2ff0 | Nhật ký #48 merged; Sonar #174, Mobile #51, Desktop #60, Pages #69 PASS |

| Mã | Ưu tiên | Việc còn lại | Điều kiện hoàn thành |
|---|---|---|---|
| T01 | P0 | DONE: AI #7 merged, AI main #29 và private cross #7 PASS | Exact BE main pin, main CI PASS |
| T02 | P0 | DONE: App main #61/#52/#43 và Sonar #156 PASS | Tất cả PASS đúng main 83e7eec |
| T03 | P0 | BE #111 CI #424/#425 và VPS #226 PASS, merged 40464ce; App chart còn chờ | Sửa cấu hình test Npgsql, chạy đủ HTTP/PostgreSQL, CI PASS, review migration, deploy, App chart thật |
| T04 | P1 | Cache offline nullable, có user/area scope, invalidation khi logout/revoke, retention/migration | Kiểm thử offline và isolation; phục hồi chart/cache an toàn |
| T05 | P1 | Kiểm tra toàn bộ current metric UI, status/threshold/unit, dữ liệu stale và scope; bổ sung production smoke | Không label sai hoặc hiển thị số liệu ngoài quyền |
| T06 | P1 | 19 npm vulnerabilities theo log trước (cần audit lại) | Phân loại direct/transitive/dev/runtime, sửa an toàn, CI PASS |
| T07 | P1 | Kiểm thử PostgreSQL technical diagnostics, JWT bốn role | P2.4.6.2; 401/403 và scoped access |
| T08 | P1 | Geometry QC bắt buộc với fixture phù hợp; kiểm tra private media/Drive | P2.4.6.3 |
| T09 | P1 | Cùng batch/receipt/estimate/review trên ba nền tảng, retry/cancellation/stale | P2.4.6.4–5 |
| T10 | P2 | Kiểm tra firmware legacy PR #1; không merge vội; rà migration và hợp đồng còn lại | Không đưa code legacy vào v2 |
| T11 | P2 | Tổng kiểm thử bảo mật, CI/CD và quy trình test thực tế | P2.4.6.6 |
| T12 | P3 | Thiết bị thật, UART, đo chuẩn, mẫu thật, vệ sinh, vận hành lâu dài | Chỉ sau P2.4.6 PASS |

**Việc kế tiếp:** nghiệm thu nền tảng cache scoped Mobile, sau đó nối auth/API/UI và kiểm thử offline/revoke. Không tự đánh dấu P2.4.6.1 PASS chỉ vì CI riêng lẻ xanh.

## 6. Quy định cập nhật file sau mỗi lượt

Đọc file này trước khi bắt đầu mọi đợt kiểm tra/sửa/triển khai WaterBench. Sau khi thực hiện xong trong lượt đó:
1. Append một mục mới ở phần 7, kể cả lượt chỉ kiểm tra CI không sửa code. Không xóa lịch sử hay ghi đè kết quả cũ; sửa sai bằng mục đính chính.
2. Ghi ngày giờ theo UTC+7 nếu đã xác minh; mốc, yêu cầu, repo, file/API/DB đã đổi, PR và head SHA, main SHA, CI run links/kết quả đúng SHA, merge/deploy, test thực tế và vấn đề còn tồn tại.
3. Cập nhật snapshot và bảng trạng thái/công việc còn lại ở phần 2 và 5. Phân biệt CODED, CI PASS, MERGED, DEPLOYED, PRODUCTION VERIFIED và PHYSICAL VERIFIED.
4. Một Conventional Commit cho mỗi PR; nếu làm App trong cùng đợt, ưu tiên đưa nhật ký vào cùng commit. Nếu chỉ repo khác thay đổi, cập nhật nhật ký bằng một commit docs riêng trên App, không thêm nhiều commit vụn.
5. Không ghi secrets, token, dữ liệu ảnh riêng tư, URL chứa credential hoặc dữ liệu người dùng. Không claim CI/deploy/test nếu chưa thấy kết quả.
6. Trước khi kết thúc lượt trả lời, cung cấp link file và ghi rõ mục mới. Nếu không thể cập nhật GitHub, nói rõ blocker; không tự nhận đã lưu.
7. Quy trình áp dụng cho các lượt tiếp theo khi người dùng yêu cầu triển khai/kiểm tra; không có tác vụ chạy tự động ngoài lượt chat.

## 7. Nhật ký bổ sung (append-only)

### Mẫu cho mỗi lượt tiếp theo
- Thời điểm:
- Mốc / yêu cầu:
- Kết quả rà soát:
- Thay đổi code/API/DB (hoặc không thay đổi):
- Repository / PR / commit / main:
- CI và deployment (link + trạng thái):
- Test đã làm và giới hạn:
- Quyết định kỹ thuật, lỗi còn lại:
- Việc tiếp theo:


### 11 — P2.4.6.1.1–6.1.4: Nhật ký main, AI main, API lịch sử scoped (27/11/2026)
- Đọc file nhật ký trước khi làm. [App #41](https://github.com/CrabSense/CrabSenseApp/pull/41) head 08d81b0, Sonar #157 PASS, squash merge main 149f7be28a2efc83b93efddaf9b464195b6ac71f trong lượt này. Main Sonar #158, Mobile #44, Desktop #53 PASS; Pages #62 (45977077389) đang chạy lúc ghi.
- [AI #7](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/pull/7) head f918915, Water AI #27/#28 và private cross #6 PASS đúng BE main 59ce2c5; squash merge main 43931eab49f36968511d37572e64421fdc964de6. [AI main #29](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45977092768) PASS; [Private Cross main #7](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45977092771) đang chạy.
- App #40 main 83e7eec: Sonar #156, Pages #61, Mobile #43, Desktop #52 đều PASS (deployment workflow, không phải kiểm thử người dùng production).
- Rà soát BE: /api/iot/history tạo aggregate snapshot thiếu presence/quality; /api/iot/sensor-data/{sensorId} thiếu chất lượng và phạm vi đo lịch sử. WaterMeasurement chỉ lưu SensorId/WaterSystemId, không đủ chứng minh khu/dãy lịch sử khi thiết bị chuyển vị trí.
- Tạo [BE #111](https://github.com/CrabSense/CrabSenseBE/pull/111), head 232fc3bc71555d76d34a3e755d00bf01efb42538, 1 commit feat(iot): add provenance-scoped sensor history contract, 9 file. [CI #422](https://github.com/CrabSense/CrabSenseBE/actions/runs/45977407173) đang chạy; chưa merge hoặc deploy.
- API GET /api/areas/{areaId}/sensors/{sensorId}/history: FarmPortal + DB assignment, scope khu/dãy/cảm biến hiện tại không mâu thuẫn; chỉ đọc dữ liệu lưu đúng scope tại ingest, Realtime, type và unit khớp, timestamp thực, zero giữ nguyên. Range [from,to) tối đa 31 ngày, 500 rows/page, asOf bắt buộc từ page 2. Không lộ raw edge event ID, không đưa AI estimate vào history, no-store. Offset pagination có cutoff, không bảo đảm transaction snapshot; client cần dedup/reload nếu không nhất quán.
- Migration 20261127100000_ScopedSensorHistory thêm nullable ObservedAreaId, ObservedRowId, ObservedSensorType và index lọc; không backfill/đổi dữ liệu cũ. Chỉ stamp authenticated fresh ingest có timestamp rõ, unit tường minh, cấu hình scope không mâu thuẫn. Không khẳng định vị trí vật lý hoặc độ chính xác hiệu chuẩn. Dữ liệu cũ thiếu provenance không được đưa vào API mới; biểu đồ có thể rỗng cho đến khi có telemetry mới đủ điều kiện. Ingest thêm lookup cấu hình khi có liên kết row/system/component; cần test tải và tương thích. Index có thể cần kiểm tra lock/time trên bảng production lớn.
- Test mới InMemory: farm-only route, zero thật, sai khu/dãy/unit/quality, loại legacy, page/hasMore, không lộ ID edge, chuyển row không gán dữ liệu cũ, System Admin bị từ chối và scope cấu hình mâu thuẫn. Chưa xác nhận test PASS, chưa có test PostgreSQL migration/ingest thực cho PR #111. Cần rà thêm race relocation và query plan. Không thay đổi API legacy/FE/App/Kiosk/AI chức năng trong đợt này; chart/cache Mobile vẫn unavailable.
- Tiếp theo: kiểm tra BE CI #422, AI main cross #7 và App Pages #62; bổ sung kiểm thử PostgreSQL/ingest & migration trước merge BE, sau đó App cache nullable có scope và biểu đồ thật. Không chuyển P2.4.6.2/P3.

### 12 — Kiểm tra CI P2.4.6.1.4 (27/11/2026, 16:57 UTC+7)
- [BE #111](https://github.com/CrabSense/CrabSenseBE/pull/111) OPEN, head 232fc3bc71555d76d34a3e755d00bf01efb42538, chưa merge. [CI #422](https://github.com/CrabSense/CrabSenseBE/actions/runs/45977407173) FAIL. Job .NET unit tests and coverage lỗi Build: ScopedSensorHistoryTests.cs dòng 37, CS1061 AppDbContext không có Users. Đã đối chiếu AppDbContext: tên đúng AppUsers. Cần sửa db.Users.Add(actor) thành db.AppUsers.Add(actor); chưa chạy các unit test mới, chưa xác nhận API đúng. Job tổng hợp FAIL do validation job lỗi.
- Job PostgreSQL, production publish and EF migrations (job 140432502632) PASS: PostgreSQL concurrency/integrity, production publish + migration bundle (không VPS), migration guard, full clean/legacy EF migration tests đều success. Không đồng nghĩa với test tích hợp scoped history/ingest mới hoặc thời gian lock/index trên production đã nghiệm thu. BE main vẫn 59ce2c5, VPS #225 PASS.
- AI #7 đã merge 43931eab49f36968511d37572e64421fdc964de6; [Water AI main #29](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45977092768) và [Private Cross main #7](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/45977092771) PASS. Hoàn tất T01 đối với BE 59ce2c5; không phải xác nhận tương thích BE #111.
- [App #42](https://github.com/CrabSense/CrabSenseApp/pull/42) đã merge, main 23c0b1989a89d0c516c46c0173a9adeea4a1faca. Sonar #159 PASS, [main #160](https://github.com/CrabSense/CrabSenseApp/actions/runs/45977709742), [Pages #63](https://github.com/CrabSense/CrabSenseApp/actions/runs/45977709656), [Mobile #45](https://github.com/CrabSense/CrabSenseApp/actions/runs/45977709748), [Desktop #54](https://github.com/CrabSense/CrabSenseApp/actions/runs/45977709981) PASS.
- Lượt chỉ kiểm tra và ghi nhật ký; không sửa mã BE, không merge PR lỗi. Tiếp theo sửa lỗi build giữ một commit PR #111, kiểm tra CI và test scoped history/ingest PostgreSQL. Chưa chuyển 6.1.5/P2.4.6.2/P3.

### 13 — Sửa BE #111 và bổ sung kiểm thử HTTP/PostgreSQL (27/11/2026)
- Đọc nhật ký mục 12; App #43 đã merge main a2b4fd5de9e0748fee7a4a7fcb71df2df2944f8c, Sonar main #162 (45978464329), Desktop #55 (45978464293), Mobile #46 (45978464317) PASS; Pages #64 (45978464381) đang chạy lúc kiểm tra.
- [BE #111](https://github.com/CrabSense/CrabSenseBE/pull/111): sửa ScopedSensorHistoryTests.cs db.Users thành db.AppUsers, giữ nguyên kiểm thử và quyền. Cập nhật một commit feat(iot): add provenance-scoped sensor history contract, head fd987bb4d95def2e582d22479cab6ea710d80e97 thay 232fc3b, tổng 11 file, không force main. [CI #423](https://github.com/CrabSense/CrabSenseBE/actions/runs/45978771749) đang chạy, chưa merge/deploy. Main vẫn 59ce2c5.
- Thêm ScopedSensorHistoryPostgresTests.cs: test HTTP qua PermissionApiFactory/TestServer, IotService và EF/Npgsql + UnitOfWork thật, DB scoped_history_test trên loopback đã chạy full migration. Test credential thiết bị sai/đúng, ingest fresh hai mẫu, duplicate replay, dữ liệu 0 thật, backfill và thiếu unit/legacy loại khỏi scoped history, bảo toàn scope/quality/unit, pagination asOf, quyền cả ba farm role, 401/403/404/400, revoke staff và chuyển cảm biến sang khu/dãy khác. Test không thực thi relay/alert thật (mock side effects) và dùng test-header role chứ không phải JWT production.
- Bổ sung run-migration-tests.ps1 tạo DB riêng, dùng migration bundle hiện có, chạy dotnet test đúng lớp kiểm thử, kiểm TRX đúng một test Passed (không chấp nhận skip). Unit suite thường skip bài PostgreSQL nếu không có env test; job migration bắt buộc thực thi. Marker yêu cầu: SCOPED_SENSOR_HISTORY_HTTP_POSTGRES_PASSED=1. Không sửa migration, API production hoặc mở rộng scope trong lượt này.
- Không tuyên bố test mới PASS trước khi CI hoàn tất. Kiểm tra hiệu năng/lock/index production, race relocation, JWT thật và thiết bị thật vẫn chưa nghiệm thu. Mobile cache/history chưa triển khai lại vì BE chưa merge/deploy. Tiếp theo kiểm tra CI #423, log marker và xử lý lỗi; cập nhật pin tích hợp khi BE main mới ổn định.

### 14 — Kiểm tra CI #423 (27/11/2026)
- [BE #111](https://github.com/CrabSense/CrabSenseBE/pull/111) OPEN, head fd987bb4d95def2e582d22479cab6ea710d80e97, một commit. [CI #423](https://github.com/CrabSense/CrabSenseBE/actions/runs/45978771749) FAIL. Unit job 140437075227 PASS: 741 test được phát hiện, 740 thực thi PASS, 0 fail, một test PostgreSQL chạy ở job riêng; cả ba ScopedSensorHistoryTests PASS. Lỗi CS1061 trước đã hết.
- DB job 140437074736 FAIL tại Full clean and legacy EF migration tests (including production bundle). HTTP/PostgreSQL test thực thi 1, fail 1, skip 0. ScopedSensorHistoryPostgresTests.cs dòng 44 Assert.Empty(GetPendingMigrationsAsync()) thấy cả InitialBeSchema và các migration cũ trong pending. Đã đối chiếu Infrastructure/DependencyInjection.cs: production UseNpgsql đặt MigrationsHistoryTable("__EFMigrationsHistory", "be"), nhưng test dùng UseNpgsql(cs) mặc định đọc migration history ở schema mặc định. Script migration đọc be."__EFMigrationsHistory". Sai cấu hình test là nguyên nhân rất phù hợp với log; cần chạy lại để xác nhận, không kết luận DB production thiếu migration. Sửa cả seed/test options và DI trong TestServer theo cấu hình production (migrations assembly, history schema); giữ Assert.Empty và kiểm tra migration mới đã áp dụng. Không bỏ test/marker. Chưa đến bước HTTP ingest/history, chưa có marker SCOPED_SENSOR_HISTORY_HTTP_POSTGRES_PASSED=1.
- BE main 59ce2c5, CI #421 và VPS #225 vẫn PASS; BE #111 chưa merge/deploy. App #44 đã merge f904c090d8fce0f8045e308821ae9515b8b69f3a, Sonar #163 PR PASS, main #164 (45979362102), Mobile #47 (45979361913), Desktop #56 (45979362025) PASS, Pages #65 (45979361935) đang chạy tại snapshot.
- Chỉ kiểm tra và cập nhật nhật ký, chưa sửa BE. Tiếp theo sửa cấu hình EF test, giữ một commit PR #111, kiểm tra CI và toàn bộ kịch bản HTTP/DB. Chưa triển khai Mobile cache, chưa chuyển P2.4.6.2/P3.

### 15 — Đồng bộ cấu hình PostgreSQL test với production (27/11/2026)
- [BE #111](https://github.com/CrabSense/CrabSenseBE/pull/111): commit sửa [323f373](https://github.com/CrabSense/CrabSenseBE/commit/323f3736a6b08f5057eb56993e93640fd8660b49), fix(test): align scoped history PostgreSQL migration configuration. Chỉ sửa ScopedSensorHistoryPostgresTests.cs: dùng chung ConfigurePostgres cho seed/verify/move và DI TestServer, khai báo migrations assembly, history table be.__EFMigrationsHistory, timeout 120 giây giống production. Giữ toàn bộ assertion, kiểm migration và marker bắt buộc; không sửa API/schema production.
- Một commit sửa BE trong lượt này, không rewrite lịch sử PR. CI mới chưa xuất hiện khi kiểm tra lần đầu; chưa xác nhận build hoặc HTTP/PostgreSQL PASS. CI #423 cũ vẫn FAIL. Không rerun commit cũ, không merge/deploy, không triển khai cache Mobile hoặc P3.
- Tiếp theo: xác nhận CI của đúng head 323f373, marker SCOPED_SENSOR_HISTORY_HTTP_POSTGRES_PASSED=1, kiểm tra review và các gate còn lại trước merge BE; tiếp tục nhật ký chung.

### 16 — Đối chiếu tiến độ tổng thể P0–P3 (27/11/2026)
- Đọc nhật ký và docs/water-bench-cross-repo-audit-p2.4.6.1.md, kiểm tra PR BE #111, App #45 và CI mới. Theo 13 nhóm người dùng liệt kê: 6 PASS phần mềm theo baseline/nhật ký (P0, P1, P2.1–3, P2.4.1–5 gộp), 1 đang làm (P2.4.6.1), 6 chưa nghiệm thu (P2.4.6.2–6, P3). Đây chỉ là đếm nhóm không trọng số; không phải tỷ lệ hoàn thành dự án hoặc nghiệm thu vật lý. P0/P1 dựa trên nhật ký lịch sử, không chạy lại firmware trong lượt này. Các mục 6.2–6.5 đã có một số test thành phần, chưa nghiệm thu toàn diện.
- [BE #111](https://github.com/CrabSense/CrabSenseBE/pull/111) OPEN head 323f3736a6b08f5057eb56993e93640fd8660b49; [CI #424](https://github.com/CrabSense/CrabSenseBE/actions/runs/45979930154) IN_PROGRESS: Build và PostgreSQL concurrency/integrity PASS; unit test đang chạy; production publish/bundle đang chạy; full migration + HTTP/PostgreSQL marker chưa xác nhận. Chưa merge/deploy. App Pages #65 (45979361935) build/deploy PASS. App #45 OPEN trước cập nhật.
- P2.4.6.1: đã rà sáu repo, loại biểu đồ giả, sửa NH3 502, AI pin BE main PASS, sửa nullable/zero và race request Mobile. API scoped history đã code, đang nghiệm thu; cache SQLite/biểu đồ thật còn thiếu. Còn rà UI current metrics, dependency audit npm, migration/index và race relocation; chưa đóng P2.4.6.1.
- Lượt chỉ rà tiến độ và cập nhật nhật ký, không thay đổi chức năng. Tiếp theo CI #424, marker HTTP/PostgreSQL, review migration, merge/deploy BE nếu đủ gate, đồng bộ pin Kiosk/AI, Mobile cache/chart, rồi đóng 6.1 trước 6.2. Không chuyển P3.

### 17 — BE scoped history PASS/merged; cập nhật pin Kiosk (27/11/2026)
- [BE CI #424](https://github.com/CrabSense/CrabSenseBE/actions/runs/45979930154) PASS đúng PR head 323f373. DB job 140440946881 log: Passed 1, Failed 0, Skipped 0; marker SCOPED_SENSOR_HISTORY_HTTP_POSTGRES_PASSED=1. Unit/coverage và aggregate PASS. [BE #111](https://github.com/CrabSense/CrabSenseBE/pull/111) đã merge trước lượt triển khai này, main 40464ce34de8384383ff14f7243dc069625f7ebe lúc 17:16 UTC+7. [Main CI #425](https://github.com/CrabSense/CrabSenseBE/actions/runs/45980663565) IN_PROGRESS; chưa có deploy mới được xác nhận, VPS #225 PASS thuộc 59ce2c5. Không đồng nhất CI test với migration/health production; chưa đo lock/index production hoặc nghiệm thu JWT thật.
- [Kiosk #29](https://github.com/CrabSense/CrabSenseKiosk/pull/29) tạo trong lượt này, một commit 19590c9ca301537373b5ba0855177e517a2832ea, ci(water-bench): validate scoped history backend baseline. Cập nhật hai pin (checkout + SHA assertion) trong .github/workflows/sonarcloud.yml từ 14ccffd sang 40464ce; cập nhật docs/water-bench-ai-cross-integration-p2.3.6.md. Không đổi runtime, không thêm secret, không hạ gate. CI mới chưa xuất hiện tại lần kiểm tra đầu; chưa merge. Kiosk main 65b781d.
- App #45 đã merge trước lượt này, main b2d90bd7f6fa461c5a57fa8c4877e43597f465be. Water AI vẫn 43931ea, pin BE 59ce2c5/Kiosk 65b781d. Chờ Kiosk main mới để pin AI chính xác, tránh đổi pin nhiều lần. Chưa mở cache Mobile hoặc chart thật trước khi xác nhận BE deploy và cross integration. Tiếp theo main #425/VPS, Kiosk #29 CI, merge nếu đủ gate, pin AI và kiểm thử private cross, rồi P2.4.6.1.5. Không chuyển 6.2/P3.

### 18 — Kiểm tra BE deploy và Kiosk main (27/11/2026, 20:25 UTC+7)
- BE main 40464ce34de8384383ff14f7243dc069625f7ebe: [CI #425](https://github.com/CrabSense/CrabSenseBE/actions/runs/45980663565) PASS cả unit/coverage, PostgreSQL/migrations và aggregate; DB job 140443420897 log Passed 1, Failed 0, Skipped 0, marker SCOPED_SENSOR_HISTORY_HTTP_POSTGRES_PASSED=1. [VPS #226](https://github.com/CrabSense/CrabSenseBE/actions/runs/45981279475) PASS đúng SHA, controlled migration bundle, migration guard và backup/migrate/deploy/health-check đều success. Đây là bằng chứng workflow, không phải kiểm tra SQL trực tiếp hay JWT/telemetry production từ lượt này.
- [Kiosk #29](https://github.com/CrabSense/CrabSenseKiosk/pull/29) CI [#75](https://github.com/CrabSense/CrabSenseKiosk/actions/runs/45981237728) PASS đúng head 19590c9; Windows runtime, Edge V2, pin BE và HTTP/controller/PostgreSQL với storage double PASS. Đã merge 20:24:56 UTC+7 trước lượt này, main 3fc897caa558d5186139d2452f3a7b5f3eb4e912. [Main #76](https://github.com/CrabSense/CrabSenseKiosk/actions/runs/46006911492) IN_PROGRESS, ba job đang chạy.
- [App #46](https://github.com/CrabSense/CrabSenseApp/pull/46) Sonar #169 PASS, merged 20:24:39 UTC+7, main 44595d2b8304b6820510a0680936bbffb711497e. Main [#170](https://github.com/CrabSense/CrabSenseApp/actions/runs/46006872048), [Mobile #49](https://github.com/CrabSense/CrabSenseApp/actions/runs/46006872149), [Desktop #58](https://github.com/CrabSense/CrabSenseApp/actions/runs/46006872085), [Pages #67](https://github.com/CrabSense/CrabSenseApp/actions/runs/46006872033) IN_PROGRESS. Baseline trước main b2d90bd: Mobile #48, Desktop #57, Pages #66 PASS.
- AI main 43931ea, CI #29 và Private Cross #7 PASS trên pin cũ. Lượt chỉ kiểm tra và cập nhật nhật ký, không sửa chức năng hay pin AI. Tiếp theo xác nhận Kiosk main #76, pin AI sang BE 40464ce/Kiosk 3fc897c, kiểm thử và merge nếu đủ gate; sau đó Mobile cache/chart. Chưa đóng P2.4.6.1, chưa chuyển 6.2/P3.

### 19 — Đồng bộ private Water AI với BE/Kiosk main mới (27/11/2026)
- [Kiosk main #76](https://github.com/CrabSense/CrabSenseKiosk/actions/runs/46006911492) PASS đúng 3fc897caa558d5186139d2452f3a7b5f3eb4e912: Windows runtime, SonarCloud/Edge V2 và Kiosk+BE+PostgreSQL (storage double), xác minh pin BE. BE 40464ce CI #425 và VPS #226 vẫn PASS. App baseline 44595d2: Sonar #170, Mobile #49, Desktop #58, Pages #67 đều PASS.
- [AI #8](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/pull/8) tạo trong lượt này, một commit 4a0c4b94fd979830ef32b291156d1ee799e9077e, ci(water-bench): validate merged scoped history integration baseline. Hai file: .github/workflows/water-bench-cross-integration.yml (cập nhật cả checkout và SHA assertions từ BE 59ce2c5/Kiosk 65b781d sang BE 40464ce/Kiosk 3fc897c), docs/water-bench-private-integration.md. Giữ nguyên real local AI, PostgreSQL, test fixture, TRX gate và quyền read-only; không đổi runtime/công thức/DB, không thêm secret. Geometry-disabled synthetic fixture vẫn chưa nghiệm thu hình học production.
- [Water AI CI #32](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/46007447071) và [Private Cross #8](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/46007447085) IN_PROGRESS đúng head 4a0c4b9 lúc kiểm tra. Chưa merge AI #8; main vẫn 43931ea.
- [App #47](https://github.com/CrabSense/CrabSenseApp/pull/47) Sonar #171 (46007043777) PASS đúng 175fc71; squash merge trong lượt này main be6b18d5e02dad3767593b96c17c095f446a7e89. Main workflow mới chưa kiểm tra. Tiếp tục nhật ký bằng PR docs riêng, một commit. Chưa bật Mobile cache/chart, chưa nghiệm thu JWT thật, SQL production trực tiếp hoặc thiết bị thật. Tiếp theo kiểm tra AI #32/private cross #8, merge đúng head khi đủ gate, kiểm tra main rồi P2.4.6.1.5. Không chuyển 6.2/P3.

### 20 — AI main PASS; P2.4.6.1.5 nền tảng cache Mobile (27/11/2026)
- AI #8 đã merge 2c63944 trước lượt này; CI #32, private cross #8, main #33 và [main cross #9](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis/actions/runs/46007909089) PASS. Log main cross: 1 executed/pass, 0 failed/skipped. App #48 merged d6f2ff0; Sonar #174, Mobile #51, Desktop #60, Pages #69 PASS. Pages #68 cancelled, không đánh dấu PASS.
- Rà soát API BE scoped-sensor-history-v1 và Mobile legacy cache: bảng cũ default zero, không có user scope; không copy dữ liệu legacy. Thêm migration SQLite v4 tạo bảng cache riêng, strict decoder nhiều page/identity/unit/quality/range/asOf, giữ zero, từ chối page thiếu hoặc duplicate, giới hạn 5000 điểm. Lớp cache theo epoch phiên/user và query chính xác; TTL 5 phút từ asOf, phạm vi lưu 7 ngày, tối đa 32 snapshot, purge khi bắt đầu phiên/logout/revoke, không lưu token. Thêm test decoder và SQLite. Không thay API BE hoặc thuật toán AI.
- Đây là nền tảng chưa nối vào AuthBloc, remote repository hay giao diện. Không bật offline/chart cho người dùng trước khi wiring và test thực tế; quyền bị thu hồi từ xa khi offline không thể xác nhận ngay. Test migration upgrade, web, tích hợp auth/API, pagination và CI còn phải xác nhận. Không đóng 6.1 hoặc chuyển 6.2/P3.

### 21 — P2.4.6.1.5: API lịch sử online và vòng đời xác thực (27/11/2026)
- App #49 merged b2a42e7, CI PR #175/Mobile #52/Pages #70 và main #176/Mobile #53/Desktop #61/Pages #71 PASS. Rà workflow #176: danh sách flutter test trước đó KHÔNG chứa scoped_history_cache_test.dart; do đó chưa có bằng chứng test SQLite v4 riêng chạy, dù analyze/build PASS. Bổ sung cả cache test và service/migration test vào gate bắt buộc, không bỏ test cũ.
- Thêm ScopedHistoryService + HTTP loader sử dụng API BE scoped-sensor-history-v1, pageSize 250, giữ nguyên asOf từ server, tối đa 20 page, strict complete decoder. Chỉ online; không fallback cache khi lỗi. Cố định bearer cho mỗi request, so sánh sub/expiry/token với user hiện tại (không thay xác thực chữ ký ở BE), không transparent refresh hoặc debug log dữ liệu lịch sử. Kiểm tra generation/identity trước và sau mỗi trang và cache write. AuthBloc event và secure credential mutations vô hiệu hóa cache; DI singleton. Không kích hoạt UI hoặc offline reads, không ghi cache web. Kiểm thử cache, session/logout/denial và nâng cấp v3→v4 không backfill legacy. CI mới chưa xác nhận.
- Không sửa BE/AI/Kiosk, không mở chart trước khi kiểm thử API adapter, auth race, migration và UI. Việc tiếp theo CI PR mới, nối màn hình và kiểm thử tương tác; offline phải có nhãn stale và chính sách quyền riêng. Không chuyển 6.2/P3.

### 22 — Sửa lỗi phân tích Mobile CI #177 (27/11/2026)
- [App #50](https://github.com/CrabSense/CrabSenseApp/pull/50), head 5dd4cee: [CI #177](https://github.com/CrabSense/CrabSenseApp/actions/runs/46010018712) FAIL tại Analyze Mobile. Log job 140542840309 xác nhận ba lỗi tại scoped_history_service_test.dart dòng 13: hai ambiguous_import và một invocation_of_non_function do trùng User giữa Drift database.dart và Authentication Domain user.dart. Mobile tests bị skip, chưa có bằng chứng SQLite/migration/session test PASS. Desktop analysis/tests, Mobile Hosted Preview #54 và Pages #72 PASS.
- Sửa import database.dart thành show AppDatabase trong file test để dùng User thuộc Authentication Domain. Giữ nguyên mọi test/assertion và điều kiện CI; không đổi runtime, schema, API, quyền truy cập hoặc bật UI/offline. Cùng một commit sửa và nhật ký; không ghi đè lịch sử PR.
- Tiếp theo kiểm tra CI đúng head mới, xác nhận Mobile Analyze và test cache/service/migration chạy thật, xử lý lỗi tiếp nếu có. Chỉ merge khi đủ gate. Chưa đóng P2.4.6.1.5, chưa chuyển 6.2/P3.

### 23 — Sửa fixture nullable của Mobile CI #178 (27/11/2026)
- [CI #178](https://github.com/CrabSense/CrabSenseApp/actions/runs/46010710158), head d11274a, Mobile Analyze PASS; Mobile test 48 PASS/1 FAIL, Desktop analyze/tests PASS, Mobile #55 và Pages #73 PASS. Log job 140545177276 xác nhận lỗi duy nhất strict decoder tại scoped_history_cache_test.dart:45: Null is not a subtype of Object of value. Fixture suy luận Map<String,Object> nên gán null lỗi trước assertion; không phải bằng chứng runtime decoder sai. Bốn test mới còn lại PASS, gồm SQLite exact scope/TTL/logout/stale write, online service/denial/identity, giữ cutoff và logout giữa các trang, migration v3→v4 không backfill.
- Khai báo rõ fixture items là List<Map<String,dynamic>>, map phần tử nullable. Giữ assertion cũ, bổ sung trường hợp thiếu key value, NaN/Infinity, chuỗi/boolean, khôi phục zero và danh sách rỗng. Không sửa production decoder, auth, schema, API hoặc giảm gate CI. Một commit sửa test và nhật ký; giữ lịch sử PR #50.
- Tiếp theo kiểm tra CI đúng head mới và xác nhận toàn bộ 49 test thực thi PASS trước merge. Chưa bật offline hoặc UI/chart, chưa đóng P2.4.6.1.5, chưa chuyển 6.2/P3.
