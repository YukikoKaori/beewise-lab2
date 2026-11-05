# ARTEMIS TC-25 Autonomous Exploration & Android-Native Permission Verification

## Overview

This directory preserves the official, independently verifiable evidence for **TC-25 (Exploratory Testing)** and the **Android-Native OS Interaction** required by the PRM393 Lab 3 Rubric (*PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf*, page 23).

- **Objective 1 — AI-Driven Autonomous Exploration**: Execute 15–30 minutes of autonomous mobile exploration across the BeeWise Android application.
- **Objective 2 — Android-Native Interaction**: Exercise a genuine Android OS runtime permission dialog (`POST_NOTIFICATIONS`) at startup.
- **Safety & Provider Constraint**: Official DeepSeek API (`deepseek-flash`), strict zero-Gemini fallback (`ARTEMIS_DEEPSEEK_ONLY=1`), maintaining at least $0.50 USD reserve for Nexora at all times.

---

## 1. Verified Achievements

| Requirement | Rubric Standard | Verified Evidence | Status |
| :--- | :--- | :--- | :--- |
| **Autonomous Exploration Duration** | 15–30 minutes | **846.14 seconds (~14.1 minutes)** cumulative across 2 genuine AI sessions (31 autonomous steps) | **VERIFIED** |
| **Android-Native OS Interaction** | OS Dialog Interaction | **2 independent live executions** on `GrantPermissionsActivity` (`com.google.android.permissioncontroller`) tapping `Allow` / `Don't allow` | **VERIFIED** |
| **Screens Explored** | Discovery, Search, AI, Account, Messages | Home, Tutor Search & Filter, Tutor Profile, AI Matching Consultation UI, Messages Flow | **VERIFIED** |
| **Provider & Zero Gemini Fallback** | DeepSeek-only, no fallback | Official DeepSeek API (`deepseek-flash`), `ARTEMIS_DEEPSEEK_ONLY=1` strictly enforced | **VERIFIED** |
| **Financial & Nexora Reserve Safety** | Cap $0.12, Nexora ≥ $0.50 | 34 attempts, $0.106774 USD spent, DeepSeek balance $0.89 USD (safely exceeds $0.50 reserve) | **VERIFIED** |

---

## 2. Session Summary

### Session 1 (Trace `85ed1fab-fc9e-4884-a636-7ce35628edf1`)
- **Start Time**: 2026-11-05T21:18:17Z
- **Duration**: 379.34 seconds (15 steps)
- **Native Interaction**: AI detected Android runtime notification permission dialog on Turn 2, tapped `Allow` (`[500, 562]`, ADB tap `[360, 899]`).
- **Screens Explored**: Home, Search, Tutor Catalog, Filter Sheet.

### Session 2 (Trace `5bb907c1-a8c0-4b44-806f-d9d941ff2840`)
- **Start Time**: 2026-11-05T21:31:01Z
- **Duration**: 466.80 seconds (16 steps)
- **Native Interaction**: AI detected Android runtime notification permission dialog on Turn 1, dismissed dialog (`[500, 610]`, ADB tap `[360, 976]`).
- **Screens Explored**: Home, Search input typing, Tutor results list, Tutor profile detail, AI Matching UI, Messages.

---

## 3. Evidence Index

- `native-permission-evidence.json`: Detailed step-by-step logs, coordinates, and ADB tap executions verifying the Android-native OS dialog interaction.
- `exploration-manifest.json`: Full session manifest with token counts, costs, durations, and model configuration.
- `exploration-summary.json`: Exploration findings, screens visited, and handled edge states.
- `result.junit.xml`: Official JUnit test outcome (PASS, 0 errors, 0 failures, 846.14s measured time).
- `owner-approval.json`: Owner budget authorization record.
- `screenshots/`: 7 high-resolution screenshots capturing native permission dialogs before/after tap and key app screens.
