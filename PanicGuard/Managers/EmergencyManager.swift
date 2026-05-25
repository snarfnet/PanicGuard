import Foundation
import AVFoundation
import CoreLocation
import UIKit
import CoreMotion

class EmergencyManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isAlertActive = false
    @Published var isRecording = false
    @Published var isFakeCallScheduled = false
    @Published var fakeCallActive = false
    @Published var currentLocation: CLLocation?
    @Published var locationAuthorized = false
    @Published var alertMode: AlertMode = .both
    @Published var shakeToActivate = true
    @Published var contacts: [EmergencyContact] = []
    @Published var fakeCallProfile = FakeCallProfile()
    @Published var recordingDuration: TimeInterval = 0

    private let locationManager = CLLocationManager()
    private var sirenPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var flashTimer: Timer?
    private var fakeCallTimer: Timer?
    private var recordingTimer: Timer?
    private let motionManager = CMMotionManager()
    private var pendingLocationRequest = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        loadContacts()
        loadSettings()
    }

    // MARK: - Location
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationAuthorized = true
            startLocationTracking()
        default:
            locationAuthorized = false
        }
    }

    func startLocationTracking() {
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            pendingLocationRequest = true
            locationManager.requestWhenInUseAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }

    /// Request a one-shot location for SOS message
    func requestCurrentLocation() {
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            pendingLocationRequest = true
            locationManager.requestWhenInUseAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
            pendingLocationRequest = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[PanicGuard] Location error: \(error.localizedDescription)")
        // If location fails, try requestLocation as fallback
        if let clError = error as? CLError, clError.code == .denied {
            DispatchQueue.main.async { self.locationAuthorized = false }
        }
    }

    // MARK: - Panic Alert
    func activateAlert() {
        guard !isAlertActive else { return }
        isAlertActive = true
        startLocationTracking()

        switch alertMode {
        case .siren:
            startSiren()
        case .flash:
            startFlash()
        case .both:
            startSiren()
            startFlash()
        case .silent:
            // Silent mode - just record and send location
            break
        }

        // Auto-record in all modes
        startRecording()

        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func deactivateAlert() {
        isAlertActive = false
        stopSiren()
        stopFlash()
        stopRecording()
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Siren
    private func startSiren() {
        stopSiren()

        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        guard let engine = audioEngine, let player = playerNode else { return }

        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let frameCount = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }

        buffer.frameLength = AVAudioFrameCount(frameCount)
        let data = buffer.floatChannelData![0]

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            // Two-tone siren: alternating high and low
            let freq = progress < 0.5 ? 880.0 + progress * 1200 : 2080.0 - (progress - 0.5) * 1200
            data[i] = Float(sin(2 * .pi * freq * t) * 0.9)
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            // Max volume
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            try engine.start()
            player.play()
            // Loop the buffer
            player.scheduleBuffer(buffer, at: nil, options: .loops)
        } catch {}
    }

    private func stopSiren() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
    }

    // MARK: - Flash
    private func startFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        var isOn = false
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            do {
                try device.lockForConfiguration()
                if isOn {
                    device.torchMode = .off
                } else {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                }
                device.unlockForConfiguration()
                isOn.toggle()
            } catch {}
        }
    }

    private func stopFlash() {
        flashTimer?.invalidate()
        flashTimer = nil
        if let device = AVCaptureDevice.default(for: .video), device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {}
        }
    }

    // MARK: - Recording
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch { return }

        let filename = "evidence_\(Int(Date().timeIntervalSince1970)).m4a"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1
            }
        } catch {}
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Emergency SMS
    func getEmergencyMessage() -> String {
        var msg = L.sos_message_header + "\n"
        if let loc = currentLocation {
            msg += L.sos_message_location + " https://maps.apple.com/?ll=\(loc.coordinate.latitude),\(loc.coordinate.longitude)\n"
        }
        msg += L.sos_message_footer
        return msg
    }

    func getEmergencySMSURL() -> URL? {
        guard let contact = contacts.first else { return nil }
        let message = getEmergencyMessage().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "sms:\(contact.phone)&body=\(message)")
    }

    // MARK: - Fake Call
    func scheduleFakeCall() {
        isFakeCallScheduled = true
        fakeCallTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(fakeCallProfile.delaySeconds), repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isFakeCallScheduled = false
                self?.fakeCallActive = true
            }
        }
    }

    func cancelFakeCall() {
        fakeCallTimer?.invalidate()
        fakeCallTimer = nil
        isFakeCallScheduled = false
        fakeCallActive = false
    }

    func endFakeCall() {
        fakeCallActive = false
    }

    // MARK: - Shake Detection
    func startShakeDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data, self.shakeToActivate, !self.isAlertActive else { return }
            let magnitude = sqrt(data.acceleration.x * data.acceleration.x +
                               data.acceleration.y * data.acceleration.y +
                               data.acceleration.z * data.acceleration.z)
            if magnitude > 3.0 {
                self.activateAlert()
            }
        }
    }

    func stopShakeDetection() {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Persistence
    private func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergency_contacts"),
           let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            contacts = decoded
        }
    }

    func saveContacts() {
        if let data = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(data, forKey: "emergency_contacts")
        }
    }

    private func loadSettings() {
        if let mode = UserDefaults.standard.string(forKey: "alert_mode"),
           let alertMode = AlertMode(rawValue: mode) {
            self.alertMode = alertMode
        }
        shakeToActivate = UserDefaults.standard.object(forKey: "shake_activate") as? Bool ?? true

        if let data = UserDefaults.standard.data(forKey: "fake_call_profile"),
           let decoded = try? JSONDecoder().decode(FakeCallProfile.self, from: data) {
            fakeCallProfile = decoded
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(alertMode.rawValue, forKey: "alert_mode")
        UserDefaults.standard.set(shakeToActivate, forKey: "shake_activate")
        if let data = try? JSONEncoder().encode(fakeCallProfile) {
            UserDefaults.standard.set(data, forKey: "fake_call_profile")
        }
    }
}
