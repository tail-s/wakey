import Foundation
import Testing
@testable import WakeyCore

@Suite struct L10nTests {
    @Test(arguments: AppLanguage.allCases)
    func everyKeyIsTranslated(language: AppLanguage) {
        let table = L10n.table(for: language)
        let missing = L10nKey.allCases.filter { (table[$0] ?? "").isEmpty }
        #expect(missing.isEmpty, "Missing \(language.rawValue): \(missing.map(\.rawValue))")
    }

    @Test(arguments: AppLanguage.allCases)
    func formatPlaceholdersMatchEnglish(language: AppLanguage) {
        func placeholders(_ text: String) -> [String] {
            let pattern = try! NSRegularExpression(pattern: "%(?:@|d)")
            let range = NSRange(text.startIndex..., in: text)
            return pattern.matches(in: text, range: range).map { String(text[Range($0.range, in: text)!]) }
        }
        for key in L10nKey.allCases {
            #expect(
                placeholders(L10n.string(key, language)) == placeholders(L10n.string(key, .english)),
                "Placeholder mismatch for \(key.rawValue) in \(language.rawValue)"
            )
        }
    }

    @Test func formatsNumbersAndNames() {
        #expect(L10n.format(.keepOnBatteryFormat, .english, 20) == "Keep on battery (down to 20%)")
        #expect(L10n.format(.heroWorkingFormat, .korean, "Claude") == "Claude 작업 중")
        #expect(L10n.format(.timerMinutesLeftFormat, .japanese, 12) == "残り12分")
    }
}
