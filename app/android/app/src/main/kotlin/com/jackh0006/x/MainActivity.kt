package com.jackh0006.x

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingText: String? = null
    private var pendingResult: MethodChannel.Result? = null
    private val createDocumentRequest = 1001

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != createDocumentRequest) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val text = pendingText
        val result = pendingResult
        pendingText = null
        pendingResult = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null || text == null) {
            result?.success(false)
            return
        }
        try {
            contentResolver.openOutputStream(uri)?.use {
                it.write(text.toByteArray(Charsets.UTF_8))
            }
            result?.success(true)
        } catch (_: Exception) {
            result?.success(false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.jackh0006.x/native",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val text = call.argument<String>("text")
                    if (text == null) {
                        result.error("INVALID_ARGUMENT", "Missing text", null)
                        return@setMethodCallHandler
                    }
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    startActivity(Intent.createChooser(send, "Share encrypted text"))
                    result.success(true)
                }

                "saveText" -> {
                    val text = call.argument<String>("text")
                    val filename = call.argument<String>("filename")
                        ?: "X-encrypted-message.txt"
                    if (text == null) {
                        result.error("INVALID_ARGUMENT", "Missing text", null)
                        return@setMethodCallHandler
                    }
                    if (pendingResult != null) {
                        result.error("BUSY", "Another save is in progress", null)
                        return@setMethodCallHandler
                    }
                    pendingText = text
                    pendingResult = result
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TITLE, filename)
                        }
                        startActivityForResult(intent, createDocumentRequest)
                    } catch (_: Exception) {
                        pendingText = null
                        pendingResult = null
                        result.error("UNAVAILABLE", "No document provider", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
