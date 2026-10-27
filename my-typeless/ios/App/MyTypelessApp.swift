import SwiftUI

@main
struct MyTypelessApp: App {
    var body: some Scene {
        WindowGroup { SetupView() }
    }
}

struct SetupView: View {
    @State private var testText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("設定鍵盤（一次過）") {
                    Text("1. 撳下面「打開設定」→ 鍵盤 → 開「My Typeless」同「允許完整取用」")
                    Text("2. 「允許完整取用」係俾鍵盤上網叫 Gemini 用，冇佢整理唔到")
                    Button("打開設定") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Section("點用") {
                    Text("用平時嘅鍵盤打字，或者用佢個咪講完 → 撳 🌐 轉做 My Typeless → 撳「整理」。")
                    Text("文字好長嘅話，可以先全選再撳「整理」。唔啱心水撳 ↶ 還原。")
                }
                Section("喺度試吓") {
                    TextEditor(text: $testText)
                        .frame(minHeight: 160)
                }
            }
            .navigationTitle("My Typeless")
        }
    }
}
