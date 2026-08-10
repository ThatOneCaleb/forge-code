import SwiftUI
import ForgeCodeEngine

/// Monospaced text editor for writing program code directly.
/// Shows a friendly error banner (engine's `ParseError.message`) on parse failure.
struct CodeEditorView: View {
    @Bindable var vm: SimulatorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Code Editor")
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.secondary)

            TextEditor(text: $vm.codeText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 160)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(vm.parseError != nil ? Color.orange : Color(.systemGray4), lineWidth: 1)
                )
                .accessibilityLabel("Code editor. Type your program here.")

            if let error = vm.parseError {
                parseErrorBanner(error)
            }
        }
    }

    private func parseErrorBanner(_ error: ParseError) -> some View {
        Label(error.message, systemImage: "lightbulb.fill")
            .font(.callout)
            .foregroundStyle(.orange)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Hint: \(error.message)")
    }
}
