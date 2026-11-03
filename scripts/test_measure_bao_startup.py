"""Timing interpretation checks; these do not certify native startup."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
from types import SimpleNamespace
import http.client

spec = importlib.util.spec_from_file_location(
    "startup", Path(__file__).with_name("measure-bao-startup.py"))
startup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(startup)


class FirstFrameMetricsTests(unittest.TestCase):
    def test_truncated_trace_does_not_abort_ui_and_anr_collection(self):
        calls = []

        def run(*args):
            calls.append(args)
            output = b""
            if args[0] == "logcat":
                output = b"Dart VM service is listening on http://127.0.0.1:1234/private/"
            elif args[:2] == ("forward", "tcp:0"):
                output = b"4321"
            elif args[:2] == ("shell", "cat"):
                output = b"1 (app) " + b" ".join([b"1"] * 20)
            elif args[:2] == ("shell", "getconf"):
                output = b"100"
            return SimpleNamespace(stdout=output, returncode=0)

        with patch.object(startup.urllib.request, "urlopen",
                          side_effect=http.client.IncompleteRead(b"")):
            result = startup.observe_flutter_frames(run, "1", Path("unused.json"))
        self.assertEqual(result["status"], "NOT_OBSERVED")
        self.assertEqual(calls[-1], ("forward", "--remove", "tcp:4321"))

    def test_framework_and_raster_timings_keep_distinct_origins(self):
        events = [
            {"name": "FlutterEngineMainEnter", "ts": 2_000_000},
            {"name": "Widgets built first useful frame", "ts": 2_500_000},
            {"name": "Rasterized first useful frame", "ts": 2_750_000},
        ]
        self.assertEqual(startup.flutter_frame_metrics(events, 1_000_000), {
            "processToFirstFrameBuiltMs": 1500.0,
            "engineToFirstFrameBuiltMs": 500.0,
            "processToFirstFrameRasterizedMs": 1750.0,
            "engineToFirstFrameRasterizedMs": 750.0,
        })

    def test_later_frames_cannot_prove_startup_when_ring_buffer_wrapped(self):
        events = [{"name": "Frame", "ph": "e", "ts": 2_000_000},
                  {"name": "SurfaceFrame::Submit", "ph": "E", "ts": 2_100_000}]
        self.assertTrue(all(value is None for value in
                            startup.flutter_frame_metrics(events, 1_000_000).values()))

    def test_missing_raster_and_incompatible_clock_are_not_pass(self):
        events = [{"name": "FlutterEngineMainEnter", "ts": 2_000_000},
                  {"name": "Widgets built first useful frame", "ts": 2_500_000}]
        self.assertIsNone(startup.flutter_frame_metrics(
            events, 1_000_000)["processToFirstFrameRasterizedMs"])
        self.assertTrue(all(value is None for value in
                            startup.flutter_frame_metrics(events, 3_000_000).values()))


if __name__ == "__main__":
    unittest.main()
