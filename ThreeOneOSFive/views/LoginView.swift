import SwiftUI
import UIKit

// MARK: - Tema visual (plata / hielo, combina con el fondo)

private enum IDKTheme {
    /// Nombre del asset de la imagen de fondo (Assets.xcassets)
    static let backgroundImageName = "IDKBackground"

    static let ink = Color(red: 0.09, green: 0.11, blue: 0.17)
    static let inkSoft = Color(red: 0.09, green: 0.11, blue: 0.17).opacity(0.55)
    static let inkFaint = Color(red: 0.09, green: 0.11, blue: 0.17).opacity(0.35)

    static let silverLight = Color.white
    static let silverMid = Color(red: 0.80, green: 0.83, blue: 0.88)
    static let silverDark = Color(red: 0.55, green: 0.60, blue: 0.68)

    static let accent = Color(red: 0.28, green: 0.52, blue: 0.86)

    static var silverStroke: LinearGradient {
        LinearGradient(
            colors: [silverLight.opacity(0.95), silverMid.opacity(0.55), silverLight.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Estilo "cristal" reutilizable

private struct IDKGlass: ViewModifier {
    var radius: CGFloat = 16
    var tint: Color = Color.white.opacity(0.30)
    var strokeColor: AnyShapeStyle = AnyShapeStyle(IDKTheme.silverStroke)
    var strokeWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(tint)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            )
            .shadow(color: IDKTheme.silverDark.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

private extension View {
    func idkGlass(radius: CGFloat = 16,
                  tint: Color = Color.white.opacity(0.30),
                  stroke: AnyShapeStyle = AnyShapeStyle(IDKTheme.silverStroke),
                  strokeWidth: CGFloat = 1) -> some View {
        modifier(IDKGlass(radius: radius, tint: tint, strokeColor: stroke, strokeWidth: strokeWidth))
    }
}

// MARK: - Login

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
            
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 24)
                        
                        topBadge
                        
                        // Empuja el formulario hacia abajo para dejar ver
                        // al ángel y el logo de la imagen de fondo
                        Spacer(minLength: 200)
                        
                        loginPanel
                        
                        Spacer().frame(height: 24)
                        
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
    
    // MARK: - Background (imagen fija de fondo)
    
    private var background: some View {
        ZStack {
            // Color base por si la imagen no carga
            Color(red: 0.88, green: 0.90, blue: 0.94)
                .ignoresSafeArea()
            
            // Imagen a pantalla completa, sin deformarse
            Color.clear
                .overlay(
                    Image(IDKTheme.backgroundImageName)
                        .resizable()
                        .scaledToFill()
                )
                .clipped()
                .ignoresSafeArea()
            
            // Velo suave abajo para que el formulario se lea bien
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.0), location: 0.0),
                    .init(color: Color.white.opacity(0.08), location: 0.5),
                    .init(color: Color.white.opacity(0.35), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Top Badge
    
    private var topBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(red: 0.2, green: 0.6, blue: 0.2))
                .frame(width: 6, height: 6)
                .shadow(color: Color(red: 0.2, green: 0.6, blue: 0.2).opacity(0.6), radius: 4)
            Text("SISTEMA ACTIVO")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(IDKTheme.ink.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.white.opacity(0.30)))
        )
        .overlay(Capsule().strokeBorder(IDKTheme.silverStroke, lineWidth: 1))
        .shadow(color: IDKTheme.silverDark.opacity(0.25), radius: 8, y: 4)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }
    
    // MARK: - Panel de login (todo el formulario en una tarjeta de cristal)
    
    private var loginPanel: some View {
        VStack(spacing: 18) {
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
        .padding(.top, 22)
        .padding(.bottom, 20)
        .idkGlass(radius: 28, tint: Color.white.opacity(0.38))
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.easeOut(duration: 0.6).delay(0.25), value: appeared)
    }
    
    // MARK: - Panel Header (logo pequeño + nombre)
    
    private var panelHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(glowAnimation ? 0.95 : 0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 14,
                            endRadius: 52
                        )
                    )
                    .frame(width: 104, height: 104)
                
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.95),
                                Color.white.opacity(0),
                                IDKTheme.silverMid.opacity(0.9),
                                Color.white.opacity(0)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 8])
                    )
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(rotationAngle))
                
                Circle()
                    .strokeBorder(IDKTheme.silverStroke, lineWidth: 2.5)
                    .frame(width: 66, height: 66)
                    .shadow(color: Color.white.opacity(0.9), radius: glowAnimation ? 14 : 6)
                
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 4)
            }
            .frame(height: 100)
            
            HStack(spacing: 8) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, IDKTheme.ink.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 36, height: 1)
                
                Text("IDK EXTERNAL")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(IDKTheme.ink.opacity(0.8))
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, IDKTheme.ink.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 36, height: 1)
            }
        }
    }
    
    // MARK: - Welcome Card
    
    private var welcomeCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), IDKTheme.silverMid.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().strokeBorder(IDKTheme.silverStroke, lineWidth: 1))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(IDKTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Acceso restringido")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(IDKTheme.ink)
                Text("Introduce tu clave para continuar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(IDKTheme.inkSoft)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .idkGlass(radius: 16, tint: Color.white.opacity(0.25))
    }
    
    // MARK: - Password Field
    
    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundStyle(IDKTheme.ink.opacity(0.7))
                .font(.system(size: 15))
            
            SecureField("Introduce tu clave...", text: $password)
                .textFieldStyle(.plain)
                .foregroundStyle(IDKTheme.ink)
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
                        .foregroundStyle(IDKTheme.inkFaint)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .idkGlass(
            radius: 16,
            tint: Color.white.opacity(0.55),
            stroke: showError
                ? AnyShapeStyle(Color.red.opacity(0.6))
                : AnyShapeStyle(IDKTheme.silverStroke),
            strokeWidth: showError ? 1.5 : 1
        )
        .offset(x: shakeOffset)
    }
    
    // MARK: - Login Button
    
    private var loginButton: some View {
        Button(action: attemptLogin) {
            HStack(spacing: 10) {
                if isVerifying {
                    ProgressView()
                        .tint(.white)
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
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.20, blue: 0.30),
                                Color(red: 0.09, green: 0.11, blue: 0.17)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.55), Color.white.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: IDKTheme.accent.opacity(0.35), radius: 14, y: 6)
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
        .foregroundStyle(Color(red: 0.78, green: 0.25, blue: 0.25))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.65))
                .overlay(Capsule().stroke(Color.red.opacity(0.25), lineWidth: 1))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Status Indicators
    
    private var statusIndicators: some View {
        HStack(spacing: 20) {
            statusDot(color: supabase.isConnected ? Color(red: 0.2, green: 0.6, blue: 0.2) : .gray, label: "Online")
            statusDot(color: IDKTheme.accent.opacity(0.8), label: "v2.0")
            statusDot(color: IDKTheme.silverDark, label: "Beta")
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
                .foregroundStyle(IDKTheme.inkSoft)
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 9))
                .foregroundStyle(IDKTheme.inkSoft)
            Text("Hecho por didierxitx7")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(IDKTheme.inkSoft)
        }
        .shadow(color: Color.white.opacity(0.9), radius: 4)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: appeared)
    }
    
    // MARK: - Login Logic (SIN CAMBIOS)
    
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
    
    // MARK: - Handle Login Error (SIN CAMBIOS)
    
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
    
    // MARK: - Shake Animation (SIN CAMBIOS)
    
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
