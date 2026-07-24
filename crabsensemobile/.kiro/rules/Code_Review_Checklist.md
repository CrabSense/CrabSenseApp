# Code Review Checklist

Version: 1.0

Use this checklist before marking any task as completed.

---

# 1. Requirement Review

□ Requirement fully understood

□ Scope is correct

□ No unrelated changes

□ Business logic unchanged

---

# 2. Architecture

□ Clean Architecture respected

□ Feature structure unchanged

□ Dependency direction correct

□ No architecture violation

---

# 3. Folder Structure

□ Correct folder

□ Correct file location

□ No duplicated file

□ No unnecessary folders

---

# 4. Naming

□ File names use snake_case

□ Classes use PascalCase

□ Variables use camelCase

□ Constants use UPPER_CASE

□ Repository naming correct

□ Provider naming correct

---

# 5. UI Review

□ Material 3

□ Responsive

□ Dark Mode

□ Loading State

□ Empty State

□ Error State

□ Retry

□ Pull Refresh

□ Accessibility

□ Theme applied

---

# 6. Widget Quality

□ Widget under 200 lines

□ Function under 40 lines

□ No duplicated widgets

□ Reusable components extracted

---

# 7. State Management

□ Riverpod only

□ No business logic in Widget

□ State separation correct

□ Controller responsibility correct

---

# 8. API Review

□ Correct endpoint

□ Correct method

□ Correct model

□ Correct mapping

□ Error handled

□ Timeout handled

□ Retry handled

---

# 9. Model Review

□ Correct JSON mapping

□ Null safety

□ fromJson()

□ toJson()

□ copyWith()

□ Equality implemented

---

# 10. Validation

□ Required fields checked

□ Null checked

□ Empty checked

□ Range checked

□ Format checked

---

# 11. Error Handling

□ try/catch

□ User-friendly error

□ Logging

□ No silent exception

---

# 12. Performance

□ const widgets

□ Lazy loading

□ Pagination

□ Cache used

□ Dispose resources

□ No unnecessary rebuild

---

# 13. Security

□ No API key

□ No password

□ No token

□ No secret

□ No sensitive log

---

# 14. Offline

□ Offline state handled

□ Sync queue maintained

□ Retry available

□ Local cache updated

---

# 15. Notification

□ Notification handled

□ Permission checked

□ Duplicate prevention

---

# 16. Code Quality

□ No duplicated code

□ No dead code

□ No TODO left unintentionally

□ No debug print

□ No unused imports

□ No magic numbers

□ No hard-coded strings

---

# 17. Documentation

□ Public classes documented

□ Complex logic documented

□ README updated if necessary

---

# 18. Testing

□ Build successful

□ No analyzer issues

□ Widget tested

□ Logic verified

□ Edge cases checked

---

# 19. Git Review

□ Correct commit type

□ Small logical change

□ Meaningful commit message

---

# 20. Final Acceptance

Project can compile successfully.

Application behavior is unchanged except for requested features.

No existing feature is broken.

Project remains production-ready.

---

# AI Self Verification

Before completing a task, ask yourself:

1. Did I change only what was requested?

2. Did I preserve the architecture?

3. Did I introduce duplicate code?

4. Did I break any existing feature?

5. Is every new class reusable?

6. Is every widget maintainable?

7. Can another developer understand this code easily?

8. Will this scale in the future?

9. Would I approve this code in a professional code review?

10. Would I deploy this code to production today?

Only answer **YES** to all questions before marking the task as complete.