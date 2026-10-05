import SwiftUI

struct MaintenanceView: View {
    let message: String
    
    @State private var appeared = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Fondo negro
            Color.black
                .ignoresSafeArea()
            
            // Glow naranja radial
            RadialGradient(
                colors: [
                    Color.orange.opacity(0.15),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icono animado
                maintenanceIcon
                
                // Título
                VStack(spacing: 12) {
                    Text("MANTENIMIENTO")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white)
                    
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)
                
                Spacer()
                
                // Footer
                HStack(spacing: 6) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Volveremos pronto")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: appeared)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
    
    // MARK: - Icono animado
    
    private var maintenanceIcon: some View {
        ZStack {
            // Halo pulsante
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(pulseScale)
            
            // Anillo exterior punteado
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                .frame(width: 200, height: 200)
            
            // Anillo giratorio con dash
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.orange.opacity(0),
                            Color.orange.opacity(0.8),
                            Color.orange.opacity(0),
                            Color.orange.opacity(0.5),
                            Color.orange.opacity(0)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 10])
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(rotationAngle))
            
            // Anillo interior
            Circle()
                .stroke(Color.orange, lineWidth: 2)
                .frame(width: 110, height: 110)
                .shadow(color: .orange.opacity(0.6), radius: 20)
            
            // Icono
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, Color(red: 1.0, green: 0.8, blue: 0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 280)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.85)
        .animation(.easeOut(duration: 0.7), value: appeared)
    }
}
