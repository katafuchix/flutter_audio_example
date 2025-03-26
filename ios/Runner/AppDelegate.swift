import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    //private var audioPlayer: AVAudioPlayer? // プロパティとして定義
    private var audioSession: AVAudioSession? // プロパティとして定義
    
    private var audioPlayer: AVPlayer? // AVPlayer を使用
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
      let controller = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(name: "com.example.audio/mode", binaryMessenger: controller.binaryMessenger)

      channel.setMethodCallHandler { [weak self] call, result in
          guard let self = self else { return }
          switch call.method {
          case "playAudio":
              if let args = call.arguments as? [String: Any],
                 let urlString = args["url"] as? String {
                  self.playAudio(urlString: urlString, result: result)
              } else {
                  result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for playAudio", details: nil))
              }
          case "stopAudio":
              self.stopAudio(result: result)
          case "setSpeakerMode":
              if let args = call.arguments as? [String: Any],
                 let speakerMode = args["speaker"] as? Bool {
                  self.setSpeakerMode(speakerMode: speakerMode, result: result)
              } else {
                  result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for setSpeakerMode", details: nil))
              }
          default:
              result(FlutterMethodNotImplemented)
          }
      }

      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
    private func playAudio(urlString: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid audio URL", details: nil))
            return
        }

        do {
            // AVAudioSessionの設定を明示的に行い、スピーカーを無効化
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playAndRecord, options: [])
            try audioSession?.setMode(.default)
            try audioSession?.setActive(true)

            // AVPlayerの初期化と再生
            audioPlayer = AVPlayer(url: url)
            audioPlayer?.play()
            result("Audio playback started")
        } catch {
            result(FlutterError(code: "PLAYBACK_ERROR", message: "Failed to play audio: \(error.localizedDescription)", details: nil))
        }
    }

    private func stopAudio(result: @escaping FlutterResult) {
        audioPlayer?.pause()
        audioPlayer = nil
        result("Audio playback stopped")
    }

    private func setSpeakerMode(speakerMode: Bool, result: @escaping FlutterResult) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)

            if speakerMode {
                try session.overrideOutputAudioPort(.speaker)
            } else {
                try session.overrideOutputAudioPort(.none)
            }

            result("Speaker mode set to \(speakerMode)")
        } catch {
            result(FlutterError(code: "SPEAKER_MODE_ERROR", message: "Failed to set speaker mode: \(error.localizedDescription)", details: nil))
        }
    }
    
    /*
    private func setSpeakerMode(speakerMode: Bool, result: @escaping FlutterResult) {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playAndRecord, options: speakerMode ? .defaultToSpeaker : [])
            try audioSession?.setActive(true)
            result("Speaker mode set to \(speakerMode)")
        } catch {
            result(FlutterError(code: "SPEAKER_MODE_ERROR", message: "Failed to set speaker mode: \(error.localizedDescription)", details: nil))
        }
    }*/
}


/*
    private func playAudio(urlString: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid audio URL", details: nil))
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            result("Audio playback started")
        } catch {
            result(FlutterError(code: "PLAYBACK_ERROR", message: "Failed to play audio: \(error.localizedDescription)", details: nil))
        }
    }

    private func stopAudio(result: @escaping FlutterResult) {
        audioPlayer?.stop()
        audioPlayer = nil
        result("Audio playback stopped")
    }
*/
