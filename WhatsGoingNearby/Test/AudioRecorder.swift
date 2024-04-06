//
//  AudioRecorder.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 06/04/24.
//

import SwiftUI
import AVFoundation

struct AudioRecorder: View {
    
    @State var audioRecorder: AVAudioRecorder?
    
    var body: some View {
        VStack {
            Button("Start Recording") {
                do {
                    try setupAudioSession()
                    try setupRecorder()
                    startRecording()
                } catch {
                    print(error)
                }
            }
            
            Button("Stop") {
                stopRecording()
            }
        }
        .onAppear {
            requestRecordPermission()
        }
    }
    
    //MARK: - Private Method
    
    func startRecording() {
        audioRecorder?.record()
    }

    func stopRecording() {
        audioRecorder?.stop()
    }
    
    private func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                // Permission granted
            } else {
                // Handle permission denied
            }
        }
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
    }
    
    func setupRecorder() throws {
        let recordingSettings = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue] as [String : Any]
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("recording.m4a")
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: recordingSettings)
        audioRecorder?.prepareToRecord()
    }
}

#Preview {
    AudioRecorder()
}
