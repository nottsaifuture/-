import SwiftUI

struct KeyboardView: View {
    @ObservedObject var model: KeyboardModel

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Label("My Typeless", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Picker("風格", selection: $model.style) {
                    ForEach(CleanStyle.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            Text(model.status)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 40)

            Button { model.cleanUp() } label: {
                ZStack {
                    if model.busy {
                        ProgressView().tint(.white)
                    } else {
                        Label("整理", systemImage: "wand.and.stars")
                            .font(.title2.bold())
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 210, height: 64)
                .background(Capsule().fill(Color.black))
            }
            .disabled(model.busy)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                if model.needsGlobe {
                    KeyButton(systemImage: "globe") { model.nextKeyboard() }
                }
                KeyButton(systemImage: "arrow.uturn.backward") { model.undo() }
                KeyButton(title: "空格", width: nil) { model.insert(" ") }
                KeyButton(title: "return", width: 90) { model.insert("\n") }
                KeyButton(systemImage: "delete.left") { model.deleteBackward() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct KeyButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    var width: CGFloat? = 48
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Image(systemName: systemImage)
                } else {
                    Text(title ?? "")
                }
            }
            .font(.title3)
            .foregroundStyle(.primary)
            .frame(width: width, height: 48)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background(Capsule().fill(Color(.systemBackground).opacity(0.85)))
        }
    }
}
