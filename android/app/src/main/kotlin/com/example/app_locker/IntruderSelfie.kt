package com.example.app_locker

import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.activity.ComponentActivity
import java.io.File

object IntruderSelfie {
    private const val DIR_NAME = "intruder_images"

    /**
     * Capture a still image from the front camera and save it inside the app's
     * private files directory. This call is silent (no UI preview).
     */
    fun capture(activity: ComponentActivity) {
        val future = ProcessCameraProvider.getInstance(activity)
        future.addListener({
            val provider = future.get()
            val selector = CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                .build()

            // Prepare output file
            val outputDir = File(activity.filesDir, DIR_NAME).apply { mkdirs() }
            val outputFile = File(outputDir, "intruder_${System.currentTimeMillis()}.jpg")

            val imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                .build()

            try {
                provider.unbindAll()
                provider.bindToLifecycle(activity, selector, imageCapture)
            } catch (ex: Exception) {
                return@addListener // binding failed
            }

            val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()
            imageCapture.takePicture(
                outputOptions,
                ContextCompat.getMainExecutor(activity),
                object : ImageCapture.OnImageSavedCallback {
                    override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                        // Successfully saved – nothing else to do.
                    }

                    override fun onError(exception: ImageCaptureException) {
                        // Ignore errors silently.
                    }
                }
            )
        }, ContextCompat.getMainExecutor(activity))
    }

    fun getImagesDir(context: android.content.Context): File =
        File(context.filesDir, DIR_NAME)
} 