import Foundation

struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var phone: String

    init(id: UUID = UUID(), name: String, phone: String) {
        self.id = id
        self.name = name
        self.phone = phone
    }
}

enum AlertMode: String, CaseIterable {
    case siren = "SIREN"
    case flash = "FLASH"
    case both = "BOTH"
    case silent = "SILENT"

    var label: String {
        switch self {
        case .siren: return L.mode_siren
        case .flash: return L.mode_flash
        case .both: return L.mode_both
        case .silent: return L.mode_silent
        }
    }

    var icon: String {
        switch self {
        case .siren: return "speaker.wave.3.fill"
        case .flash: return "flashlight.on.fill"
        case .both: return "exclamationmark.shield.fill"
        case .silent: return "eye.slash.fill"
        }
    }
}

struct FakeCallProfile: Identifiable, Codable {
    let id: UUID
    var callerName: String
    var delaySeconds: Int

    init(id: UUID = UUID(), callerName: String = L.fakecall_name_placeholder, delaySeconds: Int = 30) {
        self.id = id
        self.callerName = callerName
        self.delaySeconds = delaySeconds
    }
}
