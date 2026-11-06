# ARTEMIS TC-25 Autonomous Exploration & Android-Native Permission Verification

## Overview

This directory preserves the official, independently verifiable evidence for **TC-25 (Exploratory Testing)** and the **Android-Native OS Interaction** required by the PRM393 Lab 3 Rubric (*PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf*, page 23).

- **Objective 1 — AI-Driven Autonomous Exploration**: Execute 15–30 continuous minutes of autonomous mobile exploration across the BeeWise Android application.
- **Objective 2 — Android-Native Interaction**: Exercise a genuine Android OS runtime permission dialog (`POST_NOTIFICATIONS`) at startup.
- **Safety & Provider Constraint**: Official DeepSeek API (`deepseek-flash`), strict zero-Gemini fallback (`ARTEMIS_DEEPSEEK_ONLY=1`), maintaining at least $0.50 USD reserve for Nexora at all times.

---

## 1. Verified Achievements

| Requirement | Rubric Standard | Verified Evidence | Status |
| :--- | :--- | :--- | :--- |
| **Continuous Exploration Duration** | 15–30 continuous minutes ($900 \le t \le 1800$) | **925.734 seconds (~15.43 continuous minutes)** in single session `aa025ab2-6a51-4b34-a4c1-3ba346e4e0a4` (23 autonomous steps) | **PASS** |
| **Pytest & JUnit Output** | 0 errors, 0 failures | `result.junit.xml` records 1 test passed in 925.896s | **PASS** |
| **Android-Native OS Interaction** | OS Dialog Interaction | **2 independent live executions** on `GrantPermissionsActivity` (`com.google.android.permissioncontroller`) tapping `Allow` / `Don't allow` | **VERIFIED** |
| **Screens Explored** | Discovery, Search, AI, Account, Messages | Home, Tutor Search & Filter, AI Matching Consultation UI, Account Diagnostics, Login Validation, Messages Flow, Crashlytics Non-fatal Demo | **VERIFIED** |
| **Provider & Zero Gemini Fallback** | DeepSeek-only, no fallback | Official DeepSeek API (`deepseek-flash`), `ARTEMIS_DEEPSEEK_ONLY=1` strictly enforced | **VERIFIED** |
| **Financial & Nexora Reserve Safety** | Cap approved, Nexora ≥ $0.50 | DeepSeek live balance is **$0.76 USD**, safely exceeding the **$0.50 USD reserve** by **$0.26 USD** | **VERIFIED** |

---

## 2. Qualifying Passing Session

### Session `aa025ab2-6a51-4b34-a4c1-3ba346e4e0a4` (Single Continuous Run)
- **Start Time**: 2026-11-06T11:12:38Z
- **Measured Duration**: **925.734 seconds** (15 minutes 25 seconds)
- **Outcome**: **COMPLETED / PASS**
- **Autonomous Actions**: 23 steps across 6 major areas:
  1. *Tìm gia sư (Search & Discovery)*: Subject chips, area chips, teaching mode chips, fee slider, sort toggle, empty state.
  2. *Ghép AI (AI Consultation UI)*: Prompt typing, 0/500 char counter, empty-submit snackbar validation.
  3. *Tài khoản (Account)*: Logged-out state, Remote Config info, PDF report section, diagnostics.
  4. *Đăng nhập (Login Validation)*: Empty field validation and format validation.
  5. *Tin nhắn (Messages)*: Login-gated state.
  6. *Firebase Demo Flow*: Dispatched sample non-fatal error to Crashlytics.
- **Product UX Findings Discovered**:
  - Filter reset discrepancy: Tapping 'Xóa bộ lọc' in Search does not clear active 'Online'/'Tại nhà' mode chip.
  - Demo catalog empty-state for filtered combinations.

---

## 3. Preserved Historical Sessions

- **Session 1 (`85ed1fab-fc9e-4884-a636-7ce35628edf1`)**: 379.34 seconds (15 steps). AI tapped `Allow` on `POST_NOTIFICATIONS` dialog (`GrantPermissionsActivity`).
- **Session 2 (`5bb907c1-a8c0-4b44-806f-d9d941ff2840`)**: 466.80 seconds (16 steps). AI tapped `Don't allow` on `POST_NOTIFICATIONS` dialog (`GrantPermissionsActivity`).
- **Session 4 (`8ccdcfb4-527b-4fcf-87d5-8fadf3c37690`)**: 1018.735 seconds (26 steps). Deep autonomous traversal.

---

## 4. Evidence Index

- `result.junit.xml`: Official JUnit test outcome (PASS, 0 errors, 0 failures, 925.896s measured time).
- `exploration-manifest.json`: Full session manifest with token counts, costs, durations, and model configuration.
- `exploration-summary.json`: Exploration findings, screens visited, and handled edge states.
- `native-permission-evidence.json`: Detailed step-by-step logs, coordinates, and ADB tap executions verifying the Android-native OS dialog interaction.
- `owner-approval-v6.json`: Owner budget authorization record for the final run.
- `screenshots/`: High-resolution screenshots capturing native permission dialogs before/after tap and key app screens.
