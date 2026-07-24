# CrabSense Project Rules

Version 1.0

---

# Project

CrabSense

IoT Crab Farm Management

Flutter Mobile

ASP.NET Core API

PostgreSQL

ESP32

AI Vision

---

# Main Modules

Authentication

Dashboard

Farm

Box

Crab

IoT

Water Quality

AI

Harvest

Sales

Notification

Profile

---

# Mobile Rules

Bottom Navigation

Home

Water

Scan

Alert

Profile

---

# Screen Naming

MOB-Login

MOB-Home

MOB-ScanQR

MOB-BoxStatus

...

---

# API Naming

/api/auth

/api/boxes

/api/crabs

/api/videos

/api/alerts

/api/harvest

/api/sales

---

# Model Naming

BoxModel

CrabModel

VideoModel

HarvestModel

AlertModel

---

# Riverpod Naming

boxProvider

crabProvider

videoProvider

---

# Repository Naming

BoxRepository

HarvestRepository

VideoRepository

---

# Controller Naming

BoxController

HarvestController

AIController

---

# Screen Rules

Mỗi Screen phải có

Loading

Empty

Error

Retry

Offline

Pull Refresh

---

# Scan Flow

Scan QR

↓

Load Box

↓

Capture Video

↓

AI

↓

Inspection

↓

Recommendation

↓

Harvest

---

# AI Rules

Confidence

Recommendation

Feedback

History

---

# Offline Rules

Operation Log

Harvest

Inspection

Video Queue

Sync Queue

Retry Queue

---

# Notification Rules

Push

Video Due

Alert

Harvest Window

AI Recommendation

---

# UI Rules

Material 3

Rounded Card

Glass Effect nhẹ

Primary

Teal

Background

Light Gray

Radius

16

Animation

300ms

---

# Code Rules

Không hard-code.

Không duplicate.

Không business logic trong Widget.

Không gọi API trong UI.

Không sửa DB.

Không sửa API.

Không sửa Architecture.

---

# Done Definition

Compile Success

No Warning

No Error

Responsive

Dark Mode

Offline Ready

Null Safe

Production Ready