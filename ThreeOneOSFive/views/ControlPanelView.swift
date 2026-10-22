import SwiftUI
import UIKit

// MARK: - Tema visual XL3 (oscuro + amarillo paja + rojo, combina con el fondo)

private enum XLTheme {
    /// Nombre del asset de la imagen de fondo (Assets.xcassets)
    static let backgroundImageName = "XLBackground"

    // Texto claro sobre cristal oscuro
    static let ink = Color.white
    static let inkSoft = Color.white.opacity(0.62)
    static let inkFaint = Color.white.opacity(0.38)

    /// Amarillo del sombrero de paja
    static let accent = Color(red: 0.97, green: 0.78, blue: 0.20)
    /// Rojo de la banda del sombrero
    static let accentRed = Color(red: 0.86, green: 0.17, blue: 0.20)
    static let warning = Color(red: 1.00, green: 0.55, blue: 0.20)
    static let ok = Color(red: 0.30, green: 0.80, blue: 0.42)
    static let danger = Color(red: 1.00, green: 0.42, blue: 0.42)

    /// Borde del cristal: amarillo -> casi transparente -> rojo
    static var edgeStroke: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.65), Color.white.opacity(0.10), accentRed.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Estilo "cristal" reutilizable

private struct XLGlass: ViewModifier {
    var radius: CGFloat = 16
    var tint: Color = Color.black.opacity(0.35)
    var strokeColor: AnyShapeStyle = AnyShapeStyle(XLTheme.edgeStroke)
    /// false = sin desenfoque, deja ver la foto de fondo con nitidez
    var useMaterial: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if useMaterial {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                    }
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(tint)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

private extension View {
    func xlGlass(radius: CGFloat = 16,
                  tint: Color = Color.black.opacity(0.35),
                  stroke: AnyShapeStyle = AnyShapeStyle(XLTheme.edgeStroke),
                  material: Bool = true) -> some View {
        modifier(XLGlass(radius: radius, tint: tint, strokeColor: stroke, useMaterial: material))
    }
}

// MARK: - Modelo de toggle

struct PatchToggle: Identifiable {
    let id: String
    let displayName: String
    let patchFilename: String
    let icon: String
    let category: PatchCategory
    
    var isDynamic: Bool = false
    var isBlocked: Bool = false
    var blockMessage: String? = nil
    var downloadURL: String? = nil
    var remoteID: String? = nil
    
    var fullFilename: String { "\(patchFilename).3105" }
    var normalizedName: String { Self.normalize(patchFilename) }
    
    static func normalize(_ name: String) -> String {
        var result = name
        if result.lowercased().hasSuffix(".3105") {
            result = String(result.dropLast(5))
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: " -_"))
        result = result.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return result.uppercased()
    }
}

enum PatchCategory: String, CaseIterable, Identifiable {
    case aimbot = "Aimbot"
    case hologramas = "Hologramas"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .aimbot: return "scope"
        case .hologramas: return "cube.transparent"
        }
    }
}

// MARK: - Registro de parches por modo (hardcodeados)

enum PatchRegistry {
    static func toggles(for mode: FFMode) -> [PatchToggle] {
        return []
    }
}

// MARK: - Panel principal

