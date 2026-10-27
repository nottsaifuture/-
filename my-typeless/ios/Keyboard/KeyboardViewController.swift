import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController {
    private let model = KeyboardModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        model.controller = self
        let host = UIHostingController(rootView: KeyboardView(model: model))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        let height = view.heightAnchor.constraint(equalToConstant: 280)
        height.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            height,
        ])
        host.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.needsGlobe = needsInputModeSwitchKey
        model.hasFullAccess = hasFullAccess
        model.status = hasFullAccess
            ? "打完字或者講完嘢，撳「整理」"
            : "請先喺設定開「允許完整取用」"
    }
}

@MainActor
final class KeyboardModel: ObservableObject {
    weak var controller: UIInputViewController?
    @Published var busy = false
    @Published var status = ""
    @Published var hasFullAccess = true
    @Published var needsGlobe = true
    @Published var style: CleanStyle {
        didSet { UserDefaults.standard.set(style.rawValue, forKey: "style") }
    }
    private var lastOriginal: String?
    private var lastResult: String?

    init() {
        style = CleanStyle(rawValue: UserDefaults.standard.string(forKey: "style") ?? "") ?? .spoken
    }

    private var proxy: UITextDocumentProxy? { controller?.textDocumentProxy }

    // 有揀字就淨係整理揀咗嘅字，冇就整理成個輸入框
    func cleanUp() {
        guard let proxy, !busy else { return }
        guard hasFullAccess else {
            status = "請先喺設定開「允許完整取用」"
            return
        }
        let selected = proxy.selectedText ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        let useSelection = !selected.isEmpty
        let original = useSelection ? selected : (proxy.documentContextBeforeInput ?? "") + after
        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "輸入框冇字"
            return
        }

        busy = true
        status = "整理緊…"
        Task {
            defer { busy = false }
            do {
                let result = try await Gemini.clean(original, style: style)
                guard !result.isEmpty else {
                    status = "Gemini 冇俾到結果"
                    return
                }
                if useSelection {
                    proxy.insertText(result) // 會取代揀咗嘅字
                } else {
                    if !after.isEmpty {
                        proxy.adjustTextPosition(byCharacterOffset: after.count)
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                    for _ in 0..<original.count { proxy.deleteBackward() }
                    proxy.insertText(result)
                }
                lastOriginal = original
                lastResult = result
                status = "整理好 ✓　唔啱心水可以撳 ↶ 還原"
            } catch {
                status = error.localizedDescription
            }
        }
    }

    func undo() {
        guard let proxy, let original = lastOriginal, let result = lastResult else { return }
        let before = proxy.documentContextBeforeInput ?? ""
        guard before.hasSuffix(result) || (!before.isEmpty && result.hasSuffix(before)) else {
            status = "冇得還原"
            return
        }
        for _ in 0..<result.count { proxy.deleteBackward() }
        proxy.insertText(original)
        lastOriginal = nil
        lastResult = nil
        status = "已還原"
    }

    func insert(_ text: String) { proxy?.insertText(text) }
    func deleteBackward() { proxy?.deleteBackward() }
    func nextKeyboard() { controller?.advanceToNextInputMode() }
}
