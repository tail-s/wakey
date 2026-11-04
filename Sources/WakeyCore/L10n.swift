import Foundation

/// Languages Wakey can show, picked in Settings independently of macOS.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case korean = "ko"
    case japanese = "ja"

    public var id: String { rawValue }

    /// Shown in the language picker in its own language.
    public var nativeName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        }
    }
}

public enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    public var id: String { rawValue }
}

public enum L10nKey: String, CaseIterable, Sendable {
    // Menu panel
    case title, heroOff, heroIdle, heroRemote, heroWorkingFormat
    case activeNow, nothing, holdIdle, holdDisplay, holdLid
    case reasonAutoOff, reasonIdle, reasonPausedOnBattery, reasonBatteryFloor
    case reasonRemoteStandby, reasonClamshell, reasonLidAway, reasonNormal
    case lidNeedsHelper, lidTooHot
    case lidSection, situationLidOpenAC, situationLidOpenBattery, situationClamshell, situationLidClosedNoDisplay
    case lidAwayTitle, lidAwaySubtitle
    case timer, timer30, timer60, timer120, timerAlways, timerUntilOff, timerMinutesLeftFormat
    case stepAway
    case powerACBatteryFormat, powerAC, powerBatteryFormat
    case lidClosedExternal, lidOpenExternal, lidOpenNoExternal
    case detectedWorkingFormat, detectedNone, blockingFormat
    case keepOnBatteryFormat, remoteStandby
    case advanced, advancedNote
    case manualIdle, manualIdleSubtitle, manualDisplay, manualDisplaySubtitle, manualLid, manualLidSubtitle
    case openSettings, quit

    // Settings window
    case settingsTitle, tabGeneral, tabDetection, tabAbout
    case sectionLanguage, language, appearance, appearanceSystem, appearanceLight, appearanceDark, appearanceNote
    case sectionBehavior, launchAtLogin, launchAtLoginFailed
    case remoteStandbySettings, remoteStandbySubtitle, releaseAfter, minutesFormat, batteryFloor
    case sectionLid, helper, helperSubtitle, helperReady, helperNotInstalled, helperNeedsApproval, helperUnavailable
    case helperInstall, helperUninstall, helperOpenLoginItems
    case clamshellAuto, clamshellAutoSubtitle, thermalGuard
    case sectionApps, appClaude, appChatGPT, appAntigravity, appTerminal
    case signalClaude, signalChatGPT, signalAntigravity, signalTerminal
    case statusWorking, statusIdle, statusNotRunning
    case claudeHooks, claudeHooksSubtitle, claudeHooksOn, claudeHooksAdd, claudeHooksRemove
    case detectionNote
    case versionFormat, whatsNew, whatsNew1, whatsNew2, whatsNew3, openChangelog, openReadme
    case terminalAgentName
}

public enum L10n {
    public static func string(_ key: L10nKey, _ language: AppLanguage) -> String {
        table(for: language)[key] ?? english[key] ?? key.rawValue
    }

    public static func format(_ key: L10nKey, _ language: AppLanguage, _ arguments: CVarArg...) -> String {
        String(format: string(key, language), locale: Locale(identifier: language.rawValue), arguments: arguments)
    }

    public static func table(for language: AppLanguage) -> [L10nKey: String] {
        switch language {
        case .english: return english
        case .korean: return korean
        case .japanese: return japanese
        }
    }

