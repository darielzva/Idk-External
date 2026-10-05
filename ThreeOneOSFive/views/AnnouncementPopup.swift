import SwiftUI

struct AnnouncementPopup: View {
    let announcement: RemoteAnnouncement
    let onDismiss: () -> Void
    let onRestart: () -> Void
    
    @State private var appeared = false
    
    // MARK: - Colores según tipo
    
    private var accentColor: Color {
        switch announcement.type {
        case "success": return Color(red: 0.29, green: 0.87, blue: 0.50)
        case "warning": return Color(red: 0.96, green: 0.62, blue: 0.04)
        case "danger": return Color(red: 0.94, green: 0.27, blue: 0.27)
        default: return Color(red: 0.23, green: 0.51, blue: 0.96)
        }
    }
    
    private var iconName: String {
        switch announcement.type {
        case "success": return "checkmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        case "danger": return "exclamationmark.octagon.fill"
        default: return "info.circle.fill"
        }
    }
    
    private var titleText: String {
        switch announcement.type {
        case "success": return "ÉXITO"
        case "warning": return "ADVERTENCIA"
        case "danger": return "AVISO IMPORTANTE"
        default: return "INFORMACIÓN"
        }
    }
    
    var body: some View {
        ZStack {
            // Fondo oscuro
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Solo cierra si se permite
                    if announcement.canDismiss && !announcement.forceRestart {
                        onDismiss()
                    }
                }
            
            // Contenido del popup
            VStack(spacing: 24) {
                Spacer()
                
                // Icono grande con halo
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    accentColor.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .stroke(accentColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                
                // Título
                Text(titleText)
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(accentColor)
                    .opacity(appeared ? 1 : 0)
                
                // Mensaje
                Text(announcement.message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appeared ? 1 : 0)
                
                Spacer()
                
                // Botones
                VStack(spacing: 10) {
                    // Botón Reiniciar (si force_restart)
                    if announcement.forceRestart {
                        Button {
                            onRestart()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .bold))
                                Text("REINICIAR APP")
                                    .font(.system(size: 14, weight: .heavy))
                                    .tracking(2)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(accentColor)
                                    .shadow(color: accentColor.opacity(0.4), radius: 12, y: 4)
                            )
                        }
                    }
                    
                    // Botón Entendido (si can_dismiss y no force_restart)
                    if announcement.canDismiss && !announcement.forceRestart {
                        Button {
                            onDismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                Text("ENTENDIDO")
                                    .font(.system(size: 14, weight: .heavy))
                                    .tracking(2)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
            // Vibración según tipo
            let generator = UINotificationFeedbackGenerator()
            switch announcement.type {
            case "success": generator.notificationOccurred(.success)
            case "warning": generator.notificationOccurred(.warning)
            case "danger": generator.notificationOccurred(.error)
            default: generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Container para múltiples popups

struct AnnouncementPopupsContainer: View {
    let announcements: [RemoteAnnouncement]
    let onDismiss: (String) -> Void
    let onRestart: () -> Void
    
    var body: some View {
        if let first = announcements.first {
            AnnouncementPopup(
                announcement: first,
                onDismiss: { onDismiss(first.id) },
                onRestart: onRestart
            )
        }
    }
}
