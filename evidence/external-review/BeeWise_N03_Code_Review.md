# BeeWise N-03 — Independent technical review draft

Date: 2026-11-03
Reviewer: AI-assisted technical analysis; requires human reviewer sign-off for N-04
Scope: Uploaded BeeWise-N03-implementation-review.zip and identical .patch copies (uncommitted working tree snapshot)
Disposition: CHANGES REQUESTED (proposed; developer must record acceptance/rejection)

## F-01 — P1 — Test safety — Default runner bypasses case allowlist
**Location:** `e2e_test/run-artemis.ps1:8-17, 53-65`; `e2e_test/test_account_and_firebase.py:12, 179, 228, 271`.
**Condition:** `ARTEMIS_CASE_IDS` unset/empty. The runner validates only user-supplied IDs but invokes the entire `not exploratory and not manual_setup` suite with no `-k` filter, including scenarios outside `$allowedCaseIds` (e.g. TC-07 sign-in, TC-11 PDF export, TC-13 sign-out). This defeats the stated non-business-mutation allowlist and might cause unwanted side effects or charges.
**Recommendation:** Fail closed on empty case selection or always construct a `-k` filter from the allowlist. Add a negative/default-run regression check that proves disallowed scenarios cannot execute.
**Proposed disposition:** Accept, pending maintainer confirmation.

## F-02 — P1 — Correctness — Fabrication observation overwritten with false
**Location:** `e2e_test/conftest.py:239-301` (especially 260-269, 287-301).
**Condition:** The TC-01 normalizer sees `number_of_tutor_cards=0` and `real_firestore_confirmation=True`. It accepts this as proof of no fabrication and overwrites the observation with `profiles_fabricated=False`, regardless of an explicit contradictory `profiles_fabricated=True` in the input. The parser also does not require authoritative evidence beyond the agent report. This can generate a false negative.
**Reproduction:** `_decode_observation({'home_title':'BeeWise','number_of_tutor_cards':0,'firebase_notice':None,'real_firestore_confirmation':True,'profiles_fabricated':True})` returns `profiles_fabricated: False`.
**Recommendation:** Reject conflicting fields and preserve original observations. Define explicit positive/negative provenance contract; don't infer a negative from count zero alone. Add contradictory-input tests.
**Proposed disposition:** Accept, pending maintainer confirmation.

## F-03 — P2 — Correctness — Overflow and crash are conflated
**Location:** `e2e_test/conftest.py:204-227`.
**Condition:** An entry reports only `overflow_or_crash=True`; normalization sets both `overflow_seen` and `crash_dialog_seen` to `True`. This invents an unobserved failure type and makes diagnosis inaccurate.
**Reproduction:** `_decode_observation({'destinations':[{'name':'Trang chủ','title_visible':True,'overflow_or_crash':True}]})` returns both flags true.
**Recommendation:** Require separate boolean signals for overflow and crash (or retain an `issue_unknown_type` field and fail inconclusive). Assert independent behavior in parser checks.
**Proposed disposition:** Accept, pending maintainer confirmation.

## F-04 — P2 — Test quality — TC-09 checks only a set, not visit count/order
**Location:** `e2e_test/test_account_and_firebase.py:81-97`; `e2e_test/conftest.py:189-203`.
**Condition:** `set(destinations) >= expected` permits duplicates, extra destinations and arbitrary order, despite the test instruction that all five destinations must be visited in order. The parser also accepts `{'destinations':['Trang chủ'], 'overflow':False,'crash':False}` as a complete shaped report (though the test later fails it).
**Recommendation:** Check exact ordered list of five unique destinations, and validate that complete navigation evidence is present in the parser where appropriate. Add negative cases for reordered, duplicated, missing, extra destinations.
**Proposed disposition:** Accept, pending maintainer confirmation.

## F-05 — P2 — Correctness — Boolean counts accepted as integer
**Location:** `e2e_test/conftest.py:248-249, 420-425`; `e2e_test/test_discovery.py:34, 59, 85`.
**Condition:** Python's `bool` is a subclass of `int`. `isinstance(False, int)` and `isinstance(True, int)` both return True. Invalid AI observations can satisfy integer count validations.
**Reproduction:** `require({'result_count':True}, 'result_count', int)` returns `True`. TC-01 normalization also accepts `number_of_tutor_cards=False`.
**Recommendation:** Validate count fields with `type(value) is int` (with separate bounds checks) rather than `isinstance` for integers. Add booleans to negative checks.
**Proposed disposition:** Accept, pending maintainer confirmation.

## F-06 — P2 — Reliability — False quota detection from free-form text
**Location:** `e2e_test/conftest.py:17-24, 82-105`.
**Condition:** `_trace_has_rate_limit` JSON-serializes the entire trace and searches for string fragments like `429` or `rate limit`, including historical narratives, prompts and negative statements (e.g. `No 429 or rate limit occurred`). A harmless mention may stop an otherwise valid session.
**Recommendation:** Inspect structured error events/status codes of the current session, not arbitrary trace strings. If no typed error is available, restrict to known failure records and use context-aware matches. Test false positives and genuine 429/RESOURCE_EXHAUSTED events.
**Proposed disposition:** Accept, pending maintainer confirmation.

## Validation and limits
- Two uploaded `.patch` files have identical SHA-256 hashes. ZIP includes source snapshot and a working-tree diff.
- Demonstrated parser behaviors by extracting and executing the functions from `conftest.py`; no host/device execution.
- Real runner execution not performed (Windows PowerShell + configured ARTEMIS host/device required).
- A reviewer must inspect the PR and confirm/comment on these findings for a human-independent review requirement. Author must then record per-finding dispositions and correction commit SHAs. No claim is made that defects have been fixed.
