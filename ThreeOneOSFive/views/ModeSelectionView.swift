import SwiftUI

struct ModeSelectionView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var appeared = false
    @State private var showAdvancedSettings = false
    
    private let title = "PERFILES DARIELMODZ"
    private let subtitle = "Selecciona tu versión del juego"
    private let madeBy = "Hecho por didierxitx7"
    
    // MARK: - Key Helpers
    
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
        
        // Si ya expiró
        if diff <= 0 {
            return "Expirada"
        }
        
        let totalMinutes = Int(diff / 60)
        let totalHours = totalMinutes / 60
        let days = totalHours / 24
        let minutes = totalMinutes % 60
        
        // Más de 1 día
        if days > 1 {
            return "\(days) días"
        }
        // Exactamente 1 día
        if days == 1 {
            return "1 día"
        }
        // Menos de 1 día pero más de 1 hora
        if totalHours >= 1 {
            return "\(totalHours)h \(minutes)m"
        }
        // Menos de 1 hora
        return "\(minutes)m"
    }
    
    /// Parser robusto para fechas de Supabase
    private func parseSupabaseDate(_ string: String) -> Date? {
        // Intento 1: ISO8601 con formato estándar
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: string) { return date }
        
        // Intento 2: formato de Supabase (2026-10-05 05:43:32.053+0)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = df.date(from: string) { return date }
        
        // Intento 3: formato sin milisegundos
        df.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        if let date = df.date(from: string) { return date }
        
        // Intento 4: reemplazar espacio por T
        let fixed = string.replacingOccurrences(of: " ", with: "T")
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: fixed) { return date }
        
        return nil
    }
    
    private var keyStatusColor: Color {
        guard let key = supabase.currentKey else { return .white.opacity(0.5) }
        
        if key.isBanned {
            return Color(red: 0.9, green: 0.3, blue: 0.3)
        }
        
        if let expiresAt = key.expiresAt,
           let date = parseSupabaseDate(expiresAt) {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days < 0 {
                return Color(red: 0.9, green: 0.3, blue: 0.3)
            }
            if days <= 3 {
                return Color(red: 1.0, green: 0.6, blue: 0.2)
            }
        }
        
        return .white
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            background
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    
                    logoHeader
                    
                    Spacer().frame(height: 24)
                    
                    titleSection
                    
                    Spacer().frame(height: 32)
                    
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
                    
                    Spacer().frame(height: 50)
                    
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
    
    // MARK: - Background
    
    private var background: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.1),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Logo Header
    
    private var logoHeader: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
            
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                .frame(width: 110, height: 110)
            
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 90, height: 90)
                .shadow(color: .white.opacity(0.5), radius: 15)
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .clipShape(Circle())
        }
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
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
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
    
    @ViewBuilder
    private func gameIcon(name: String, mode: FFMode) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: mode == .normal
                            ? [Color.orange.opacity(0.3), Color.red.opacity(0.15)]
                            : [Color.blue.opacity(0.3), Color.cyan.opacity(0.15)],
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: mode == .normal ? "flame.fill" : "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(mode == .normal ? Color.orange : Color.blue)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(keyDisplayName)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(supabase.currentKey?.label ?? "Usuario")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(daysRemainingText)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(keyStatusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(keyStatusColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(keyStatusColor.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
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
            .foregroundStyle(.white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
            .foregroundStyle(.white.opacity(0.5))
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
