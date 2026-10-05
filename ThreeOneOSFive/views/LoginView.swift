import SwiftUI
import UIKit

struct LoginView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = "Clave incorrecta"
    @State private var shakeOffset: CGFloat = 0
    @State private var glowAnimation = false
    @State private var appeared = false
    @State private var rotationAngle: Double = 0
    @State private var isVerifying = false
    
    var body: some View {
        ZStack {
            background
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    
                    topBadge
                    
                    Spacer().frame(height: 30)
                    
                    logoSection
                    
                    Spacer().frame(height: 30)
                    
                    titleSection
                    
                    Spacer().frame(height: 36)
                    
                    welcomeCard
                    
                    Spacer().frame(height: 20)
                    
                    passwordField
                    
                    Spacer().frame(height: 14)
                    
                    loginButton
                    
                    if showError {
                        errorMessageView
                    }
                    
                    Spacer().frame(height: 24)
                    
                    statusIndicators
                    
                    Spacer().frame(height: 40)
                    
                    footerSection
                    
                    Spacer().frame(height: 30)
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
    
    // MARK: - Background
    
    private var background: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color.white.opacity(glowAnimation ? 0.12 : 0.04),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.15),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            GeometryReader { geo in
                ForEach(0..<25, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 2, height: 2)
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .opacity(glowAnimation ? 0.7 : 0.15)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Top Badge
    
    private var topBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .shadow(color: .white.opacity(0.8), radius: 4)
            Text("SISTEMA ACTIVO")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(glowAnimation ? 0.2 : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
            
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.6),
                            Color.white.opacity(0),
                            Color.white.opacity(0.4),
                            Color.white.opacity(0)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 8])
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(rotationAngle))
            
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 120, height: 120)
            
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 100, height: 100)
                .shadow(color: .white.opacity(0.6), radius: glowAnimation ? 25 : 12)
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .clipShape(Circle())
                .shadow(color: .white.opacity(0.4), radius: 10)
        }
        .frame(height: 220)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(.easeOut(duration: 0.6).delay(0.15), value: appeared)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("DARIELMODZ")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.4), radius: 10)
            
            HStack(spacing: 8) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 1)
                
                Text("EXTERNAL")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.8))
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 1)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.25), value: appeared)
    }
    
    // MARK: - Welcome Card
    
    private var welcomeCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Acceso restringido")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("Introduce tu clave para continuar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 28)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.35), value: appeared)
    }
    
    // MARK: - Password Field
    
    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundStyle(.white)
                .font(.system(size: 15))
            
            SecureField("Introduce tu clave...", text: $password)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.go)
                .onSubmit(attemptLogin)
                .disabled(isVerifying)
            
            if !password.isEmpty && !isVerifying {
                Button {
                    password = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            showError
                                ? Color.red.opacity(0.6)
                                : Color.white.opacity(0.25),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .white.opacity(0.1), radius: 12)
        )
        .padding(.horizontal, 28)
        .offset(x: shakeOffset)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.45), value: appeared)
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(white: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .white.opacity(0.4), radius: 15, y: 5)
            )
        }
        .padding(.horizontal, 28)
        .disabled(password.isEmpty || isVerifying)
        .opacity((password.isEmpty || isVerifying) ? 0.4 : 1.0)
        .scaleEffect(password.isEmpty ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: appeared)
    }
    
    // MARK: - Error Message
    
    private var errorMessageView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(errorMessage)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
        .padding(.top, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Status Indicators
    
    private var statusIndicators: some View {
        HStack(spacing: 20) {
            statusDot(color: supabase.isConnected ? .white : .gray, label: "Online")
            statusDot(color: .white, label: "v2.0")
            statusDot(color: .white, label: "Beta")
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: appeared)
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
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
            Text("Hecho por didierxitx7")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.7), value: appeared)
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
        // Vibración de error
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Mensaje específico según el error
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
