import SwiftUI

struct ModeSelectionView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var appeared = false
    @State private var showAdvancedSettings = false
    
    private var keyStatus: AngelKeyStatus {
        AngelKeyStatus.make(
            hasKey: supabase.currentKey != nil,
            isBanned: supabase.currentKey?.isBanned ?? false,
            expiresAt: supabase.currentKey?.expiresAt
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AngelBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    AngelHeader(subtitle: "PATCH LIBRARY", online: supabase.isConnected)
                        .padding(.top, 8)
                    
                    versionsCard
                    profileCard
                    advancedSettingsButton
                    
                    AngelSignature()
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Tarjeta de versiones
    
    private var versionsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Listen now")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Selecciona tu versión del juego")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AngelTheme.secondary)
            }
            
            VStack(spacing: 4) {
                modeRow(
                    mode: .normal,
                    title: "FREE FIRE TH",
                    subtitle: "Abrir panel de control",
                    gameImageName: "FFNormalLogo",
                    delay: 0.1
                )
                
                modeRow(
                    mode: .max,
                    title: "FREE FIRE MAX",
                    subtitle: "Abrir panel de control",
                    gameImageName: "FFMaxLogo",
                    delay: 0.2
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .angelCard()
    }
    
    @ViewBuilder
    private func modeRow(
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
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AngelTheme.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
    
    @ViewBuilder
    private func gameIcon(name: String, mode: FFMode) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let tint: Color = mode == .normal ? .orange : .blue
        
        ZStack {
            shape
                .fill(tint.opacity(0.16))
                .frame(width: 52, height: 52)
            
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(shape)
            } else {
                Image(systemName: mode == .normal ? "flame.fill" : "bolt.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
    }
    
    // MARK: - Tarjeta de acceso
    
    private var profileCard: some View {
        let status = keyStatus
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                    .font(.system(size: 16, weight: .bold))
                Text(status.title)
                    .font(.system(size: 16, weight: .heavy))
            }
            .foregroundStyle(status.color)
            
            Text(status.detail)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(supabase.currentKey?.keyValue ?? "SIN KEY")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(supabase.currentKey?.label ?? "Usuario")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AngelTheme.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(status.remaining)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(status.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(status.color.opacity(0.14))
                    )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .angelCard(tint: status.color.opacity(0.35))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }
    
    // MARK: - Ajustes avanzados
    
    private var advancedSettingsButton: some View {
        Button {
            showAdvancedSettings = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Ajustes avanzados")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(AngelTheme.accent)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(AngelTheme.accent.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
        .sheet(isPresented: $showAdvancedSettings) {
            SettingsView()
        }
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
// MARK: - Tema Angel External
// Acento: ámbar/dorado cálido (sale del tono sepia de la imagen y de la llama del encendedor)

enum AngelTheme {
    static let accent      = Color(red: 0.93, green: 0.69, blue: 0.36)
    static let accentLight = Color(red: 0.98, green: 0.88, blue: 0.70)
    static let accentDark  = Color(red: 0.62, green: 0.38, blue: 0.14)
    static let bg          = Color(red: 0.04, green: 0.035, blue: 0.03)
    static let card        = Color(red: 0.11, green: 0.105, blue: 0.10)
    static let stroke      = Color.white.opacity(0.08)
    static let secondary   = Color.white.opacity(0.5)
    static let ok          = Color(red: 0.20, green: 0.80, blue: 0.40)
    static let danger      = Color(red: 0.93, green: 0.30, blue: 0.30)
    static let warn        = Color(red: 1.00, green: 0.60, blue: 0.20)

    static let accentGradient = LinearGradient(
        colors: [accentLight, accent, accentDark],
        startPoint: .topLeading,
        endPoint: .bottomRight
    )

    static let appName = "ANGEL EXTERNAL"
    static let signature = "Hecho por @didierxit7"
}

// MARK: - Fondo

struct AngelBackground: View {
    var body: some View {
        ZStack {
            AngelTheme.bg.ignoresSafeArea()

            RadialGradient(
                colors: [AngelTheme.accent.opacity(0.14), Color.clear],
                center: .init(x: 0.85, y: 0.0),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [AngelTheme.accentDark.opacity(0.10), Color.clear],
                center: .init(x: 0.0, y: 0.65),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Logo (la imagen "Logo" se adapta al recuadro)
// Si el recorte no te gusta, ajusta zoom / focusX / focusY.
// focusX/focusY = punto de la imagen (0...1) que quieres centrar en el recuadro.

struct AngelLogo: View {
    var size: CGFloat = 72
    var zoom: CGFloat = 1.3
    var focusX: CGFloat = 0.68
    var focusY: CGFloat = 0.5

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)

        Image("Logo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .scaleEffect(zoom)
            .offset(
                x: -(focusX - 0.5) * size * zoom,
                y: -(focusY - 0.5) * size * zoom
            )
            .frame(width: size, height: size)
            .clipShape(shape)
            .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 1))
            .shadow(color: AngelTheme.accent.opacity(0.25), radius: 14, y: 4)
    }
}

// MARK: - Header (logo + nombre + estado)

struct AngelHeader: View {
    var subtitle: String = "PATCH LIBRARY"
    var online: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            AngelLogo(size: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(AngelTheme.appName)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(AngelTheme.secondary)
            }

            Spacer(minLength: 4)

            VStack(spacing: 6) {
                Circle()
                    .fill(online ? AngelTheme.ok : Color.gray)
                    .frame(width: 10, height: 10)
                    .shadow(color: (online ? AngelTheme.ok : Color.gray).opacity(0.8), radius: 4)
                Text(online ? "READY" : "OFFLINE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.5)
                    .foregroundStyle(online ? AngelTheme.ok : Color.gray)
            }
        }
    }
}

// MARK: - Tarjeta

extension View {
    func angelCard(corner: CGFloat = 26, tint: Color? = nil) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AngelTheme.card.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(tint ?? AngelTheme.stroke, lineWidth: 1)
                )
        )
    }
}

// MARK: - Firma (al final de cada sección)

struct AngelSignature: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 9))
            Text(AngelTheme.signature)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.45))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Estado de la key

