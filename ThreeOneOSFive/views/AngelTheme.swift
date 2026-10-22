import SwiftUI

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