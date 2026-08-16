import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @State private var username = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    enum Field { case username, password }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.25), Color(.systemBackground)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)
                        Text("Luismail")
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        Text("LSAD protocol · not SMTP")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 14) {
                        HStack {
                            TextField("username", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                            Text("/\(luismailDomain)")
                                .foregroundStyle(.secondary)
                                .font(.footnote.monospaced())
                        }
                        .padding()
                        .glassEffect(in: .rect(cornerRadius: 14))

                        SecureField("password", text: $password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .glassEffect(in: .rect(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    if let error = session.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    GlassEffectContainer(spacing: 12) {
                        VStack(spacing: 12) {
                            Button {
                                focusedField = nil
                                Task { await session.login(username: username, password: password) }
                            } label: {
                                Text("Log in")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .tint(.accentColor)
                            .disabled(username.isEmpty || password.isEmpty || session.isLoading)

                            Button {
                                focusedField = nil
                                Task { await session.register(username: username, password: password) }
                            } label: {
                                Text("Register new address")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .disabled(username.isEmpty || password.isEmpty || session.isLoading)
                        }
                    }
                    .padding(.horizontal)

                    if session.isLoading {
                        ProgressView()
                    }

                    Spacer()
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}
