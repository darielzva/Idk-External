import SwiftUI

struct RevokedAccessView: View {
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color(red: 0.6, green: 0.1, blue: 0.1).opacity(0.3),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.8, green: 0.1, blue: 0.1).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                    
                    Circle()
                        .stroke(
                            Color(red: 0.9, green: 0.2, blue: 0.2),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.slash.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(Color(red: 0.9, green: 0.2, blue: 0.2))
                }
                
                VStack(spacing: 12) {
                    Text("ACCESO REVOCADO")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white)
                    
                    Text("Tu key ha sido desactivada, baneada o expirada.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Contacta al administrador para más información.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Text("Hecho por didierxitx7")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            // Vibración al entrar
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}
