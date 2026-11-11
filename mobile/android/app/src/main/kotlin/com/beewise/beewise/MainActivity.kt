package com.beewise.beewise

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beewise/local_pdf")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val root = File(filesDir, "local-reports").canonicalFile
                    val file = File(call.arguments as? String ?: "").canonicalFile
                    val relative = file.relativeTo(root).invariantSeparatorsPath
                    if (!relative.matches(Regex("[A-Za-z0-9_-]{1,172}/beewise-report-[A-Za-z0-9]{20}[.]pdf")) || !file.isFile) {
                        result.error("missing_pdf", null, null)
                        return@setMethodCallHandler
                    }
                    val uri = FileProvider.getUriForFile(this, "$packageName.local_pdf", file)
                    startActivity(Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/pdf")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    })
                    result.success(null)
                } catch (_: ActivityNotFoundException) {
                    result.error("no_viewer", null, null)
                } catch (_: Exception) {
                    result.error("open_failed", null, null)
                }
            }
    }
}
