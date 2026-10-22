import SwiftUI
import UIKit

struct LoginView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = "Clave incorrecta"
    @State private var shakeOffset: CGFloat = 0
    @State private var appeared = false
    @State private var isVerifying = false
    
    var body: some View {
        ZStack {
            AngelBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    AngelHeader(subtitle: "PATCH LIBRARY", online: supabase.isConnected)
                        .padding(.top, 8)
                    
                    accessCard
                    
                    statusIndicators
                        .padding(.top, 4)
                    
                    AngelSignature()
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Tarjeta de acceso
    
    private var accessCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Listen now")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.white)
            
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AngelTheme.accentGradient)
                        .frame(width: 118, height: 118)
                        .shadow(color: AngelTheme.accent.opacity(0.3), radius: 16, y: 6)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Acceso restringido")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Introduce tu clave para continuar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AngelTheme.secondary)
                    
                    Text("SISTEMA ACTIVO")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(AngelTheme.ok)
                }
                
                Spacer(minLength: 0)
            }
            
            passwordField
            loginButton
            
            if showError {
                errorMessageView
            }
        }
        .padding(20)
        .angelCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }
    
    // MARK: - Password Field (con botón de pegar)
    
    private var passwordField: some View {
        HStack(spacing: 10) {
            Image(systemName: "key.fill")
                .foregroundStyle(AngelTheme.accent)
                .font(.system(size: 15))
            
            SecureField("Introduce tu clave...", text: $password)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.go)
                .onSubmit(attemptLogin)
                .disabled(isVerifying)
            
            // Botón de pegar (solo si el campo está vacío)
            if password.isEmpty && !isVerifying {
                Button {
                    pasteFromClipboard()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.system(size: 15))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle().fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
            
            // Botón de limpiar
            if !password.isEmpty && !isVerifying {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        password = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            showError
                                ? AngelTheme.danger.opacity(0.7)
                                : AngelTheme.accent.opacity(0.25),
                            lineWidth: 1.2
                        )
                )
        )
        .offset(x: shakeOffset)
        .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
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
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(AngelTheme.accentGradient)
                    .shadow(color: AngelTheme.accent.opacity(0.35), radius: 14, y: 5)
            )
        }
        .buttonStyle(.plain)
        .disabled(password.isEmpty || isVerifying)
        .opacity((password.isEmpty || isVerifying) ? 0.4 : 1.0)
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
        .foregroundStyle(AngelTheme.danger)
        .frame(maxWidth: .infinity)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Status Indicators
    
    private var statusIndicators: some View {
        HStack(spacing: 20) {
            statusDot(color: supabase.isConnected ? AngelTheme.ok : .gray, label: "Online")
            statusDot(color: AngelTheme.accent, label: "v2.0")
            statusDot(color: AngelTheme.accent, label: "Beta")
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: appeared)
    }
    
    private func statusDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.8), radius: 3)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    // MARK: - Pegar del portapapeles
    
    private func pasteFromClipboard() {
        guard let pastedText = UIPasteboard.general.string,
              !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            log("clipboard: vacío")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            password = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        log("clipboard: pegado")
    }
    
    // MARK: - Login Logic (Supabase)
    
    private func attemptLogin() {
        guard !isVerifying else { return }
        guard !password.isEmpty else { return }
        
        isVerifying = true
        showError = false
        
        Task {
            do {
                let key = try await supabase.verifyKey(password)
                log("login: key verificada — \(key.label ?? "sin label")")
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                await MainActor.run {
                    isVerifying = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // Guardar sesión (persiste al cerrar la app)
                        session.saveSession(keyValue: key.keyValue)
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
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
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
            errorMessage = "Este dispositivo fue baneado permanentemente"
        case .deviceSuspended:
            errorMessage = "Tu dispositivo está suspendido temporalmente"
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