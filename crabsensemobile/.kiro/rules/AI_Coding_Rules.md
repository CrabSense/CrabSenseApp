# AI Coding Rules

Version: 1.0

---

# Objective

Mục tiêu của AI là tạo ra source code production-ready, dễ bảo trì, dễ mở rộng và không phá vỡ kiến trúc hiện tại.

---

# Golden Rules

AI MUST NOT:

- Thay đổi business logic nếu không được yêu cầu.
- Thay đổi API Contract.
- Thay đổi Database Schema.
- Thay đổi Route.
- Thay đổi Authentication Flow.
- Thay đổi Role Permission.
- Thay đổi Folder Structure.
- Đổi tên file.
- Đổi tên class.
- Xóa code đang hoạt động.
- Thêm package mới nếu chưa được chấp thuận.

---

# AI MUST

- Phân tích yêu cầu trước khi code.
- Chỉ sửa đúng phạm vi task.
- Sinh code compile được.
- Null Safety 100%.
- Có Error Handling.
- Có Loading State.
- Có Empty State.
- Có Offline State nếu cần.
- Có Retry.
- Không duplicate code.
- Không dead code.
- Không unused import.
- Không magic number.
- Không hard-code.

---

# Before Coding

AI phải:

1. Đọc Requirement
2. Đọc API
3. Đọc Model
4. Đọc Architecture
5. Đọc Existing Code
6. Sau đó mới code.

---

# Before Finish

Checklist

- Compile Success
- No Warning
- No Error
- Clean Code
- Correct Naming
- Correct Folder
- Correct Architecture

---

# Forbidden

AI KHÔNG ĐƯỢC

❌ đoán API

❌ đoán Database

❌ đoán JSON

❌ đoán Business Logic

❌ đoán Permission

Nếu thiếu dữ liệu

=> hỏi hoặc TODO.

---

# Documentation

Code mới phải có comment ngắn gọn nếu logic phức tạp.

Không comment những thứ hiển nhiên.

---

# Commit Style

feat:

fix:

refactor:

style:

docs:

test:

chore: