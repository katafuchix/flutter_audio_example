package com.example.flutter_audio_example

import android.content.Context
import android.content.Context.*
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import io.flutter.embedding.android.FlutterActivity
import android.media.AudioManager
import android.media.AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.audio/mode"
    private var mediaPlayer: MediaPlayer? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var audioManager: AudioManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playAudio" -> {
                    val url = call.argument<String>("url") ?: ""
                    playAudio(url)
                    result.success("Audio playback started")
                }

                "stopAudio" -> {
                    stopAudio()
                    result.success("Audio playback stopped")
                }

                "setSpeakerMode" -> {
                    val speakerMode = call.argument<Boolean>("speaker") ?: false
                    setSpeakerMode(speakerMode)
                    result.success("Speaker mode set to $speakerMode")
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun playAudio(url: String) {
        stopAudio() // 再生中の場合は停止
        mediaPlayer = MediaPlayer().apply {
            setDataSource(url)
            setAudioStreamType(AudioManager.STREAM_MUSIC)
            prepare()
            start()
        }
    }

    private fun stopAudio() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    private fun setSpeakerMode(speakerMode: Boolean) {
        Log.d("SOUND", speakerMode.toString())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audioManager?.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            val targetDevice = if (speakerMode) {
                devices?.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            } else {
                devices?.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE || it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET }
            }

            Log.d("SOUND", targetDevice.toString())

            if (targetDevice != null) {
                audioManager?.setCommunicationDevice(targetDevice)
            } else {
                Log.e("AudioMode", "No suitable audio device found")
            }
        } else {
            audioManager?.mode = AudioManager.MODE_IN_COMMUNICATION
            audioManager?.isSpeakerphoneOn = speakerMode
        }
    }
}
