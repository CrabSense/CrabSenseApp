# Flutter Coding Standards

Version 1.0

---

# Flutter

Flutter Stable

Material 3

---

# Architecture

Clean Architecture

Presentation

↓

Application

↓

Domain

↓

Data

---

# State Management

Riverpod

Không dùng:

- Provider
- Bloc
- GetX
- MobX

trừ khi được yêu cầu.

---

# Navigation

GoRouter

Không Navigator.push trực tiếp.

---

# HTTP

Dio

---

# Local Storage

Hive

SharedPreferences

Flutter Secure Storage

---

# Dependency Injection

Riverpod Provider

---

# Folder Structure

lib/

core/

shared/

features/

config/

widgets/

---

# Widget Rules

Một Widget

<= 200 dòng

Nếu lớn hơn

=> tách.

---

# Function Rules

Một function

<= 40 dòng.

---

# Build Method

Không chứa business logic.

---

# Naming

Class

PascalCase

Function

camelCase

Variable

camelCase

Constant

UPPER_CASE

File

snake_case

---

# Theme

Không hard-code

Color

Font

Padding

Radius

Shadow

Animation

---

# Responsive

Phải hoạt động

Phone

Tablet

---

# Accessibility

Text Scale

Dark Mode

Screen Reader

---

# Performance

const

Lazy List

Pagination

Cache

Dispose

Image Cache

---

# API

UI

↓

Controller

↓

Repository

↓

Datasource

↓

Dio

---

# Error

Không catch Exception rỗng.

---

# Validation

Mọi Form đều validate.

---

# Security

Không log

Token

Password

Secret

API Key

---

# Testing

Widget Test

Unit Test

Integration Test

khi cần.