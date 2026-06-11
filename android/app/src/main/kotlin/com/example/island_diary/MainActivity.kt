package com.example.island_diary

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.island_diary/file_open"
    private var pendingFilePath: String? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getPendingFile") {
                result.success(pendingFilePath)
                pendingFilePath = null
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.island_diary/huawei_motion_photo").setMethodCallHandler { call, result ->
            if (call.method == "getHuaweiMotionPhotoIds") {
                val ids = ArrayList<String>()
                try {
                    val uri = Uri.parse("content://media/external/images/media")
                    val projection = arrayOf("_id")
                    val selection = "special_file_type = 20"
                    val cursor = contentResolver.query(uri, projection, selection, null, "_id DESC")
                    cursor?.use {
                        val idColumn = it.getColumnIndexOrThrow("_id")
                        while (it.moveToNext()) {
                            val id = it.getLong(idColumn)
                            ids.add(id.toString())
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                result.success(ids)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            Thread.sleep(1000)
        } catch (e: Exception) {}
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val data: Uri? = intent.data
        if (Intent.ACTION_VIEW == action && data != null) {
            try {
                val tempFile = copyUriToTempFile(data)
                if (tempFile != null) {
                    pendingFilePath = tempFile.absolutePath
                    methodChannel?.invokeMethod("onFileReceived", pendingFilePath)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun copyUriToTempFile(uri: Uri): File? {
        try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val fileName = "temp_restore_shared.island.zip"
            val tempFile = File(cacheDir, fileName)
            if (tempFile.exists()) {
                tempFile.delete()
            }
            val outputStream = FileOutputStream(tempFile)
            val buffer = ByteArray(4096)
            var byteRead: Int
            while (inputStream.read(buffer).also { byteRead = it } != -1) {
                outputStream.write(buffer, 0, byteRead)
            }
            inputStream.close()
            outputStream.close()
            return tempFile
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}
