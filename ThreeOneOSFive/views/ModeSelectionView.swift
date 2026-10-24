import SwiftUI

// MARK: - Selección de modo

struct ModeSelectionView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var appeared = false
    @State private var showAdvancedSettings = false

    // MARK: - TÍTULO
    private let title = SITheme.appName
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

    /// Mismos estados que antes (baneada / por vencer / ok).
    private var keyStatusColor: Color {
        guard let key = supabase.currentKey else { return SITheme.inkSoft }

        if key.isBanned {
            return SITheme.danger
        }

        if let expiresAt = key.expiresAt,
           let date = parseSupabaseDate(expiresAt) {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days < 0 {
                return SITheme.danger
            }
            if days <= 3 {
                return SITheme.warning
            }
        }

        return SITheme.accent
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SIBackground(imageTop: 112, imageWidthRatio: 0.72)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 14)

                    header

                    // Espacio para dejar ver la imagen de fondo
                    Spacer().frame(height: 250)

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

                    Spacer().frame(height: 18)

                    profileCard
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 22)

                    advancedSettingsButton

                    Spacer().frame(height: 32)

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

    // MARK: - Header (logo a la izquierda + nombre)

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SITheme.accent.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 44
                        )
                    )
                    .frame(width: 80, height: 80)

                SILogo(size: 52)

                Circle()
                    .strokeBorder(SITheme.ringStroke, lineWidth: 2)
                    .frame(width: 58, height: 58)
                    .shadow(color: SITheme.accent.opacity(0.6), radius: 8)
            }
            .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 19, weight: .heavy))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(SITheme.ink)

                HStack(spacing: 6) {
                    Circle()
                        .fill(SITheme.ok)
                        .frame(width: 6, height: 6)
                        .shadow(color: SITheme.ok.opacity(0.7), radius: 3)
                    Text("PANEL ACTIVO")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(SITheme.accent)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96, anchor: .leading)
        .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)
    }

    // MARK: - Subtítulo

    private var subtitlePill: some View {
        Text(subtitle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(SITheme.ink.opacity(0.85))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(SITheme.card.opacity(0.92)))
            .overlay(Capsule().strokeBorder(SITheme.edgeStroke, lineWidth: 1))
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
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(0.5)
                        .foregroundColor(SITheme.ink)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SITheme.inkSoft)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SITheme.accent)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(SITheme.accent.opacity(0.14))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .siCard(radius: 14)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }

    @ViewBuilder
    private func gameIcon(name: String, mode: FFMode) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: mode == .normal
                            ? [SITheme.warning.opacity(0.30), SITheme.warning.opacity(0.10)]
                            : [SITheme.accent.opacity(0.30), SITheme.accentDeep.opacity(0.12)],
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
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: mode == .normal ? "flame.fill" : "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(mode == .normal ? SITheme.warning : SITheme.accent)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SITheme.accent.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(SITheme.accent.opacity(0.45), lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SITheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(keyDisplayName)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(SITheme.ink)
                    .lineLimit(1)

                Text(supabase.currentKey?.label ?? "Usuario")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SITheme.inkSoft)
                    .lineLimit(1)
            }

            Spacer()

            Text(daysRemainingText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(keyStatusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(keyStatusColor.opacity(0.14))
                        .overlay(Capsule().stroke(keyStatusColor.opacity(0.5), lineWidth: 1))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .siCard(radius: 14, tab: false)
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
            .foregroundColor(SITheme.ink.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(SITheme.card.opacity(0.92)))
            .overlay(Capsule().strokeBorder(SITheme.edgeStroke, lineWidth: 1))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
        .sheet(isPresented: $showAdvancedSettings) {
            SettingsView()
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(SITheme.edgeStroke)
                .frame(width: 70, height: 1)
            Text(madeBy)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(SITheme.inkSoft)
        }
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