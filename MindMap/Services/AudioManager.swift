//
//  AudioManager.swift
//  MindMap
//
//  Created by Nikita Sergyshkin on 05/08/2025.
//

import AVFoundation
import Foundation
import Combine

// MARK: - Recording State
enum RecordingState {
    case idle
    case recording
    case paused
    case finished
}

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var recordingState: RecordingState = .idle
    @Published var recordingLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var hasPermission: Bool = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        setupAudioSession()
        requestPermission()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Ошибка настройки аудио сессии: \(error)")
        }
    }
    
    private func requestPermission() {
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasPermission = granted
            }
        }
    }
    
    // MARK: - Recording
    func startRecording() -> URL? {
        guard hasPermission else {
            print("Нет разрешения на запись")
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            recordingState = .recording
            recordingDuration = 0.0
            
            startTimers()
            
            return audioFilename
        } catch {
            print("Ошибка начала записи: \(error)")
            return nil
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        recordingState = .paused
        stopTimers()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        recordingState = .recording
        startTimers()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        recordingState = .finished
        stopTimers()
    }
    
    // MARK: - Playback
    func playAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Ошибка воспроизведения: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
    }
    
    // MARK: - Timers
    private func startTimers() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateRecordingDuration()
        }
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateRecordingLevel()
        }
    }
    
    private func stopTimers() {
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        recordingTimer = nil
        levelTimer = nil
        recordingLevel = 0.0
    }
    
    private func updateRecordingDuration() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recordingDuration = recorder.currentTime
    }
    
    private func updateRecordingLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        // Нормализуем уровень от -80dB to 0dB в диапазон 0.0 to 1.0
        let normalizedLevel = max(0.0, (level + 80.0) / 80.0)
        recordingLevel = normalizedLevel
    }
    
    // MARK: - Utility
    func deleteRecording(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Ошибка удаления записи: \(error)")
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            recordingState = .finished
        } else {
            recordingState = .idle
        }
        stopTimers()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Ошибка кодирования аудио: \(error?.localizedDescription ?? "Неизвестная ошибка")")
        recordingState = .idle
        stopTimers()
    }
}