package com.umkm.mobilepos

import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private val TAG = "MobilePosImagePicker"
    private val CHANNEL = "com.umkm.mobilepos/image_picker"
    private val PICK_IMAGE_REQUEST = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> {
                    pendingResult = result
                    Log.d(TAG, "pickImage called")
                    pickImage()
                }
                "listImages" -> {
                    try {
                        result.success(listImages())
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to list images", e)
                        result.error("LIST_FAILED", "Failed to list images", e.message)
                    }
                }
                "copyImageUri" -> {
                    try {
                        val uriString = call.argument<String>("uri")
                        if (uriString.isNullOrEmpty()) {
                            result.error("NO_URI", "No image URI provided", null)
                            return@setMethodCallHandler
                        }
                        result.success(copyImageToAppStorage(Uri.parse(uriString)))
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to copy image URI", e)
                        result.error("COPY_FAILED", "Failed to copy selected image", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pickImage() {
        val mediaStoreIntent = Intent(
            Intent.ACTION_PICK,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        ).apply {
            type = "image/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        if (mediaStoreIntent.resolveActivity(packageManager) != null) {
            Log.d(TAG, "Opening MediaStore ACTION_PICK")
            startActivityForResult(mediaStoreIntent, PICK_IMAGE_REQUEST)
            return
        }

        Log.d(TAG, "Opening ACTION_GET_CONTENT fallback")
        val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(
            Intent.createChooser(fallbackIntent, "Pilih Gambar"),
            PICK_IMAGE_REQUEST
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == PICK_IMAGE_REQUEST) {
            Log.d(TAG, "onActivityResult resultCode=$resultCode data=${data != null}")
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    Log.d(TAG, "Selected uri=$uri")
                    try {
                        val path = copyImageToAppStorage(uri)
                        persistReadPermissionIfAvailable(uri, data.flags)
                        Log.d(TAG, "Image copied to $path")
                        pendingResult?.success(path)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to copy selected image", e)
                        pendingResult?.error("COPY_FAILED", "Failed to copy selected image", e.message)
                    }
                } else {
                    Log.e(TAG, "No image URI returned")
                    pendingResult?.error("NO_IMAGE", "No image selected", null)
                }
            } else {
                Log.d(TAG, "Image selection cancelled")
                pendingResult?.error("CANCELLED", "Image selection cancelled", null)
            }
            pendingResult = null
        }
    }

    private fun persistReadPermissionIfAvailable(uri: Uri, flags: Int) {
        val takeFlags = flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        if (takeFlags == 0) return

        try {
            contentResolver.takePersistableUriPermission(uri, takeFlags)
        } catch (_: Exception) {
            // The image has already been copied into app storage, so this is optional.
        }
    }

    private fun copyImageToAppStorage(uri: Uri): String {
        val imagesDir = File(filesDir, "product_images")
        if (!imagesDir.exists()) {
            imagesDir.mkdirs()
        }

        val destFile = File(imagesDir, "image_${System.currentTimeMillis()}.jpg")
        contentResolver.openInputStream(uri).use { input ->
            if (input == null) {
                throw IllegalStateException("Cannot open selected image")
            }
            destFile.outputStream().use { output ->
                input.copyTo(output)
            }
        }
        return destFile.absolutePath
    }

    private fun listImages(): List<Map<String, Any?>> {
        val collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATE_ADDED
        )
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"
        val images = mutableListOf<Map<String, Any?>>()

        contentResolver.query(collection, projection, null, null, sortOrder)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
            val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)

            while (cursor.moveToNext() && images.size < 120) {
                val id = cursor.getLong(idColumn)
                val uri = ContentUris.withAppendedId(collection, id)
                val thumbnail = loadThumbnailBytes(uri, id)
                if (thumbnail != null) {
                    images.add(
                        mapOf(
                            "uri" to uri.toString(),
                            "name" to cursor.getString(nameColumn),
                            "dateAdded" to cursor.getLong(dateColumn),
                            "thumbnail" to thumbnail
                        )
                    )
                }
            }
        }

        return images
    }

    private fun loadThumbnailBytes(uri: Uri, id: Long): ByteArray? {
        return try {
            val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentResolver.loadThumbnail(uri, Size(180, 180), null)
            } else {
                @Suppress("DEPRECATION")
                MediaStore.Images.Thumbnails.getThumbnail(
                    contentResolver,
                    id,
                    MediaStore.Images.Thumbnails.MINI_KIND,
                    null
                )
            }
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 72, stream)
                stream.toByteArray()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load thumbnail for $uri", e)
            null
        }
    }
}
