> **2026-10-31 corrective update (supersedes prior runtime status):** Native update: Analytics SDK initialization and guest screen navigation exercised on isolated API37. Seven DebugView event receipts remain NOT RUN; no authenticated event or Console screenshot is claimed.

# Analytics

Implementation: `analytics_service.dart`, controllers/providers;
contract `docs/analytics-plan.md`, source `db1f12e`. BAO-A01 removes tutor document
ID from `connection_request_submitted`; only `request_type` remains.
PASS mocks exercise typed search parameters without text/IDs, UID set/clear and
the actual connection caller. `../../cloud/checks/verified/flutter-test.*`.

Device debug mode was requested through the dedicated ADB helper; restoration is
recorded in Android logs. This alone does not prove DebugView delivery. At least
7 meaningful events with Console parameters: NOT RUN; browser Console control unavailable. Management API confirms Analytics linkage and one stream, which is not event-delivery proof.
Do not manufacture login/sign_up/logout events while signed out to reach seven.

External action: with management access and dedicated identity, follow real flows
from analytics-plan, filter the test device in DebugView, capture event/parameter
receipts and UID clearing. No recent overview data is not evidence of disabled
Analytics. Never capture secrets or personal identifiers in screenshots/logs.