    static let english: [L10nKey: String] = [
        .title: "Stay awake while AI works",
        .heroOff: "Off · macOS sleeps as usual",
        .heroIdle: "No AI is working",
        .heroRemote: "Remote standby",
        .heroWorkingFormat: "%@ working",
        .activeNow: "Active now:",
        .nothing: "Nothing",
        .holdIdle: "Sleep block",
        .holdDisplay: "Screen on",
        .holdLid: "Lid mode",
        .reasonAutoOff: "Auto is off. Only switches under Advanced apply.",
        .reasonIdle: "No AI is working, so the Mac may sleep.",
        .reasonPausedOnBattery: "Paused on battery. Turn on “Keep on battery” below.",
        .reasonBatteryFloor: "The battery is low, so Wakey let go.",
        .reasonRemoteStandby: "Remote standby. The screen sleeps, but the Mac stays reachable.",
        .reasonClamshell: "Clamshell detected, so lid mode is on. Turning off the monitor won’t sleep the Mac.",
        .reasonLidAway: "Keeps going with the lid closed. Sleeps right after the work ends.",
        .reasonNormal: "The screen may turn off and lock. Work keeps running.",
        .lidNeedsHelper: "Lid mode needs the helper. Install it in Settings.",
        .lidTooHot: "Lid mode is off because the Mac is hot.",
        .lidSection: "Lid",
        .situationLidOpenAC: "Open · power adapter",
        .situationLidOpenBattery: "Open · battery",
        .situationClamshell: "Closed · external display",
        .situationLidClosedNoDisplay: "Closed · no display",
        .lidAwayTitle: "Keep going with the lid closed and no display",
        .lidAwaySubtitle: "Sleeps when the work ends · may get warm",
        .timer: "Timer",
        .timer30: "30 min",
        .timer60: "1 hr",
        .timer120: "2 hr",
        .timerAlways: "Always",
        .timerUntilOff: "until turned off",
        .timerMinutesLeftFormat: "%d min left",
        .stepAway: "Turn off screen and step away",
        .powerACBatteryFormat: "Power adapter · battery %d%%",
        .powerAC: "Power adapter",
        .powerBatteryFormat: "Battery · %d%%",
        .lidClosedExternal: "Lid closed · external display connected",
        .lidOpenExternal: "Lid open · external display connected",
        .lidOpenNoExternal: "Lid open · no external display",
        .detectedWorkingFormat: "Detected: %@ working",
        .detectedNone: "Detected: no AI working",
        .blockingFormat: "Blocking sleep: %@",
        .keepOnBatteryFormat: "Keep on battery (down to %d%%)",
        .remoteStandby: "Stay awake between tasks (remote access)",
        .advanced: "Advanced",
        .advancedNote: "These stay on no matter what Auto decides.",
        .manualIdle: "Prevent sleep",
        .manualIdleSubtitle: "The screen may turn off; the Mac keeps running",
        .manualDisplay: "Keep screen on",
        .manualDisplaySubtitle: "Blocks the screen saver and display sleep",
        .manualLid: "Stay awake with lid closed",
        .manualLidSubtitle: "No display or power needed · may get warm",
        .openSettings: "Settings…",
        .quit: "Quit Wakey",

        .settingsTitle: "Wakey Settings",
        .tabGeneral: "General",
        .tabDetection: "Detection",
        .tabAbout: "About",
        .sectionLanguage: "Language & appearance",
        .language: "Language",
        .appearance: "Appearance",
        .appearanceSystem: "System",
        .appearanceLight: "Light",
        .appearanceDark: "Dark",
        .appearanceNote: "System follows your macOS setting.",
        .sectionBehavior: "Behavior",
        .launchAtLogin: "Launch at login",
        .launchAtLoginFailed: "Couldn’t change the login item. Move Wakey to Applications and try again.",
        .remoteStandbySettings: "Stay awake between tasks",
        .remoteStandbySubtitle: "Keeps the Mac reachable for remote access. The screen still sleeps.",
        .releaseAfter: "Release after AI finishes",
        .minutesFormat: "%d min",
        .batteryFloor: "Stop on battery below",
        .sectionLid: "Lid mode",
        .helper: "Helper",
        .helperSubtitle: "Needs your approval once in System Settings",
        .helperReady: "Installed",
        .helperNotInstalled: "Not installed",
        .helperNeedsApproval: "Waiting for approval",
        .helperUnavailable: "Not available in this build",
        .helperInstall: "Install…",
        .helperUninstall: "Uninstall",
        .helperOpenLoginItems: "Open Login Items…",
        .clamshellAuto: "Turn on automatically in clamshell",
        .clamshellAutoSubtitle: "Turning off the monitor won’t sleep the Mac",
        .thermalGuard: "Turn off when the Mac gets hot",
        .sectionApps: "Watch these apps",
        .appClaude: "Claude",
        .appChatGPT: "ChatGPT (Codex)",
        .appAntigravity: "Antigravity",
        .appTerminal: "Terminal agents (claude, codex)",
        .signalClaude: "App signal, plus exact start and finish signals with Claude Code hooks",
        .signalChatGPT: "App signal",
        .signalAntigravity: "Estimated from activity",
        .signalTerminal: "Process activity",
        .statusWorking: "Working",
        .statusIdle: "Idle",
        .statusNotRunning: "Not running",
        .claudeHooks: "Claude Code signals",
        .claudeHooksSubtitle: "Adds start and finish hooks to ~/.claude/settings.json. A backup is kept.",
        .claudeHooksOn: "Added",
        .claudeHooksAdd: "Add",
        .claudeHooksRemove: "Remove",
        .detectionNote: "Wakey only checks app status. It never reads your prompts or code.",
        .versionFormat: "Version %@",
        .whatsNew: "What’s new",
        .whatsNew1: "Auto mode keeps the Mac awake only while AI works",
        .whatsNew2: "Lid mode keeps going with the lid closed",
        .whatsNew3: "English, Korean, Japanese and dark mode",
        .openChangelog: "Full changelog",
        .openReadme: "README",
        .terminalAgentName: "Terminal agent"
    ]

