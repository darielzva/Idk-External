import SwiftUI

// MARK: - Banner individual

struct AnnouncementBanner: View {
    let announcement: RemoteAnnouncement
    let onDismiss: () -> Void
    
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
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icono
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accentColor)
            }
            
            // Texto
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(accentColor.opacity(0.9))
                
                Text(announcement.message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Botón cerrar
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.35), lineWidth: 1)
                
                // Barra lateral de acento
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                    Spacer()
                }
            }
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
        }
    }
}

// MARK: - Container para múltiples anuncios

struct AnnouncementBannersContainer: View {
    let announcements: [RemoteAnnouncement]
    let onDismiss: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(announcements) { ann in
                AnnouncementBanner(announcement: ann) {
                    onDismiss(ann.id)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.3), value: announcements.count)
    }
}
