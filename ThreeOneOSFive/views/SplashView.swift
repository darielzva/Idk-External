import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void
    
    // 🎯 Estados externos (vienen del RootView)
    let externalProgress: Double
    let externalStep: String
    
    // 🎯 Estados internos (animaciones)
    @State private var rotationAngle: Double = 0
    @State private var displayProgress: CGFloat = 0
    @State private var appeared = false
    @State private var glowPulse = false
    @State private var displayStep: String = "INICIANDO SISTEMA..."
    
    // MARK: - Nombre modificado
    private let appName = "IDK"
    
    init(
        externalProgress: Double = 0,
        externalStep: String = "INICIANDO SISTEMA...",
        onFinished: @escaping () -> Void
    ) {
        self.externalProgress = externalProgress
        self.externalStep = externalStep
        self.onFinished = onFinished
    }
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 0) {
                Spacer()
                
                logoSection
                
                Spacer().frame(height: 60)
                
                // Nombre (MODIFICADO: colores oscuros para contraste en fondo claro)
                Text(appName)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.2, blue: 0.2), // Gris oscuro
                                Color(red: 0.4, green: 0.4, blue: 0.4)   // Gris medio
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
                
                Spacer().frame(height: 20)
                
                // 🎯 Texto dinámico (paso actual)
                Text(displayStep)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color.black.opacity(0.6)) // Texto oscuro
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .frame(height: 20)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: displayStep)
                    .opacity(appeared ? 1 : 0)
                
                Spacer().frame(height: 14)
                
                // 🎯 Barra de progreso real
                progressBar
                    .padding(.horizontal, 80)
                    .opacity(appeared ? 1 : 0)
                
                Spacer().frame(height: 8)
                
                // 🎯 Porcentaje
                Text("\(Int(displayProgress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.black.opacity(0.5)) // Texto oscuro
                    .opacity(appeared ? 1 : 0)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: externalProgress) { newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                displayProgress = CGFloat(min(max(newValue, 0), 1))
            }
        }
        .onChange(of: externalStep) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                displayStep = newValue
            }
        }
    }
    
    // MARK: - Background (MODIFICADO: Tonos claros)
    
    private var background: some View {
        ZStack {
            // Fondo base: Blanco hueso / Perla claro
            Color(red: 0.93, green: 0.91, blue: 0.88)
                .ignoresSafeArea()
            
            // Gradiente radial: Brillo blanco puro en el centro
            RadialGradient(
                colors: [
                    Color.white.opacity(glowPulse ? 0.9 : 0.6),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.45),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
            
            // Gradiente sutil beige en la parte inferior
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.85, green: 0.82, blue: 0.78).opacity(0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Logo Section (MODIFICADO: Acentos perla/blancos)
    
    private var logoSection: some View {
        ZStack {
            // Halo pulsante
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(glowPulse ? 0.8 : 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 260, height: 260)
            
            // Anillo de puntos girando (MODIFICADO: puntos oscuros/perla)
            ForEach(0..<28, id: \.self) { i in
                let angle = (Double(i) / 28.0) * 360.0
                let isHighlighted = i % 7 == 0
                
                Circle()
                    .fill(
                        isHighlighted
                            ? Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.9) // Punto oscuro
                            : Color.black.opacity(0.2) // Punto gris suave
                    )
                    .frame(
                        width: isHighlighted ? 4 : 2.5,
                        height: isHighlighted ? 4 : 2.5
                    )
                    .shadow(
                        color: isHighlighted ? .black.opacity(0.2) : .clear,
                        radius: isHighlighted ? 4 : 0
                    )
                    .offset(y: -95)
                    .rotationEffect(.degrees(angle + rotationAngle))
            }
            
            // Anillo conector
            Circle()
                .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(rotationAngle * 0.5))
            
            // Círculo con gradiente (MODIFICADO: perla/blanco)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.9, green: 0.85, blue: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color.white.opacity(0.8), radius: 15)
            
            // Círculo decorativo
            Circle()
                .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                .frame(width: 140, height: 140)
            
            // Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 10)
        }
        .frame(height: 260)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(.easeOut(duration: 0.6), value: appeared)
    }
    
    // MARK: - Progress Bar (MODIFICADO: Estilo claro)
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.black.opacity(0.08)) // Fondo de la barra
                .frame(height: 4)
            
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.6), // Gris oscuro
                            Color(red: 0.2, green: 0.2, blue: 0.2),              // Negro suave
                            Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.8)   // Gris medio
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: displayProgress * 220, height: 4)
                .shadow(color: .black.opacity(0.2), radius: 6)
        }
        .frame(width: 220)
    }
    
    // MARK: - Animaciones (SIN CAMBIOS)
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            appeared = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}
