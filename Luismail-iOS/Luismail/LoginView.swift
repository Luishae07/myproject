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
                backgroundMesh

                ScrollView {
                    VStack(spacing: 22) {
                        Spacer(minLength: 40)

                        VStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(Color.accentColor)

                            HStack(spacing: 6) {
                                Image(systemName: "lock.shield.fill").font(.caption2)
                                Text("Built to protect your privacy").font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(.regular.tint(Color.accentColor.opacity(0.15)), in: .capsule)

                            Text("Mail, re-engineered.")
                                .font(.system(.title, design: .serif, weight: .semibold))
                                .multilineTextAlignment(.center)
                            Text("No **@**. No SMTP.")
                                .font(.system(.title2, design: .serif, weight: .semibold))
                                .foregroundStyle(Color.accentColor)

                            Text("Addresses look like you/luismail.pages.dev. Every message is encrypted over TLS 1.3 via LSAD.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.top, 2)
                        }

                        VStack(spacing: 14) {
                            HStack {
                                TextField("username", text: $username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .username)
                                Text("/\(luismailDomain)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .glassEffect(in: .rect(cornerRadius: 14))

                            SecureField("password", text: $password)
                                .focused($focusedField, equals: .password)
                                .padding()
                                .glassEffect(in: .rect(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                        .padding(.top, 6)

                        if let error = session.errorMessage {
                            Text(error).font(.footnote).foregroundStyle(.red)
                        }

                        GlassEffectContainer(spacing: 12) {
                            VStack(spacing: 12) {
                                Button {
                                    focusedField = nil
                                    Task { await session.login(username: username, password: password) }
                                } label: {
                                    Text("Log in").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.glass)
                                .tint(.accentColor)
                                .disabled(username.isEmpty || password.isEmpty || session.isLoading)

                                Button {
                                    focusedField = nil
                                    Task { await session.register(username: username, password: password) }
                                } label: {
                                    Text("Register new address").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.glass)
                                .disabled(username.isEmpty || password.isEmpty || session.isLoading)
                            }
                        }
                        .padding(.horizontal)

                        if session.isLoading { ProgressView() }

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var backgroundMesh: some View {
        ZStack {
            RadialGradient(colors: [Color.accentColor.opacity(0.22), .clear], center: .init(x: 0.2, y: 0.1), startRadius: 0, endRadius: 340)
            RadialGradient(colors: [Color.accentColor.opacity(0.16), .clear], center: .init(x: 0.85, y: 0.65), startRadius: 0, endRadius: 300)
            Color(.systemBackground)
                .opacity(0.001) // keeps the gradient from bleeding past safe areas oddly on some devices
        }
        .ignoresSafeArea()
    }
}
