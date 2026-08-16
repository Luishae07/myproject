import SwiftUI

struct JobsView: View {
    let project: Project
    @EnvironmentObject var session: SessionStore
    @State private var jobs: [ScheduledJob] = []
    @State private var loading = true
    @State private var showingNew = false
    @State private var newCommand = ""
    @State private var newInterval = "60"
    @State private var errorText: String?

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if jobs.isEmpty {
                ContentUnavailableView("No scheduled jobs", systemImage: "clock.arrow.circlepath")
            } else {
                List {
                    ForEach(jobs) { job in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(job.command).font(.system(.subheadline, design: .monospaced))
                            Text("every \(job.interval_minutes ?? 0) min")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Scheduled Jobs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingNew = true } label: { Image(systemName: "plus") }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                Form {
                    TextField("Command", text: $newCommand)
                        .font(.system(.body, design: .monospaced))
                    TextField("Interval (minutes)", text: $newInterval)
                        .keyboardType(.numberPad)
                    if let errorText {
                        Text(errorText).font(.footnote).foregroundStyle(.red)
                    }
                }
                .navigationTitle("New job")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { showingNew = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") { Task { await create() } }
                            .disabled(newCommand.isEmpty)
                    }
                }
            }
        }
    }

    private func load() async {
        guard let key = session.apiKey else { return }
        loading = true
        jobs = (try? await APIClient.jobsList(apiKey: key, projectId: project.id)) ?? []
        loading = false
    }

    private func create() async {
        guard let key = session.apiKey else { return }
        do {
            try await APIClient.jobsCreate(apiKey: key, projectId: project.id, command: newCommand, intervalMinutes: Int(newInterval) ?? 60)
            newCommand = ""
            showingNew = false
            await load()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        guard let key = session.apiKey else { return }
        let toDelete = offsets.map { jobs[$0] }
        jobs.remove(atOffsets: offsets)
        Task {
            for job in toDelete {
                try? await APIClient.jobsDelete(apiKey: key, jobId: job.id)
            }
        }
    }
}
