"""Offline fault injection for the pre-inference native gate; no E2E PASS."""

import sys
import unittest
from http.client import RemoteDisconnected
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/artemis-deepseek"))
import native_ready
from batch_once import wait_case

APP = '<hierarchy><node package="com.beewise.beewise" text="BeeWise"/></hierarchy>'
SHADE = '<hierarchy><node package="com.android.systemui" text="Internet"/></hierarchy>'
ANR = '<hierarchy><node package="android" text="BeeWise isn\'t responding"/></hierarchy>'
FOCUS = 'mCurrentFocus=Window{abc u0 com.beewise.beewise/.MainActivity}'


class NativeGateTests(unittest.TestCase):
    def device(self, frames):
        device = Mock()
        device.dump_hierarchy.side_effect = frames
        return device

    def run_probe(self, device, online="device"):
        self.statusbar_actions = []

        def adb(command, **kwargs):
            args = command[3:]
            if args[:3] == ["shell", "cmd", "statusbar"]:
                self.statusbar_actions.append(args[3])
            output = online if args == ["get-state"] else (
                "1" if args[-1] == "sys.boot_completed" else FOCUS)
            return SimpleNamespace(stdout=output)
        with patch.dict(sys.modules, {"uiautomator2": SimpleNamespace(connect_usb=lambda _: device)}), \
                patch("native_ready.subprocess.run", side_effect=adb):
            return native_ready.probe_device("offline-fake-device")

    def test_success_requires_shade_and_restored_app(self):
        device = self.device([APP, SHADE, APP])
        self.assertTrue(self.run_probe(device)["system_ui_responsive"])
        self.assertEqual(self.statusbar_actions, ["expand-notifications", "collapse"])

    def test_transient_animation_requires_observed_content(self):
        device = self.device([APP, APP, SHADE, SHADE, APP])
        self.assertTrue(self.run_probe(device)["readable_accessibility"])
        self.assertEqual(device.dump_hierarchy.call_count, 5)

    def test_transient_accessibility_disconnect_retries_read_only(self):
        device = self.device([APP, RemoteDisconnected(), SHADE, APP])
        self.assertTrue(self.run_probe(device)["readable_accessibility"])
        self.assertEqual(self.statusbar_actions, ["expand-notifications", "collapse"])

    def test_offline_device_never_interacts(self):
        device = self.device([])
        with self.assertRaisesRegex(ValueError, "online"):
            self.run_probe(device, "offline")
        self.assertEqual(self.statusbar_actions, [])

    def test_existing_anr_is_left_intact(self):
        device = self.device([ANR])
        with self.assertRaises(ValueError):
            self.run_probe(device)
        self.assertEqual(self.statusbar_actions, [])

    def test_anr_during_shade_is_left_intact(self):
        device = self.device([APP, ANR])
        with self.assertRaisesRegex(ValueError, "preserve dialog"):
            self.run_probe(device)
        self.assertEqual(self.statusbar_actions, ["expand-notifications"])

    def test_unresponsive_shade_blocks(self):
        device = self.device([APP, APP])
        with patch("native_ready.time.monotonic", side_effect=[0, 0, 0, 11]), \
                self.assertRaisesRegex(ValueError, "transition"):
            self.run_probe(device)
        self.assertEqual(self.statusbar_actions, ["expand-notifications"])

    def test_missing_or_busy_host_blocks_before_device(self):
        with patch("native_ready.local_json", return_value={"status": "running"}), \
                patch("native_ready.probe_device") as device:
            with self.assertRaises(ValueError):
                native_ready.probe("offline-fake-device", "TC-03")
            device.assert_not_called()

    def test_only_new_anr_interrupts_an_admitted_run(self):
        child = Mock()
        child.wait.return_value = 0
        with TemporaryDirectory() as tmp:
            output = Path(tmp)
            for timestamp in (99, 101):
                event = SimpleNamespace(stdout=f"{timestamp}.01 569 200 I am_anr: BeeWise\n")
                with patch("batch_once.subprocess.run", return_value=event):
                    if timestamp < 100:
                        self.assertEqual(wait_case(child, "offline-fake-device", 100, output), 0)
                        self.assertFalse((output/"during-run-anr.txt").exists())
                    else:
                        with self.assertRaisesRegex(RuntimeError, "New Android ANR"):
                            wait_case(child, "offline-fake-device", 100, output)
                        self.assertIn("101.01", (output/"during-run-anr.txt").read_text())


if __name__ == "__main__":
    unittest.main()
