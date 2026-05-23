import Foundation

enum L {
    private static var isJa: Bool {
        Locale.current.language.languageCode?.identifier == "ja"
    }

    static var tab_panic: String { isJa ? "発動" : "Alert" }
    static var tab_fakecall: String { isJa ? "偽着信" : "Fake Call" }
    static var tab_settings: String { isJa ? "設定" : "Settings" }

    static var mode_siren: String { isJa ? "サイレン" : "Siren" }
    static var mode_flash: String { isJa ? "フラッシュ" : "Flash" }
    static var mode_both: String { isJa ? "全力" : "Full" }
    static var mode_silent: String { isJa ? "無音記録" : "Silent" }

    static var status_active: String { isJa ? "警告発動中" : "ALERT ACTIVE" }
    static var status_ready: String { isJa ? "撃退準備完了" : "DETERRENCE READY" }
    static var status_instruction: String {
        isJa ? "ワンタップでサイレン、フラッシュ、録音を開始。近づかせないための即応モードです。" :
        "One tap starts siren, flash, and recording. Built to make unwanted attention back off."
    }

    static var btn_panic: String { isJa ? "撃退" : "DETER" }
    static var btn_stop: String { isJa ? "停止" : "STOP" }
    static var btn_sos: String { isJa ? "SOS送信" : "SOS SMS" }
    static var btn_sos_copy: String { isJa ? "SOSコピー" : "Copy SOS" }
    static var btn_sos_copied: String { isJa ? "コピー済み" : "Copied" }
    static var btn_record: String { isJa ? "証拠録音" : "Record" }
    static var btn_stop_rec: String { isJa ? "録音停止" : "Stop Rec" }
    static var btn_sos_no_contact: String { isJa ? "SOSコピー" : "Copy SOS" }

    static var fakecall_title: String { isJa ? "偽着信" : "Fake Call" }
    static var fakecall_desc: String {
        isJa ? "着信を装って、その場を離れる口実を作ります。怪しい気配を感じたら先に予約してください。" :
        "Create a believable incoming call so you can leave the situation without drawing attention."
    }
    static var fakecall_name: String { isJa ? "発信者名" : "Caller Name" }
    static var fakecall_name_placeholder: String { isJa ? "家族" : "Family" }
    static var fakecall_delay: String { isJa ? "着信まで" : "Call After" }
    static var fakecall_scheduled: String { isJa ? "偽着信を待機中" : "Fake call armed" }
    static var fakecall_cancel: String { isJa ? "キャンセル" : "Cancel" }
    static var fakecall_start: String { isJa ? "着信を予約" : "Arm Fake Call" }
    static var fakecall_test: String { isJa ? "着信画面を確認" : "Preview call screen" }
    static var fakecall_incoming: String { isJa ? "着信中" : "Incoming Call" }
    static var fakecall_decline: String { isJa ? "拒否" : "Decline" }
    static var fakecall_answer: String { isJa ? "応答" : "Answer" }

    static var settings_title: String { isJa ? "設定" : "Settings" }
    static var settings_contacts: String { isJa ? "緊急連絡先" : "Emergency Contacts" }
    static var settings_name: String { isJa ? "名前" : "Name" }
    static var settings_phone: String { isJa ? "電話番号" : "Phone" }
    static var settings_shake: String { isJa ? "シェイク発動" : "Shake Activation" }
    static var settings_shake_toggle: String { isJa ? "振って撃退アラートを発動" : "Shake to trigger alert" }
    static var settings_shake_desc: String { isJa ? "強く振るとサイレン、フラッシュ、録音を即座に開始します。" : "A hard shake starts the emergency response immediately." }
    static var settings_tips: String { isJa ? "対処メモ" : "Safety Notes" }

    static var tip_1: String { isJa ? "明るく人通りの多い場所へ移動してください。" : "Move toward bright, populated areas." }
    static var tip_2: String { isJa ? "信頼できる人に現在地を共有してください。" : "Share your live location with someone you trust." }
    static var tip_3: String { isJa ? "危険を感じたら迷わず警察へ通報してください。" : "If you feel in danger, call emergency services immediately." }
    static var tip_4: String { isJa ? "日時、場所、相手の特徴、行動を記録してください。" : "Document times, places, descriptions, and behavior." }
    static var tip_5: String { isJa ? "違和感は無視しないでください。早めに助けを呼びましょう。" : "Do not dismiss your instincts. Ask for help early." }

    static var disclaimer: String {
        isJa ? "このアプリは個人の安全を補助するツールです。緊急時は必ず110番に通報してください。専門的な警備や警察への相談の代替ではありません。" :
        "This app supports personal safety. In a real emergency, call local emergency services. It does not replace police, legal, or professional security support."
    }

    static var sos_message_header: String { isJa ? "緊急です。助けてください。" : "EMERGENCY. I need help." }
    static var sos_message_location: String { isJa ? "現在地:" : "My location:" }
    static var sos_message_footer: String { isJa ? "PanicGuardから送信" : "Sent via PanicGuard" }
}
