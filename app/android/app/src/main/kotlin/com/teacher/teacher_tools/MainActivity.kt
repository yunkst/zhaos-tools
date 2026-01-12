package com.teacher.teacher_tools

import android.content.Intent
import android.net.Uri
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.teacher_tools/file_receiver"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 设置 MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        // 处理冷启动时传入的 Intent
        intent?.let { handleIntent(it) }
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type

        // 支持新旧 Excel 格式
        val isExcelFile = when (type) {
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" -> true  // .xlsx
            "application/vnd.ms-excel" -> true  // .xls
            else -> false
        }

        if ((action == Intent.ACTION_VIEW || action == Intent.ACTION_SEND) && isExcelFile) {

            val fileUri: Uri? = when (action) {
                Intent.ACTION_VIEW -> intent.data
                Intent.ACTION_SEND -> {
                    val clipData = intent.clipData
                    if (clipData != null && clipData.itemCount > 0) {
                        clipData.getItemAt(0).uri
                    } else {
                        intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                    }
                }
                else -> null
            }

            fileUri?.let { uri ->
                val filePath = getRealPathFromURI(uri)
                if (filePath != null) {
                    // 通知 Flutter 层接收到文件
                    methodChannel?.invokeMethod("onFileReceived", filePath)
                }
            }
        }
    }

    private fun getRealPathFromURI(uri: Uri): String? {
        return try {
            // 对于 file:// 格式的 URI
            if (uri.scheme == "file") {
                uri.path
            } else {
                // 对于 content:// 格式的 URI，复制到临时目录
                val inputStream = contentResolver.openInputStream(uri)
                val tempFile = File(cacheDir, "received_${System.currentTimeMillis()}.xlsx")
                inputStream?.use { input ->
                    tempFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                tempFile.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
