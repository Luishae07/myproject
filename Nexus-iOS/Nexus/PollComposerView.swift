import SwiftUI

struct PollComposerView: View {
    let onCreate: (String, [String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var options: [String] = ["", ""]

    private var validOptions: [String] {
        options.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Ask something...", text: $question)
                }
                Section("Options") {
                    ForEach($options.indices, id: \.self) { i in
                        TextField("Option \(i + 1)", text: $options[i])
                    }
                    .onDelete { options.remove(atOffsets: $0) }
                    if options.count < 10 {
                        Button("Add option") { options.append("") }
                    }
                }
            }
            .navigationTitle("New Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        onCreate(question.trimmingCharacters(in: .whitespaces), validOptions)
                        dismiss()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || validOptions.count < 2)
                }
            }
        }
    }
}
