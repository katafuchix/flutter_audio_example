import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    //private var audioPlayer: AVAudioPlayer? // プロパティとして定義
    private var audioSession: AVAudioSession? // プロパティとして定義
    
    //private var audioPlayer: AVPlayer? // AVPlayer を使用
    var audioPlayer: AVAudioPlayer?
    
    var audioEngine: AVAudioEngine?
    var playerNode: AVAudioPlayerNode?
    var audioFile: AVAudioFile?
    var tempURL: URL?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {


      let controller = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(name: "speaker_control", binaryMessenger: controller.binaryMessenger)



      if #available(iOS 13.0, *) {
              
          channel.setMethodCallHandler { [weak self] call, result in
            guard call.method == "playAudioWithSpeaker" else {
              result(FlutterMethodNotImplemented)
              return
            }

            guard let args = call.arguments as? [String: Any],
                  let useSpeaker = args["useSpeaker"] as? Bool,
                  let urlString = args["url"] as? String,
                  let url = URL(string: urlString) else {
              result(FlutterError(code: "invalid_args", message: "引数が不正です", details: nil))
              return
            }

            print("🎛 スピーカーモードに切替リクエストを受信: useSpeaker = \(useSpeaker)")

            // mp3のデータがまだない場合のみダウンロード
            if self?.audioFile == nil {
              URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                  result(FlutterError(code: "download_error", message: "音声取得失敗", details: error.localizedDescription))
                  return
                }

                guard let data = data else {
                  result(FlutterError(code: "no_data", message: "音声データが空", details: nil))
                  return
                }

                DispatchQueue.main.async {
                  do {
                    self?.tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp.mp3")
                    try data.write(to: self!.tempURL!)
                    self?.audioFile = try AVAudioFile(forReading: self!.tempURL!)
                    print("📁 音声ファイルを初回取得＆保存")
                    self?.play(useSpeaker: useSpeaker, result: result)
                  } catch {
                    result(FlutterError(code: "file_error", message: "保存または読み込み失敗", details: error.localizedDescription))
                  }
                }
              }.resume()
            } else {
              print("♻️ 音声ファイルを再利用")
              self?.play(useSpeaker: useSpeaker, result: result)
            }
          }
      }

      /*
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
*/
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    private func play(useSpeaker: Bool, result: @escaping FlutterResult) {
      guard let audioFile = self.audioFile else {
        result(FlutterError(code: "file_missing", message: "音声ファイルが未ロード", details: nil))
        return
      }

      // 🔽 再生位置を保存（フレーム単位）
      var startFrame: AVAudioFramePosition = 0
      if let currentPlayer = self.playerNode,
         let nodeTime = currentPlayer.lastRenderTime,
         let playerTime = currentPlayer.playerTime(forNodeTime: nodeTime) {
        startFrame = playerTime.sampleTime
        print("⏱ 再生位置保存: frame = \(startFrame)")
      }

      do {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [])
        try session.setActive(true, options: [])
        try session.overrideOutputAudioPort(useSpeaker ? .speaker : .none)

        let route = session.currentRoute
        for output in route.outputs {
          print("🔈 Output Route: \(output.portType.rawValue) (\(output.portName))")
        }

        self.audioEngine?.stop()
        self.audioEngine = AVAudioEngine()
        self.playerNode = AVAudioPlayerNode()

        guard let engine = self.audioEngine,
              let player = self.playerNode else {
          result(FlutterError(code: "engine_error", message: "AudioEngine初期化失敗", details: nil))
          return
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: audioFile.processingFormat)

        // 🔽 出力ルート強制のためのマイク入力接続
        let input = engine.inputNode
        engine.connect(input, to: engine.mainMixerNode, format: input.inputFormat(forBus: 0))

        try engine.start()
        print("🎧 Engine isRunning: \(engine.isRunning)")

        let totalFrames = audioFile.length
        let framesToPlay = totalFrames - startFrame

        // 🔽 スケジュール再生（startFrame から）
        player.scheduleSegment(
          audioFile,
          startingFrame: startFrame,
          frameCount: AVAudioFrameCount(framesToPlay),
          at: nil,
          completionHandler: {
            print("✅ 再生完了")
          }
        )

        player.play()
        print("▶️ 再生再開: frame = \(startFrame)")

        result(nil)

      } catch {
        result(FlutterError(code: "playback_error", message: "再生失敗", details: error.localizedDescription))
      }
    }

    
  /*
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
    */
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
