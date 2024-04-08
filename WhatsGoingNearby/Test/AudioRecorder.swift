import SwiftUI
import AVFoundation

struct RecordingView: View {
    @State private var isRecording = false
    @State private var recordings = [URL]()
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(0..<recordings.count, id: \.self) { index in
                        Button(action: {
                            self.playAudio(url: self.recordings[index])
                        }) {
                            Text("Audio \(index + 1)")
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    if self.isRecording {
                        self.stopRecording()
                    } else {
                        self.startRecording()
                    }
                }) {
                    Text(self.isRecording ? "Parar Gravação" : "Iniciar Gravação")
                        .foregroundColor(.white)
                        .padding()
                        .background(self.isRecording ? Color.red : Color.blue)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationBarTitle("Gravador de Áudio")
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording\(recordings.count + 1).m4a")
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            self.audioRecorder = audioRecorder
            self.isRecording = true
        } catch {
            print("Erro ao iniciar a gravação: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        if let audioRecorder = self.audioRecorder {
            audioRecorder.stop()
            self.recordings.append(audioRecorder.url)
            self.isRecording = false
        }
    }
    
    func playAudio(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.play()
        } catch {
            print("Erro ao reproduzir áudio: \(error.localizedDescription)")
        }
    }

}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}