    static let korean: [L10nKey: String] = [
        .title: "AI가 일하는 동안 깨어 있기",
        .heroOff: "꺼짐 · macOS 기본 설정대로 잠듦",
        .heroIdle: "작업 중인 AI 없음",
        .heroRemote: "원격 대기 중",
        .heroWorkingFormat: "%@ 작업 중",
        .activeNow: "지금 켜진 것:",
        .nothing: "없음",
        .holdIdle: "잠자기 방지",
        .holdDisplay: "화면 켜두기",
        .holdLid: "덮개 모드",
        .reasonAutoOff: "자동이 꺼져 있어요. 고급에서 직접 켠 것만 적용돼요.",
        .reasonIdle: "작업 중인 AI가 없어 잠자기를 허용해요.",
        .reasonPausedOnBattery: "배터리 사용 중이라 멈췄어요. 아래에서 ‘배터리에서도 유지’를 켜세요.",
        .reasonBatteryFloor: "배터리가 부족해서 Wakey가 해제했어요.",
        .reasonRemoteStandby: "원격 대기 중이에요. 화면은 꺼져도 Mac에 계속 접속할 수 있어요.",
        .reasonClamshell: "클램쉘을 감지해서 덮개 모드도 켰어요. 모니터를 꺼도 잠들지 않아요.",
        .reasonLidAway: "덮개를 닫아도 계속돼요. 작업이 끝나면 바로 잠들어요.",
        .reasonNormal: "화면은 꺼지고 잠겨도 작업은 계속돼요.",
        .lidNeedsHelper: "덮개 모드에는 도우미가 필요해요. 설정에서 설치하세요.",
        .lidTooHot: "Mac이 뜨거워서 덮개 모드를 껐어요.",
        .lidSection: "덮개",
        .situationLidOpenAC: "열림 · 전원 어댑터",
        .situationLidOpenBattery: "열림 · 배터리",
        .situationClamshell: "닫힘 · 외장 모니터",
        .situationLidClosedNoDisplay: "닫힘 · 모니터 없음",
        .lidAwayTitle: "모니터 없이 덮개 닫고도 계속",
        .lidAwaySubtitle: "작업이 끝나면 잠자기 · 발열 주의",
        .timer: "타이머",
        .timer30: "30분",
        .timer60: "1시간",
        .timer120: "2시간",
        .timerAlways: "계속",
        .timerUntilOff: "끌 때까지 유지",
        .timerMinutesLeftFormat: "%d분 남음",
        .stepAway: "화면 끄고 자리 비움",
        .powerACBatteryFormat: "전원 어댑터 · 배터리 %d%%",
        .powerAC: "전원 어댑터",
        .powerBatteryFormat: "배터리 · %d%%",
        .lidClosedExternal: "덮개 닫힘 · 외장 모니터 연결",
        .lidOpenExternal: "덮개 열림 · 외장 모니터 연결",
        .lidOpenNoExternal: "덮개 열림 · 외장 모니터 없음",
        .detectedWorkingFormat: "감지됨: %@ 작업 중",
        .detectedNone: "감지됨: 작업 중인 AI 없음",
        .blockingFormat: "잠자기를 막는 중: %@",
        .keepOnBatteryFormat: "배터리에서도 유지 (%d%%까지)",
        .remoteStandby: "AI가 쉴 때도 깨어 있기 (원격 접속용)",
        .advanced: "고급",
        .advancedNote: "켜면 자동 판단과 상관없이 계속 유지돼요.",
        .manualIdle: "잠자기 방지",
        .manualIdleSubtitle: "화면은 꺼져도 Mac은 계속 동작",
        .manualDisplay: "화면 켜두기",
        .manualDisplaySubtitle: "화면 보호기와 디스플레이 꺼짐 막기",
        .manualLid: "덮개 닫아도 깨어 있기",
        .manualLidSubtitle: "외장 모니터·전원 없이도 동작 · 발열 주의",
        .openSettings: "설정…",
        .quit: "Wakey 종료",

        .settingsTitle: "Wakey 설정",
        .tabGeneral: "일반",
        .tabDetection: "감지",
        .tabAbout: "정보",
        .sectionLanguage: "언어와 화면",
        .language: "언어",
        .appearance: "화면 모드",
        .appearanceSystem: "시스템",
        .appearanceLight: "라이트",
        .appearanceDark: "다크",
        .appearanceNote: "시스템은 macOS 설정을 따라요.",
        .sectionBehavior: "동작",
        .launchAtLogin: "로그인 시 실행",
        .launchAtLoginFailed: "로그인 항목을 바꾸지 못했어요. Wakey를 응용 프로그램 폴더로 옮긴 뒤 다시 시도하세요.",
        .remoteStandbySettings: "작업 사이에도 깨어 있기",
        .remoteStandbySubtitle: "원격 접속을 위해 Mac을 깨워 둬요. 화면은 그대로 꺼져요.",
        .releaseAfter: "AI 작업이 끝난 뒤 해제",
        .minutesFormat: "%d분",
        .batteryFloor: "배터리가 이 아래면 해제",
        .sectionLid: "덮개 모드",
        .helper: "도우미",
        .helperSubtitle: "시스템 설정에서 한 번만 허용하면 돼요",
        .helperReady: "설치됨",
        .helperNotInstalled: "설치 안 됨",
        .helperNeedsApproval: "허용 대기 중",
        .helperUnavailable: "이 빌드에서는 쓸 수 없어요",
        .helperInstall: "설치…",
        .helperUninstall: "제거",
        .helperOpenLoginItems: "로그인 항목 열기…",
        .clamshellAuto: "클램쉘이면 자동으로 켜기",
        .clamshellAutoSubtitle: "모니터를 꺼도 Mac이 잠들지 않아요",
        .thermalGuard: "Mac이 뜨거워지면 끄기",
        .sectionApps: "감지할 앱",
        .appClaude: "Claude",
        .appChatGPT: "ChatGPT (Codex)",
        .appAntigravity: "Antigravity",
        .appTerminal: "터미널 에이전트 (claude, codex)",
        .signalClaude: "앱 신호. Claude Code 훅을 추가하면 시작·종료를 정확히 감지",
        .signalChatGPT: "앱 신호",
        .signalAntigravity: "사용량으로 추정",
        .signalTerminal: "프로세스 활동",
        .statusWorking: "작업 중",
        .statusIdle: "대기",
        .statusNotRunning: "실행 안 됨",
        .claudeHooks: "Claude Code 신호",
        .claudeHooksSubtitle: "~/.claude/settings.json에 시작·종료 훅을 추가해요. 백업도 남겨요.",
        .claudeHooksOn: "추가됨",
        .claudeHooksAdd: "추가",
        .claudeHooksRemove: "제거",
        .detectionNote: "Wakey는 앱 상태만 확인해요. 프롬프트나 코드는 읽지 않아요.",
        .versionFormat: "버전 %@",
        .whatsNew: "새로운 기능",
        .whatsNew1: "AI가 일할 때만 깨어 있는 자동 모드",
        .whatsNew2: "덮개를 닫아도 계속되는 덮개 모드",
        .whatsNew3: "영어·한국어·일본어, 다크 모드 지원",
        .openChangelog: "전체 변경 내역",
        .openReadme: "README",
        .terminalAgentName: "터미널 에이전트"
    ]

