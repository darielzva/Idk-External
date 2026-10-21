import SwiftUI

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
    static let warning = Color(red: 0.92, green: 0.58, blue: 0.20)

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
                    .strokeBorder(strokeColor, lineWidth: 1)
            )
            .shadow(color: IDKTheme.silverDark.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

private extension View {
    func idkGlass(radius: CGFloat = 16,
                  tint: Color = Color.white.opacity(0.30),
                  stroke: AnyShapeStyle = AnyShapeStyle(IDKTheme.silverStroke)) -> some View {
        modifier(IDKGlass(radius: radius, tint: tint, strokeColor: stroke))
    }
}

// MARK: - Selección de modo

struct ModeSelectionView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var appeared = false
    @State private var showAdvancedSettings = false
    
    // MARK: - TÍTULO
    private let title = "IDK"
    private let subtitle = "Selecciona tu versión del juego"
    private let madeBy = "Hecho por didierxitx7"
    
    // MARK: - Key Helpers (SIN CAMBIOS)
    
    private var keyDisplayName: String {
        supabase.currentKey?.keyValue ?? "SIN KEY"
    }
    
    private var daysRemainingText: String {
        guard let key = supabase.currentKey else { return "—" }
        
        if key.isBanned {
            return "Baneada"
        }
        
        guard let expiresAt = key.expiresAt,
              let date = parseSupabaseDate(expiresAt) else {
            return "Sin expiración"
        }
        
        let now = Date()
        let diff = date.timeIntervalSince(now)
        
        if diff <= 0 {
            return "Expirada"
        }
        
        let totalMinutes = Int(diff / 60)
        let totalHours = totalMinutes / 60
        let days = totalHours / 24
        let minutes = totalMinutes % 60
        
        if days > 1 {
            return "\(days) días"
        }
        if days == 1 {
            return "1 día"
        }
        if totalHours >= 1 {
            return "\(totalHours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func parseSupabaseDate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: string) { return date }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = df.date(from: string) { return date }
        
        df.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        if let date = df.date(from: string) { return date }
        
        let fixed = string.replacingOccurrences(of: " ", with: "T")
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: fixed) { return date }
        
        return nil
    }
    
    /// Mismos estados que antes (baneada / por vencer / ok). Solo ajusté los
    /// colores neutros para que se lean sobre el cristal claro.
    private var keyStatusColor: Color {
        guard let key = supabase.currentKey else { return IDKTheme.inkSoft }
        
        if key.isBanned {
            return Color(red: 0.8, green: 0.3, blue: 0.3) // Rojo suave
        }
        
        if let expiresAt = key.expiresAt,
           let date = parseSupabaseDate(expiresAt) {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days < 0 {
                return Color(red: 0.8, green: 0.3, blue: 0.3)
            }
            if days <= 3 {
                return Color(red: 0.85, green: 0.65, blue: 0.3) // Naranja suave
            }
        }
        
        return IDKTheme.accent // Azul hielo (antes blanco perla)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            background
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
                    logoHeader
                    
                    Spacer().frame(height: 10)
                    
                    titleSection
                    
                    // Espacio para dejar ver al ángel y el logo de la imagen
                    Spacer().frame(height: 150)
                    
                    subtitlePill
                    
                    Spacer().frame(height: 18)
                    
                    VStack(spacing: 14) {
                        modeCard(
                            mode: .normal,
                            title: "FREE FIRE TH",
                            subtitle: "Abrir panel de control",
                            gameImageName: "FFNormalLogo",
                            delay: 0.1
                        )
                        
                        modeCard(
                            mode: .max,
                            title: "FREE FIRE MAX",
                            subtitle: "Abrir panel de control",
                            gameImageName: "FFMaxLogo",
                            delay: 0.2
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 20)
                    
                    profileCard
                        .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 24)
                    
                    advancedSettingsButton
                    
                    Spacer().frame(height: 40)
                    
                    footerSection
                    
                    Spacer().frame(height: 30)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
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
            
            // Velo suave abajo para que el contenido se lea bien
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.0), location: 0.0),
                    .init(color: Color.white.opacity(0.10), location: 0.45),
                    .init(color: Color.white.opacity(0.35), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Logo Header (compacto, plata)
    
    private var logoHeader: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.9), Color.clear],
                        center: .center,
                        startRadius: 12,
                        endRadius: 52
                    )
                )
                .frame(width: 104, height: 104)
            
            Circle()
                .strokeBorder(IDKTheme.silverStroke, lineWidth: 2.5)
                .frame(width: 70, height: 70)
                .shadow(color: Color.white.opacity(0.9), radius: 12)
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 4)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.92)
        .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        Text(title)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .tracking(5)
            .foregroundStyle(IDKTheme.ink.opacity(0.85))
            .shadow(color: Color.white.opacity(0.9), radius: 6)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }
    
    // MARK: - Subtítulo en cápsula de cristal
    
    private var subtitlePill: some View {
        Text(subtitle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(IDKTheme.ink.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(Color.white.opacity(0.30)))
            )
            .overlay(Capsule().strokeBorder(IDKTheme.silverStroke, lineWidth: 1))
            .shadow(color: IDKTheme.silverDark.opacity(0.2), radius: 8, y: 4)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }
    
    // MARK: - Mode Card
    
    @ViewBuilder
    private func modeCard(
        mode: FFMode,
        title: String,
        subtitle: String,
        gameImageName: String,
        delay: Double
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                session.selectedMode = mode
            }
        } label: {
            HStack(spacing: 14) {
                gameIcon(name: gameImageName, mode: mode)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(IDKTheme.ink)
                        .tracking(0.5)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(IDKTheme.inkSoft)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .overlay(Circle().strokeBorder(IDKTheme.silverStroke, lineWidth: 1))
                        .frame(width: 30, height: 30)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(IDKTheme.ink.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .idkGlass(radius: 18)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
    
    @ViewBuilder
    private func gameIcon(name: String, mode: FFMode) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: mode == .normal
                            ? [IDKTheme.warning.opacity(0.30), IDKTheme.warning.opacity(0.10)]
                            : [Color.white.opacity(0.9), IDKTheme.silverMid.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
            
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: mode == .normal ? "flame.fill" : "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        mode == .normal
                            ? IDKTheme.warning
                            : IDKTheme.accent
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
        )
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
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
                
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(IDKTheme.ink.opacity(0.75))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(keyDisplayName)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(IDKTheme.ink)
                    .lineLimit(1)
                
                Text(supabase.currentKey?.label ?? "Usuario")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(IDKTheme.inkSoft)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(daysRemainingText)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(keyStatusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .overlay(Capsule().fill(keyStatusColor.opacity(0.12)))
                        .overlay(Capsule().stroke(keyStatusColor.opacity(0.45), lineWidth: 1))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .idkGlass(radius: 18)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }
    
    // MARK: - Advanced Settings Button
    
    private var advancedSettingsButton: some View {
        Button {
            showAdvancedSettings = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Ajustes avanzados")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(IDKTheme.ink.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(Color.white.opacity(0.30)))
            )
            .overlay(Capsule().strokeBorder(IDKTheme.silverStroke, lineWidth: 1))
            .shadow(color: IDKTheme.silverDark.opacity(0.2), radius: 8, y: 4)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
        .sheet(isPresented: $showAdvancedSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        Text(madeBy)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(IDKTheme.inkSoft)
            .shadow(color: Color.white.opacity(0.9), radius: 4)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
    }
}

// MARK: - Scale Button Style (SIN CAMBIOS)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