struct ControlPanelView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var supabase: SupabaseService
    @EnvironmentObject private var patchesStore: PatchesStore
    @EnvironmentObject private var announcementsStore: AnnouncementsStore
    @State private var selectedCategory: PatchCategory = .aimbot
    @State private var activeToggles: Set<String> = []
    @State private var processingToggles: Set<String> = []
    @State private var toast: ToastMessage? = nil
    @State private var showSettings = false
    @State private var alert: PatchStoreAlert? = nil
    @State private var showLogoutConfirmation = false
    @State private var appeared = false
    
    private var mode: FFMode { session.selectedMode ?? .normal }
    
    private var allToggles: [PatchToggle] {
        let hardcoded = PatchRegistry.toggles(for: mode)
        let dynamic = buildDynamicToggles(for: mode)
        return hardcoded + dynamic
    }
    
    private var toggles: [PatchToggle] {
        allToggles.filter { $0.category == selectedCategory }
    }
    
    private func buildDynamicToggles(for mode: FFMode) -> [PatchToggle] {
        let modeString = (mode == .normal) ? "normal" : "max"
        
        return patchesStore.remotePatches.compactMap { remote in
            guard remote.mode == modeString || remote.mode == "both" else {
                return nil
            }
            
            let category: PatchCategory
            switch remote.category.lowercased() {
            case "aimbot":
                category = .aimbot
            case "hologramas", "hologram":
                category = .hologramas
            default:
                category = .aimbot
            }
            
            return PatchToggle(
                id: remote.patchKey,
                displayName: remote.displayName,
                patchFilename: remote.patchFilename,
                icon: remote.icon,
                category: category,
                isDynamic: true,
                isBlocked: remote.isBlocked,
                blockMessage: remote.blockMessage,
                downloadURL: remote.downloadUrl,
                remoteID: remote.id
            )
        }
    }
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 0) {
                header
                    .padding(.top, 8)
                
                if !announcementsStore.visibleBanners.isEmpty {
                    AnnouncementBannersContainer(
                        announcements: announcementsStore.visibleBanners,
                        onDismiss: { id in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                announcementsStore.dismiss(id)
                            }
                        }
                    )
                    .padding(.top, 8)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Espacio para dejar ver el sombrero de la imagen de fondo
                        Color.clear.frame(height: 170)
                        
                        profileBanner
                        
                        statusChips
                        
                        categoryTabs
                        
                        patchesList
                        
                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            
            if let toast {
                VStack {
                    Spacer()
                    ToastView(message: toast)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.titleKey),
                message: Text(alert.messageKey),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Cerrar sesión",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cerrar sesión", role: .destructive) {
                performLogout()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Si cierras sesión deberás ingresar tu key de nuevo.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            syncToggleStates()
            Task {
                await loadDynamicPatchesIfNeeded()
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
            
            // Velo suave abajo para que el texto siempre se lea bien
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.10), location: 0.0),
                    .init(color: Color.black.opacity(0.15), location: 0.45),
                    .init(color: Color.black.opacity(0.55), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header
    
    private func glassCircleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(XLTheme.ink.opacity(0.85))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                        .overlay(Circle().fill(Color.black.opacity(0.35)))
                )
                .overlay(Circle().strokeBorder(XLTheme.edgeStroke, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                // Botón atrás (izquierda)
                glassCircleButton(systemName: "chevron.left") {
                    withAnimation {
                        session.selectedMode = nil
                        activeToggles.removeAll()
                    }
                }
                
                Spacer()
                
                // Logo centrado
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [XLTheme.accent.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 40
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .strokeBorder(XLTheme.edgeStroke, lineWidth: 2)
                        .frame(width: 54, height: 54)
                        .shadow(color: XLTheme.accent.opacity(0.7), radius: 10)
                    
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 3)
                }
                
                Spacer()
                
                // Botón logout (derecha)
                glassCircleButton(systemName: "rectangle.portrait.and.arrow.right") {
                    showLogoutConfirmation = true
                }
            }
            .padding(.horizontal, 20)
            
            // Nombre y subtítulo centrados
            VStack(spacing: 2) {
                Text("XL3 IOS NEW")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(XLTheme.ink.opacity(0.75))
                    .tracking(3)
                
                Text("Panel de control")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(XLTheme.ink)
            }
            .shadow(color: Color.black.opacity(0.85), radius: 6)
        }
    }
    
    // MARK: - Profile Banner
    
    private var profileBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay(Circle().strokeBorder(XLTheme.edgeStroke, lineWidth: 1))
                
                Image(systemName: "person.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(XLTheme.ink.opacity(0.75))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(supabase.currentKey?.keyValue ?? "SIN KEY")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(XLTheme.ink)
                    .lineLimit(1)
                
                Text(supabase.currentKey?.label ?? "Usuario")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(XLTheme.inkSoft)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(daysRemainingText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(keyStatusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            Capsule()
                                .fill(keyStatusColor.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(keyStatusColor.opacity(0.45), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .xlGlass(radius: 18)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }
    
    // MARK: - Status Chips (iOS + Modelo)
    
    private var statusChips: some View {
        HStack(spacing: 8) {
            // Chip de modo FF
            chipView(
                icon: "gamecontroller.fill",
                text: mode.displayName,
                color: XLTheme.ink.opacity(0.8),
                iconColor: XLTheme.accent
            )
            
            // Chip de iOS
            chipView(
                icon: "applelogo",
                text: "iOS \(UIDevice.current.systemVersion)",
                color: XLTheme.ink.opacity(0.8),
                iconColor: XLTheme.inkSoft
            )
            
            // Chip de modelo
            chipView(
                icon: "iphone",
                text: deviceModelIdentifier,
                color: XLTheme.ink.opacity(0.8),
                iconColor: XLTheme.inkSoft
            )
            
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }
    
    private func chipView(icon: String, text: String, color: Color, iconColor: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                .overlay(Capsule().fill(Color.black.opacity(0.35)))
        )
        .overlay(Capsule().strokeBorder(XLTheme.edgeStroke, lineWidth: 1))
    }
    
    /// Identificador del modelo real (ej: iPhone12,1)
    private var deviceModelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(PatchCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 12, weight: .semibold))
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(
                            selectedCategory == category
                                ? XLTheme.ink
                                : XLTheme.inkFaint
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            
            GeometryReader { geo in
                let width = geo.size.width / CGFloat(PatchCategory.allCases.count)
                let index = PatchCategory.allCases.firstIndex(of: selectedCategory) ?? 0
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                XLTheme.accent,
                                XLTheme.accent.opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.5, height: 3)
                    .shadow(color: XLTheme.accent.opacity(0.5), radius: 4)
                    .offset(x: width * CGFloat(index) + (width * 0.25))
                    .animation(.easeInOut(duration: 0.25), value: selectedCategory)
            }
            .frame(height: 3)
            .padding(.bottom, 2)
        }
        .xlGlass(radius: 16)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }
    
    // MARK: - Patches List
    
    private var patchesList: some View {
        VStack(spacing: 10) {
            if toggles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(XLTheme.inkFaint)
                    Text("No hay parches disponibles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(XLTheme.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .xlGlass(radius: 16)
            } else {
                ForEach(toggles) { toggle in
                    ToggleRow(
                        toggle: toggle,
                        isOn: activeToggles.contains(toggle.id),
                        isProcessing: processingToggles.contains(toggle.id),
                        onToggle: { newValue in
                            handleToggle(toggle, isOn: newValue)
                        }
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9))
                .foregroundStyle(XLTheme.inkSoft)
            Text("XL3 IOS NEW v2.0")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(XLTheme.inkSoft)
            Text("·")
                .font(.system(size: 10))
                .foregroundStyle(XLTheme.inkFaint)
            Text("Hecho por didierxitx7")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(XLTheme.inkSoft)
        }
        .shadow(color: Color.black.opacity(0.85), radius: 4)
        .padding(.top, 20)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
    }
    
    // MARK: - Cargar parches dinámicos
    
    private func loadDynamicPatchesIfNeeded() async {
        if !patchesStore.remotePatches.isEmpty { return }
        
        do {
            let patches = try await patchesStore.fetchPatches()
            log("panel: \(patches.count) parches dinámicos cargados")
            await patchesStore.downloadAllPatches(patches)
        } catch {
            log("panel: error cargando parches dinámicos: \(error)")
        }
    }
    
    // MARK: - Key Helpers
    
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
    
    private var keyStatusColor: Color {
        guard let key = supabase.currentKey else { return XLTheme.inkSoft }
        
        if key.isBanned {
            return XLTheme.danger
        }
        
        if let expiresAt = key.expiresAt,
           let date = parseSupabaseDate(expiresAt) {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days < 0 {
                return XLTheme.danger
            }
            if days <= 3 {
                return XLTheme.warning
            }
        }
        
        return XLTheme.ok
    }
    
    // MARK: - Lógica de toggle (SIN CAMBIOS)
    
    private func handleToggle(_ toggle: PatchToggle, isOn: Bool) {
        guard !processingToggles.contains(toggle.id) else { return }
        
        if toggle.isBlocked && isOn {
            showBlockAlert(toggle)
            return
        }
        
        if isOn {
            let conflictingToggles = toggles.filter {
                $0.category == toggle.category && activeToggles.contains($0.id)
            }
            
            if !conflictingToggles.isEmpty {
                for conflict in conflictingToggles {
                    deactivatePatchSilently(conflict)
                }
            }
            
            activatePatch(toggle)
        } else {
            deactivatePatch(toggle)
        }
    }
    
    private func showBlockAlert(_ toggle: PatchToggle) {
        alert = PatchStoreAlert(
            titleKey: "Opción en mantenimiento",
            messageKey: toggle.blockMessage ?? "Esta opción no está disponible en este momento."
        )
    }
    
    private func activatePatch(_ toggle: PatchToggle) {
        processingToggles.insert(toggle.id)
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let item = await findLibraryItem(for: toggle) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        showToast(
                            "Parche no encontrado: \(toggle.fullFilename)",
                            icon: "exclamationmark.triangle.fill",
                            color: XLTheme.danger
                        )
                    }
                    return
                }
                
                let project: PatchProject
                if item.summary.schemaVersion >= 2 && item.canInspectContents {
                    project = try PatchProjectLibrary.synchronizeWorkspace(item: item)
                } else {
                    guard let p = item.project else {
                        throw PatchPackageError.invalidProject
                    }
                    project = p
                }
                
                _ = try DevicePatchService.apply(project: project)
                
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    activeToggles.insert(toggle.id)
                    patchStore.reload()
                    showToast(
                        "Parche activado con éxito",
                        icon: "checkmark.circle.fill",
                        color: XLTheme.ok
                    )
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error: \(error.localizationKey)",
                        icon: "exclamationmark.triangle.fill",
                        color: XLTheme.danger
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al activar el parche",
                        icon: "exclamationmark.triangle.fill",
                        color: XLTheme.danger
                    )
                }
            }
        }
    }
    
    private func deactivatePatch(_ toggle: PatchToggle) {
        processingToggles.insert(toggle.id)
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let item = await findLibraryItem(for: toggle) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        activeToggles.remove(toggle.id)
                        showToast(
                            "Parche desactivado",
                            icon: "xmark.circle.fill",
                            color: .white.opacity(0.75)
                        )
                    }
                    return
                }
                
                guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        activeToggles.remove(toggle.id)
                        showToast(
                            "Parche desactivado",
                            icon: "xmark.circle.fill",
                            color: .white.opacity(0.75)
                        )
                    }
                    return
                }
                
                try DevicePatchService.restore(receipt: receipt)
                
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    activeToggles.remove(toggle.id)
                    patchStore.reload()
                    showToast(
                        "Parche desactivado",
                        icon: "xmark.circle.fill",
                        color: .white.opacity(0.75)
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al desactivar",
                        icon: "exclamationmark.triangle.fill",
                        color: XLTheme.danger
                    )
                }
            }
        }
    }
    
    private func deactivatePatchSilently(_ toggle: PatchToggle) {
        Task.detached(priority: .userInitiated) {
            guard let item = await findLibraryItem(for: toggle) else { return }
            guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else { return }
            try? DevicePatchService.restore(receipt: receipt)
            await MainActor.run {
                activeToggles.remove(toggle.id)
                patchStore.reload()
            }
        }
    }
    
    private func findLibraryItem(for toggle: PatchToggle) async -> PatchLibraryItem? {
        let targetNormalized = toggle.normalizedName
        return await MainActor.run {
            patchStore.items.first { item in
                let fileNormalized = PatchToggle.normalize(item.packageURL.lastPathComponent)
                return fileNormalized == targetNormalized
            }
        }
    }
    
    private func syncToggleStates() {
        var active: Set<String> = []
        for toggle in allToggles {
            let targetNormalized = toggle.normalizedName
            if let item = patchStore.items.first(where: {
                PatchToggle.normalize($0.packageURL.lastPathComponent) == targetNormalized
            }), DevicePatchService.latestReceipt(projectID: item.id) != nil {
                active.insert(toggle.id)
            }
        }
        activeToggles = active
    }
    
    private func showToast(_ message: String, icon: String, color: Color) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            toast = ToastMessage(message: message, icon: icon, color: color)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                toast = nil
            }
        }
    }
    
    // MARK: - Logout
    
    private func performLogout() {
        supabase.disconnect()
        activeToggles.removeAll()
        processingToggles.removeAll()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            session.selectedMode = nil
            session.isAuthenticated = false
        }
    }
}