    static let japanese: [L10nKey: String] = [
        .title: "AIの作業中はスリープしない",
        .heroOff: "オフ・macOSの標準どおりスリープ",
        .heroIdle: "作業中のAIはありません",
        .heroRemote: "リモート待機中",
        .heroWorkingFormat: "%@ 作業中",
        .activeNow: "現在オン:",
        .nothing: "なし",
        .holdIdle: "スリープ防止",
        .holdDisplay: "画面オン",
        .holdLid: "蓋モード",
        .reasonAutoOff: "自動はオフです。詳細でオンにした項目だけが適用されます。",
        .reasonIdle: "作業中のAIがないため、スリープを許可しています。",
        .reasonPausedOnBattery: "バッテリー駆動のため停止中です。下の「バッテリーでも維持」をオンにしてください。",
        .reasonBatteryFloor: "バッテリー残量が少ないため、Wakeyは解除しました。",
        .reasonRemoteStandby: "リモート待機中です。画面は消えても、Macにはずっと接続できます。",
        .reasonClamshell: "クラムシェルを検出したため蓋モードもオンにしました。モニターを消してもスリープしません。",
        .reasonLidAway: "蓋を閉じても続きます。作業が終わるとすぐスリープします。",
        .reasonNormal: "画面が消えてロックされても、作業は続きます。",
        .lidNeedsHelper: "蓋モードにはヘルパーが必要です。設定からインストールしてください。",
        .lidTooHot: "Macが熱くなったため、蓋モードをオフにしました。",
        .lidSection: "蓋",
        .situationLidOpenAC: "開・電源アダプタ",
        .situationLidOpenBattery: "開・バッテリー",
        .situationClamshell: "閉・外部ディスプレイ",
        .situationLidClosedNoDisplay: "閉・ディスプレイなし",
        .lidAwayTitle: "ディスプレイなしで蓋を閉じても継続",
        .lidAwaySubtitle: "作業後にスリープ・発熱に注意",
        .timer: "タイマー",
        .timer30: "30分",
        .timer60: "1時間",
        .timer120: "2時間",
        .timerAlways: "常時",
        .timerUntilOff: "オフにするまで",
        .timerMinutesLeftFormat: "残り%d分",
        .stepAway: "画面を消して離席",
        .powerACBatteryFormat: "電源アダプタ・バッテリー%d%%",
        .powerAC: "電源アダプタ",
        .powerBatteryFormat: "バッテリー・%d%%",
        .lidClosedExternal: "蓋は閉・外部ディスプレイ接続",
        .lidOpenExternal: "蓋は開・外部ディスプレイ接続",
        .lidOpenNoExternal: "蓋は開・外部ディスプレイなし",
        .detectedWorkingFormat: "検出: %@ が作業中",
        .detectedNone: "検出: 作業中のAIなし",
        .blockingFormat: "スリープを防止中: %@",
        .keepOnBatteryFormat: "バッテリーでも維持(%d%%まで)",
        .remoteStandby: "AIの待機中も起きておく(リモート用)",
        .advanced: "詳細",
        .advancedNote: "オンにした項目は、自動の判定に関係なく維持されます。",
        .manualIdle: "スリープを防止",
        .manualIdleSubtitle: "画面が消えてもMacは動き続けます",
        .manualDisplay: "画面をオンのまま",
        .manualDisplaySubtitle: "スクリーンセーバーと画面オフを防止",
        .manualLid: "蓋を閉じてもスリープしない",
        .manualLidSubtitle: "ディスプレイや電源なしでも動作・発熱に注意",
        .openSettings: "設定…",
        .quit: "Wakeyを終了",

        .settingsTitle: "Wakey 設定",
        .tabGeneral: "一般",
        .tabDetection: "検出",
        .tabAbout: "情報",
        .sectionLanguage: "言語と外観",
        .language: "言語",
        .appearance: "外観",
        .appearanceSystem: "システム",
        .appearanceLight: "ライト",
        .appearanceDark: "ダーク",
        .appearanceNote: "システムはmacOSの設定に従います。",
        .sectionBehavior: "動作",
        .launchAtLogin: "ログイン時に起動",
        .launchAtLoginFailed: "ログイン項目を変更できませんでした。Wakeyをアプリケーションフォルダに移動してから、もう一度お試しください。",
        .remoteStandbySettings: "タスクの合間も起きておく",
        .remoteStandbySubtitle: "リモート接続できるようMacを起こしておきます。画面は消えます。",
        .releaseAfter: "AI作業の終了後に解除",
        .minutesFormat: "%d分",
        .batteryFloor: "バッテリー残量がこれ以下で解除",
        .sectionLid: "蓋モード",
        .helper: "ヘルパー",
        .helperSubtitle: "システム設定で一度だけ許可が必要です",
        .helperReady: "インストール済み",
        .helperNotInstalled: "未インストール",
        .helperNeedsApproval: "許可待ち",
        .helperUnavailable: "このビルドでは使えません",
        .helperInstall: "インストール…",
        .helperUninstall: "アンインストール",
        .helperOpenLoginItems: "ログイン項目を開く…",
        .clamshellAuto: "クラムシェルでは自動でオン",
        .clamshellAutoSubtitle: "モニターを消してもMacはスリープしません",
        .thermalGuard: "Macが熱くなったらオフ",
        .sectionApps: "検出するアプリ",
        .appClaude: "Claude",
        .appChatGPT: "ChatGPT(Codex)",
        .appAntigravity: "Antigravity",
        .appTerminal: "ターミナルのエージェント(claude、codex)",
        .signalClaude: "アプリの信号。Claude Codeのフックを追加すると開始・終了を正確に検出",
        .signalChatGPT: "アプリの信号",
        .signalAntigravity: "使用状況から推定",
        .signalTerminal: "プロセスの動作",
        .statusWorking: "作業中",
        .statusIdle: "待機中",
        .statusNotRunning: "起動していません",
        .claudeHooks: "Claude Codeの信号",
        .claudeHooksSubtitle: "~/.claude/settings.json に開始・終了のフックを追加します。バックアップも残します。",
        .claudeHooksOn: "追加済み",
        .claudeHooksAdd: "追加",
        .claudeHooksRemove: "削除",
        .detectionNote: "Wakeyはアプリの状態だけを確認します。プロンプトやコードは読みません。",
        .versionFormat: "バージョン %@",
        .whatsNew: "新機能",
        .whatsNew1: "AIの作業中だけ起きておく自動モード",
        .whatsNew2: "蓋を閉じても続く蓋モード",
        .whatsNew3: "英語・韓国語・日本語、ダークモードに対応",
        .openChangelog: "すべての変更履歴",
        .openReadme: "README",
        .terminalAgentName: "ターミナルのエージェント"
    ]
}
