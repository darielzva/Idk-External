import SwiftUI

// MARK: - Tema visual XL3 (oscuro + amarillo paja + rojo, combina con el fondo)

private enum XLTheme {
    /// Nombre del asset de la imagen de fondo (Assets.xcassets)
    static let backgroundImageName = "XLBackground"

    // Texto claro sobre fondo oscuro
    static let ink = Color.white
    static let inkSoft = Color.white.opacity(0.62)
    static let inkFaint = Color.white.opacity(0.38)

    /// Amarillo del sombrero de paja
    static let accent = Color(red: 0.97, green: 0.78, blue: 0.20)
    /// Rojo de la banda del sombrero
    static let accentRed = Color(red: 0.86, green: 0.17, blue: 0.20)

    /// Borde: amarillo -> casi transparente -> rojo
    static var edgeStroke: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.65), Color.white.opacity(0.10), accentRed.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

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

    // MARK: - Nombre
    private let appName = "XL3 IOS NEW"

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
                // Dos espacios arriba y uno abajo: el contenido queda en la parte
                // baja y se ve el sombrero de la imagen de fondo
                Spacer()
                Spacer()

                logoSection

                Spacer().frame(height: 50)

                // Nombre
                Text(appName)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(XLTheme.ink)
                    .shadow(color: XLTheme.accent.opacity(0.35), radius: 10)
                    .shadow(color: Color.black.opacity(0.85), radius: 6)
                    .padding(.horizontal, 30)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                Spacer().frame(height: 20)

                // 🎯 Texto dinámico (paso actual)
                Text(displayStep)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(XLTheme.ink.opacity(0.75))
                    .shadow(color: Color.black.opacity(0.85), radius: 4)
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
                    .foregroundStyle(XLTheme.inkSoft)
                    .shadow(color: Color.black.opacity(0.85), radius: 4)
                    .opacity(appeared ? 1 : 0)

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

    // MARK: - Background (imagen fija de fondo)

    private var background: some View {
        ZStack {
            // Color base por si la imagen no carga
            Color.black
                .ignoresSafeArea()

            // Imagen a pantalla completa, sin deformarse
            Color.clear
                .overlay(
                    Image(XLTheme.backgroundImageName)
                        .resizable()
                        .scaledToFill()
                )
                .clipped()
                .ignoresSafeArea()

            // Velo oscuro: más fuerte abajo para que el logo y el texto se lean
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.10), location: 0.0),
                    .init(color: Color.black.opacity(0.30), location: 0.45),
                    .init(color: Color.black.opacity(0.70), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Resplandor amarillo que pulsa detrás del logo
            RadialGradient(
                colors: [
                    XLTheme.accent.opacity(glowPulse ? 0.20 : 0.08),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.58),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        ZStack {
            // Halo pulsante
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            XLTheme.accent.opacity(glowPulse ? 0.45 : 0.20),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 260, height: 260)

            // Anillo de puntos girando (puntos amarillos destacados)
            ForEach(0..<28, id: \.self) { i in
                let angle = (Double(i) / 28.0) * 360.0
                let isHighlighted = i % 7 == 0

                Circle()
                    .fill(
                        isHighlighted
                            ? XLTheme.accent.opacity(0.95)
                            : Color.white.opacity(0.35)
                    )
                    .frame(
                        width: isHighlighted ? 4 : 2.5,
                        height: isHighlighted ? 4 : 2.5
                    )
                    .shadow(
                        color: isHighlighted ? XLTheme.accent.opacity(0.7) : .clear,
                        radius: isHighlighted ? 4 : 0
                    )
                    .offset(y: -95)
                    .rotationEffect(.degrees(angle + rotationAngle))
            }

            // Anillo conector
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(rotationAngle * 0.5))

            // Círculo con borde amarillo -> rojo
            Circle()
                .stroke(XLTheme.edgeStroke, lineWidth: 2)
                .frame(width: 120, height: 120)
                .shadow(color: XLTheme.accent.opacity(0.6), radius: 15)

            // Círculo decorativo
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                .frame(width: 140, height: 140)

            // Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 10)
        }
        .frame(height: 260)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(.easeOut(duration: 0.6), value: appeared)
    }

    // MARK: - Progress Bar (rojo -> amarillo)

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.12)) // Fondo de la barra
                .frame(height: 4)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            XLTheme.accentRed,
                            XLTheme.accent
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: displayProgress * 220, height: 4)
                .shadow(color: XLTheme.accent.opacity(0.5), radius: 6)
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
