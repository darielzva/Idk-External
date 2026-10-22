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