struct AngelKeyStatus {
    let title: String      // ACCESS ACTIVE, etc.
    let detail: String     // texto largo
    let remaining: String  // 3 días, 5h 20m...
    let color: Color
    let icon: String

    static func parseDate(_ string: String) -> Date? {
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

    static func make(hasKey: Bool, isBanned: Bool, expiresAt: String?) -> AngelKeyStatus {
        guard hasKey else {
            return AngelKeyStatus(
                title: "NO KEY",
                detail: "Introduce una key para continuar",
                remaining: "—",
                color: .gray,
                icon: "key.slash"
            )
        }

        if isBanned {
            return AngelKeyStatus(
                title: "ACCESS BANNED",
                detail: "Esta key fue baneada",
                remaining: "Baneada",
                color: AngelTheme.danger,
                icon: "xmark.octagon.fill"
            )
        }

        guard let expiresAt, let date = parseDate(expiresAt) else {
            return AngelKeyStatus(
                title: "ACCESS ACTIVE",
                detail: "Patch access sin expiración",
                remaining: "Sin expiración",
                color: AngelTheme.ok,
                icon: "checkmark.seal.fill"
            )
        }

        let diff = date.timeIntervalSince(Date())

        if diff <= 0 {
            return AngelKeyStatus(
                title: "ACCESS EXPIRED",
                detail: "Tu acceso expiró",
                remaining: "Expirada",
                color: AngelTheme.danger,
                icon: "exclamationmark.triangle.fill"
            )
        }

        let totalMinutes = Int(diff / 60)
        let totalHours = totalMinutes / 60
        let days = totalHours / 24
        let minutes = totalMinutes % 60

        let remaining: String
        if days > 1 {
            remaining = "\(days) días"
        } else if days == 1 {
            remaining = "1 día"
        } else if totalHours >= 1 {
            remaining = "\(totalHours)h \(minutes)m"
        } else {
            remaining = "\(minutes)m"
        }

        let df = DateFormatter()
        df.locale = Locale(identifier: "es")
        df.dateStyle = .medium
        df.timeStyle = .short

        let soon = days <= 3

        return AngelKeyStatus(
            title: soon ? "ACCESS ENDING SOON" : "ACCESS ACTIVE",
            detail: "Patch access hasta: \(df.string(from: date)) · \(remaining)",
            remaining: remaining,
            color: soon ? AngelTheme.warn : AngelTheme.ok,
            icon: soon ? "clock.badge.exclamationmark.fill" : "checkmark.seal.fill"
        )
    }
}
