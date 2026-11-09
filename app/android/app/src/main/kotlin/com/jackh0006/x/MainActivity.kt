package com.jackh0006.x

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingText: String? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingFolderResult: MethodChannel.Result? = null
    private val createDocumentRequest = 1001
    private val chooseFolderRequest = 1002

    private fun prefs() = getSharedPreferences("x", Context.MODE_PRIVATE)

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == chooseFolderRequest) {
            val result = pendingFolderResult
            pendingFolderResult = null
            val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
            if (uri == null) {
                result?.success(null)
                return
            }
            try {
                val flags = data?.flags?.and(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                ) ?: 0
                contentResolver.takePersistableUriPermission(uri, flags)
                prefs().edit().putString("export_folder_uri", uri.toString()).apply()
                result?.success(uri.toString())
            } catch (_: Exception) {
                result?.success(null)
            }
            return
        }
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
                "getTheme" -> {
                    val prefs = getSharedPreferences("x", Context.MODE_PRIVATE)
                    result.success(prefs.getString("theme_mode", "system"))
                }

                "setTheme" -> {
                    val value = call.argument<String>("theme_mode")
                    if (value == null) {
                        result.error("INVALID_ARGUMENT", "Missing theme", null)
                        return@setMethodCallHandler
                    }
                    getSharedPreferences("x", Context.MODE_PRIVATE).edit()
                        .putString("theme_mode", value).apply()
                    result.success(true)
                }

                "getExportName" -> {
                    result.success(
                        prefs().getString("export_name", "X-encrypted-message.txt")
                    )
                }

                "setExportName" -> {
                    val value = call.argument<String>("export_name")
                    if (value == null || value.isEmpty() ||
                        value.contains("/") || value.contains("\\")
                    ) {
                        result.error("INVALID_ARGUMENT", "Invalid filename", null)
                        return@setMethodCallHandler
                    }
                    prefs().edit().putString("export_name", value).apply()
                    result.success(true)
                }

                "getExportFolder" -> {
                    result.success(prefs().getString("export_folder_uri", null))
                }

                "setExportFolder" -> {
                    val value = call.argument<String>("export_folder")
                    prefs().edit().apply {
                        if (value.isNullOrEmpty()) remove("export_folder_uri")
                        else putString("export_folder_uri", value)
                    }.apply()
                    result.success(true)
                }

                "chooseExportFolder" -> {
                    if (pendingFolderResult != null) {
                        result.error("BUSY", "Another folder choice is in progress", null)
                        return@setMethodCallHandler
                    }
                    pendingFolderResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                            )
                        }
                        startActivityForResult(intent, chooseFolderRequest)
                    } catch (_: Exception) {
                        pendingFolderResult = null
                        result.error("UNAVAILABLE", "No folder provider", null)
                    }
                }

                "getStorageInfo" -> {
                    val info = mapOf(
                        "data" to (filesDir?.absolutePath ?: "Unavailable"),
                        "cache" to (cacheDir?.absolutePath ?: "Unavailable"),
                        "preferences" to
                            ((filesDir?.parentFile?.absolutePath ?: "") +
                                "/shared_prefs/x.xml"),
                        "exportFolder" to prefs().getString("export_folder_uri", null),
                        "exportName" to
                            prefs().getString("export_name", "X-encrypted-message.txt")
                    )
                    result.success(info)
                }

                "deleteAppData" -> {
                    prefs().edit().clear().apply()
                    cacheDir?.deleteRecursively()
                    filesDir?.listFiles()?.forEach { it.deleteRecursively() }
                    result.success(true)
                }

                "setSecureScreen" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }

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
                    val safeName = filename.replace("/", "_").replace("\\", "_")
                    val folder = prefs().getString("export_folder_uri", null)
                    if (folder != null) {
                        try {
                            val tree = Uri.parse(folder)
                            val parent = DocumentsContract.buildDocumentUriUsingTree(
                                tree,
                                DocumentsContract.getTreeDocumentId(tree)
                            )
                            val uri = DocumentsContract.createDocument(
                                contentResolver, parent, "text/plain", safeName
                            ) ?: throw IllegalStateException("No document")
                            contentResolver.openOutputStream(uri)?.use {
                                it.write(text.toByteArray(Charsets.UTF_8))
                            }
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                        return@setMethodCallHandler
                    }
                    pendingText = text
                    pendingResult = result
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TITLE, safeName)
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
