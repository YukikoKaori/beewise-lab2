# BeeWise analytics plan

## Product questions and event contract

Events use Firebase recommended names where they fit. Parameters are bounded, typed and contain no parent name, email, phone, user ID, free-text query, learning goal, message, tutor name, chat ID or invoice ID. Search terms are deliberately not logged because the field also accepts free text; query length, selected filters and outcome are sufficient to measure funnel health without sending user-entered text.

| Event | Trigger | Parameters (type) | Question it answers | Lab 2 flow |
|---|---|---|---|---|
| `login` | Email or Google sign-in succeeds | `method` (string) | Which sign-in methods complete successfully? | Account access / Discover and connect |
| `sign_up` | A parent or tutor account is created | `method` (string), `account_type` (string enum: parent/tutor) | Which account types complete registration? | Parent account access / Tutor application |
| `tutor_application_submitted` | Tutor application document is created with pending status | none | How many tutor applications reach review? | Tutor registration |
| `logout` | Parent signs out | none | How many authenticated sessions end by explicit sign-out? | Account access |
| `search` | Search is submitted after results or an error resolve | `query_length` (int), `filter_count` (int), `sort_mode` (string enum), `result_count` (int), `outcome` (string enum: results/empty/error) | Which search configurations return no results or errors? | Discover and connect, Search |
| `view_tutor` | An active tutor detail is loaded | `subject_count` (int), `entry_source` (string enum) | Which discovery entry points lead to tutor details, and how complete are viewed profiles? | Discover and connect, Tutor detail |
| `view_detail` | A group chat, trial proposal, class revision, invoice or official schedule route opens | `detail_type` (string enum: group_chat/trial_proposal/class_revision/invoice/official_schedule) | Which stages of consultant onboarding are opened, and where does the flow stop? | Discover/connect, consultant onboarding, payment/schedule |
| `ai_match_success` | AI returns one or more IDs from the active catalog | `result_count` (int) | How often does AI matching produce an actionable recommendation? | AI matching |
| `ai_match_no_results` | AI returns no valid active tutor | none | How often must users recover from an AI no-match? | AI matching recovery |
| `connection_request_submitted` | Firestore batch succeeds | `request_type` (string enum) | How many tutor profiles progress to a submitted request? | Discover and connect |
| `chat_message_sent` | Parent text write succeeds | `message_type` (string enum: text) | How often do submitted requests lead to parent chat activity? | Consultant onboarding |
| `trial_response` | Parent response is stored | `response` (string enum: accepted/alternate_time) | Do trial proposals fit the requested time? | Consultant onboarding |
| `class_revision_confirmed` | Parent confirms a consultant revision | none | How often does the proposed class reach parent confirmation? | Consultant onboarding |
| `class_adjustment_requested` | Parent requests a revision | none | Where do proposed class details need correction? | Consultant onboarding recovery |
| `payment_verification_requested` | Pending verification request is stored | none | How many confirmed classes reach payment verification? | Payment |
| `export_report` | Tutor PDF is generated | `subject_count` (int), `file_size_kb` (int) | Which profile views lead to a report export? | Tutor detail / file export |
| `upload_report` | Storage upload completes | `file_size_kb` (int) | How many generated reports reach cloud storage? | File export and upload |

## Implementation and privacy

`AnalyticsService` owns all Firebase Analytics calls. The auth-state provider and auth controllers set the Firebase Analytics user ID to the authenticated UID after sign-in and restore it for an existing signed-in session; sign-out clears it. Telemetry failures are isolated so a completed user action stays completed. No UID is copied into event parameters. Search logs length/count/category outcome only; profile/detail views log enum values and subject count, not names or document IDs.

The implementation is code-reviewed locally. Live event receipt, parameter values and user-ID association remain unverified until the student Firebase project is configured and a DebugView capture is added under `evidence/analytics/`.
