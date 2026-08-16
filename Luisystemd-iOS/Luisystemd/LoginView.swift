import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @State private var username = ""
    @State private var password = ""
    @State private var isSignup = false
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var githubSignIn = GitHubSignIn()

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 6) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                        Text("Luisystemd")
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                            .foregroundStyle(.white)
                        Text("Code, run, and deploy from anywhere")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 60)

                    VStack(spacing: 12) {
                        TextField("Username", text: $username)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .glassEffect(in: .rect(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .glassEffect(in: .rect(cornerRadius: 12))

                        if let errorText {
                            Text(errorText)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Text(isLoading ? "..." : (isSignup ? "Create account" : "Log in"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(username.isEmpty || password.isEmpty || isLoading)

                        Button(isSignup ? "Already have an account? Log in" : "New here? Create an account") {
                            isSignup.toggle()
                            errorText = nil
                        }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))

                        HStack {
                            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
                            Text("or").font(.caption).foregroundStyle(.white.opacity(0.6))
                            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        Button {
                            Task { await signInWithGitHub() }
                        } label: {
                            Label("Continue with GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.glass)
                        .foregroundStyle(.white)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func submit() async {
        isLoading = true
        errorText = nil
        do {
            let resp = isSignup
                ? try await APIClient.signup(username: username, password: password)
                : try await APIClient.login(username: username, password: password)
            session.setSession(username: resp.username, apiKey: resp.key)
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }

    private func signInWithGitHub() async {
        isLoading = true
        errorText = nil
        do {
            let result = try await githubSignIn.signIn()
            session.setSession(username: result.username, apiKey: result.apiKey)
        } catch let authError as ASWebAuthenticationSessionError where authError.code == .canceledLogin {
            // user dismissed the sheet -- not a real error
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }
}