// MARK: - Fila de toggle

private struct ToggleRow: View {
    let toggle: PatchToggle
    let isOn: Bool
    let isProcessing: Bool
    let onToggle: (Bool) -> Void
    
    private var statusColor: Color {
        if toggle.isBlocked {
            return XLTheme.warning
        }
        return isOn ? XLTheme.accent : Color.white.opacity(0.35)
    }
    
    private var rowStroke: AnyShapeStyle {
        if toggle.isBlocked {
            return AnyShapeStyle(XLTheme.warning.opacity(0.5))
        }
        if isOn {
            return AnyShapeStyle(XLTheme.accent.opacity(0.55))
        }
        return AnyShapeStyle(XLTheme.edgeStroke)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 3)
                .shadow(color: isOn ? XLTheme.accent.opacity(0.6) : .clear, radius: 4)
                .padding(.vertical, 12)
                .padding(.leading, 6)
            
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: toggle.isBlocked
                                    ? [XLTheme.warning.opacity(0.22), XLTheme.warning.opacity(0.08)]
                                    : (isOn
                                        ? [XLTheme.accent.opacity(0.25), XLTheme.accent.opacity(0.08)]
                                        : [Color.white.opacity(0.20), Color.white.opacity(0.06)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .frame(width: 38, height: 38)
                    
                    if isProcessing {
                        ProgressView()
                            .tint(XLTheme.ink.opacity(0.6))
                            .scaleEffect(0.7)
                    } else if toggle.isBlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(XLTheme.warning)
                    } else {
                        Image(systemName: toggle.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isOn ? XLTheme.accent : XLTheme.ink.opacity(0.75))
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(toggle.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(toggle.isBlocked ? XLTheme.inkFaint : XLTheme.ink)
                        .shadow(color: Color.black.opacity(0.85), radius: 3)
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        Text(toggle.category.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(XLTheme.inkSoft)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.35))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                            )
                        
                        if toggle.isBlocked {
                            Text("En mantenimiento")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(XLTheme.warning)
                        }
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
                .tint(XLTheme.accent)
                .scaleEffect(0.85)
                .disabled(isProcessing || toggle.isBlocked)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
        }
        .xlGlass(
            radius: 16,
            tint: isOn ? XLTheme.accent.opacity(0.12) : Color.black.opacity(0.30),
            stroke: rowStroke,
            material: false
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - Toast

struct ToastMessage: Equatable {
    let message: String
    let icon: String
    let color: Color
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.message == rhs.message
    }
}

private struct ToastView: View {
    let message: ToastMessage
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(message.color)
            Text(message.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(XLTheme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.regularMaterial).environment(\.colorScheme, .dark)
                .overlay(Capsule().fill(Color.black.opacity(0.45)))
        )
        .overlay(Capsule().strokeBorder(XLTheme.edgeStroke, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.35), radius: 14, y: 6)
    }
}
