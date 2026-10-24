import SwiftUI
import UIKit

// MARK: - Login

struct LoginView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var password = ""
    @State private var showPassword = false
    @State private var showError = false
    @State private var errorMessage = "Clave incorrecta"
    @State private var shakeOffset: CGFloat = 0
    @State private var glowAnimation = false
    @State private var appeared = false
    @State private var rotationAngle: Double = 0
    @State private var isVerifying = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            SIBackground(imageTop: 64, imageWidthRatio: 0.72)

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 16)

                        topBadge

                        // Empuja el formulario hacia abajo para dejar ver la imagen de fondo
                        Spacer(minLength: 250)

                        loginPanel

                        Spacer().frame(height: 22)

                        footerSection

                        Spacer().frame(height: 24)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Top Badge

    private var topBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(SITheme.ok)
                .frame(width: 6, height: 6)
                .shadow(color: SITheme.ok.opacity(0.6), radius: 4)
            Text("SISTEMA ACTIVO")
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .foregroundColor(SITheme.ink.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(SITheme.card.opacity(0.92)))
        .overlay(Capsule().strokeBorder(SITheme.edgeStroke, lineWidth: 1))
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }

    // MARK: - Panel de login

    private var loginPanel: some View {
        VStack(spacing: 16) {
            panelHeader

            welcomeCard

            passwordField

            loginButton

            if showError {
                errorMessageView
            }

            statusIndicators
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .siCard(radius: 22)
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.easeOut(duration: 0.6).delay(0.25), value: appeared)
    }

    // MARK: - Panel Header (logo + nombre)

    private var panelHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                SITheme.accent.opacity(glowAnimation ? 0.45 : 0.20),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 14,
                            endRadius: 54
                        )
                    )
                    .frame(width: 108, height: 108)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.clear,
                                SITheme.accent.opacity(0.95),
                                Color.clear,
                                SITheme.accentRed.opacity(0.9),
                                Color.clear
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 8])
                    )
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(rotationAngle))

                SILogo(size: 62)

                Circle()
                    .strokeBorder(SITheme.ringStroke, lineWidth: 2.5)
                    .frame(width: 70, height: 70)
                    .shadow(color: SITheme.accent.opacity(0.7), radius: glowAnimation ? 12 : 5)
            }
            .frame(height: 104)

            Text(SITheme.appName)
                .font(.system(size: 14, weight: .heavy))
                .tracking(2.5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(SITheme.accent)
        }
    }

    // MARK: - Welcome Card

    private var welcomeCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SITheme.accent.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(SITheme.accent.opacity(0.45), lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SITheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Acceso restringido")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(SITheme.ink)
                Text("Introduce tu clave para continuar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SITheme.inkSoft)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .siCard(radius: 12, tint: Color.white.opacity(0.03), tab: false)
    }

    // MARK: - Password Field (con ojo y pegar)

    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundColor(SITheme.accent.opacity(0.85))
                .font(.system(size: 15))

            Group {
                if showPassword {
                    TextField("Introduce tu clave...", text: $password, prompt: Text("Introduce tu clave...").foregroundColor(SITheme.inkFaint))
                } else {
                    SecureField("Introduce tu clave...", text: $password, prompt: Text("Introduce tu clave...").foregroundColor(SITheme.inkFaint))
                }
            }
            .textFieldStyle(.plain)
            .foregroundColor(SITheme.ink)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.go)
            .focused($fieldFocused)
            .onSubmit(attemptLogin)
            .disabled(isVerifying)

            if !password.isEmpty && !isVerifying {
                Button {
                    password = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SITheme.inkFaint)
                        .font(.system(size: 14))
                }
            }

            // Pegar desde el portapapeles
            Button(action: pasteFromClipboard) {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(SITheme.accent.opacity(0.9))
                    .font(.system(size: 15))
            }
            .disabled(isVerifying)

            // Ver / ocultar lo que escribes
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(SITheme.accent.opacity(0.9))
                    .font(.system(size: 15))
                    .frame(width: 22)
            }
            .disabled(isVerifying)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .siCard(
            radius: 12,
            stroke: showError
                ? AnyShapeStyle(SITheme.danger.opacity(0.8))
                : AnyShapeStyle(SITheme.edgeStroke),
            tint: Color.white.opacity(0.05),
            tab: false
        )
        .offset(x: shakeOffset)
    }

    private func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        password = text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button(action: attemptLogin) {
            HStack(spacing: 10) {
                if isVerifying {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.9)
                    Text("VERIFICANDO...")
                        .font(.system(size: 15, weight: .heavy))
                        .tracking(2)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                    Text("ENTRAR")
                        .font(.system(size: 15, weight: .heavy))
                        .tracking(2)
                }
            }
            .foregroundColor(Color.black.opacity(0.88))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(SITheme.accentGradient)
                    .shadow(color: SITheme.accent.opacity(0.45), radius: 14, y: 6)
            )
        }
        .disabled(password.isEmpty || isVerifying)
        .opacity((password.isEmpty || isVerifying) ? 0.45 : 1.0)
        .scaleEffect(password.isEmpty ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
    }

    // MARK: - Error Message

    private var errorMessageView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(errorMessage)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(SITheme.danger)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(SITheme.danger.opacity(0.12))
                .overlay(Capsule().stroke(SITheme.danger.opacity(0.35), lineWidth: 1))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Status Indicators

    private var statusIndicators: some View {
        HStack(spacing: 20) {
            statusDot(color: supabase.isConnected ? SITheme.ok : .gray, label: "Online")
            statusDot(color: SITheme.accent.opacity(0.85), label: "v2.0")
            statusDot(color: SITheme.accentRed.opacity(0.9), label: "Beta")
        }
    }

    private func statusDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.6), radius: 3)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(SITheme.inkSoft)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 9))
                .foregroundColor(SITheme.inkSoft)
            Text("Hecho por didierxitx7")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(SITheme.inkSoft)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: appeared)
    }

    // MARK: - Login Logic

    private func attemptLogin() {
        guard !isVerifying else { return }
        let key = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        isVerifying = true
        showError = false
        fieldFocused = false

        Task {
            do {
                let result = try await supabase.verifyKey(key)
                log("login: key verificada — \(result.label ?? "sin label")")

                UINotificationFeedbackGenerator().notificationOccurred(.success)

                await MainActor.run {
                    isVerifying = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        KeychainStore.save(key)          // guarda la key para no pedirla de nuevo
                        session.isAuthenticated = true
                    }
                }

            } catch let error as SupabaseError {
                await MainActor.run {
                    isVerifying = false
                    handleLoginError(error)
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    errorMessage = "Error de conexión"
                    showError = true
                    shakePasswordField()
                }
            }
        }
    }

    // MARK: - Handle Login Error

    private func handleLoginError(_ error: SupabaseError) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        switch error {
        case .keyNotFound:
            errorMessage = "Clave no encontrada"
        case .keyBanned:
            errorMessage = "Esta clave fue baneada"
        case .keyExpired:
            errorMessage = "Esta clave expiró"
        case .keyInactive:
            errorMessage = "Esta clave está desactivada"
        case .deviceLimitReached:
            errorMessage = "Límite de dispositivos alcanzado"
        case .deviceBanned:
            errorMessage = "Este dispositivo fue baneado"
        case .networkError:
            errorMessage = "Error de conexión"
        case .invalidURL, .noData, .decodingFailed:
            errorMessage = "Error del servidor"
        }

        showError = true
        shakePasswordField()
    }

    // MARK: - Shake Animation

    private func shakePasswordField() {
        withAnimation(.default) { shakeOffset = -10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = 10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.default) { shakeOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showError = false }
            password = ""
        }
    }
}