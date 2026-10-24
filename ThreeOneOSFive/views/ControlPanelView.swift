import SwiftUI
import UIKit

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
            SIBackground(imageTop: 186, imageWidthRatio: 0.70)

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
                    VStack(spacing: 14) {
                        // Espacio para dejar ver la imagen de fondo
                        Color.clear.frame(height: 272)

                        profileBanner

                        statusStrip

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

    // MARK: - Header

    private func circleButton(systemName: String, tint: Color = SITheme.ink, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 40, height: 40)
                .background(Circle().fill(SITheme.card.opacity(0.92)))
                .overlay(Circle().strokeBorder(SITheme.edgeStroke, lineWidth: 1))
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                // Botón atrás (izquierda)
                circleButton(systemName: "chevron.left") {
                    withAnimation {
                        session.selectedMode = nil
                        activeToggles.removeAll()
                    }
                }

                Spacer()

                // Logo principal (centro)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [SITheme.accent.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 46
                            )
                        )
                        .frame(width: 84, height: 84)

                    SILogo(size: 56)

                    Circle()
                        .strokeBorder(SITheme.ringStroke, lineWidth: 2)
                        .frame(width: 62, height: 62)
                        .shadow(color: SITheme.accent.opacity(0.6), radius: 8)
                }

                Spacer()

                // Botón logout (derecha)
                circleButton(systemName: "rectangle.portrait.and.arrow.right", tint: SITheme.accentRed) {
                    showLogoutConfirmation = true
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 2) {
                Text(SITheme.appName)
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2.5)
                    .foregroundColor(SITheme.accent)

                Text("Panel de control")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(SITheme.ink)
            }
        }
    }

    // MARK: - Profile Banner

    private var profileBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SITheme.accent.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(SITheme.accent.opacity(0.45), lineWidth: 1)
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "person.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(SITheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(supabase.currentKey?.keyValue ?? "SIN KEY")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(SITheme.ink)
                    .lineLimit(1)

                Text(supabase.currentKey?.label ?? "Usuario")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SITheme.inkSoft)
                    .lineLimit(1)
            }

            Spacer()

            Text(daysRemainingText)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(keyStatusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(keyStatusColor.opacity(0.14))
                        .overlay(
                            Capsule()
                                .stroke(keyStatusColor.opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .siCard(radius: 14)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    // MARK: - Status Strip (modo + iOS + modelo en una sola tarjeta)

    private var statusStrip: some View {
        HStack(spacing: 0) {
            stripItem(icon: "gamecontroller.fill", text: mode.displayName, tint: SITheme.accent)
            stripDivider
            stripItem(icon: "applelogo", text: "iOS \(UIDevice.current.systemVersion)", tint: SITheme.inkSoft)
            stripDivider
            stripItem(icon: "iphone", text: deviceModelIdentifier, tint: SITheme.inkSoft)
        }
        .padding(.vertical, 11)
        .siCard(radius: 14, tab: false)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func stripItem(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(tint)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(SITheme.ink.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 16)
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

    // MARK: - Category Tabs (selector tipo píldora)

    private var categoryTabs: some View {
        HStack(spacing: 6) {
            ForEach(PatchCategory.allCases) { category in
                let selected = selectedCategory == category
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 12, weight: .bold))
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(selected ? Color.black.opacity(0.88) : SITheme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        Capsule().fill(
                            selected
                                ? AnyShapeStyle(SITheme.accentGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                    )
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(SITheme.card.opacity(0.92)))
        .overlay(Capsule().strokeBorder(SITheme.edgeStroke, lineWidth: 1))
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }

    // MARK: - Patches List

    private var activeInCategory: Int {
        toggles.filter { activeToggles.contains($0.id) }.count
    }

    private var patchesList: some View {
        VStack(spacing: 10) {
            HStack {
                Text(selectedCategory.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(SITheme.inkSoft)
                Spacer()
                Text("\(activeInCategory)/\(toggles.count) ACTIVOS")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(activeInCategory > 0 ? SITheme.accent : SITheme.inkFaint)
            }
            .padding(.horizontal, 4)

            if toggles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(SITheme.inkFaint)
                    Text("No hay parches disponibles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SITheme.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .siCard(radius: 14, tab: false)
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
        VStack(spacing: 8) {
            Rectangle()
                .fill(SITheme.edgeStroke)
                .frame(width: 70, height: 1)

            HStack(spacing: 6) {
                Text("\(SITheme.appName) v2.0")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SITheme.inkSoft)
                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(SITheme.inkFaint)
                Text("Hecho por didierxitx7")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SITheme.inkSoft)
            }
        }
        .padding(.top, 18)
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
        
        return SITheme.ok
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
                            color: SITheme.danger
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
                        color: SITheme.ok
                    )
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error: \(error.localizationKey)",
                        icon: "exclamationmark.triangle.fill",
                        color: SITheme.danger
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al activar el parche",
                        icon: "exclamationmark.triangle.fill",
                        color: SITheme.danger
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
                        color: SITheme.danger
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

    private var tileColors: [Color] {
        if toggle.isBlocked {
            return [SITheme.warning.opacity(0.28), SITheme.warning.opacity(0.10)]
        }
        if isOn {
            return [SITheme.accent.opacity(0.35), SITheme.accentDeep.opacity(0.18)]
        }
        return [Color.white.opacity(0.10), Color.white.opacity(0.04)]
    }

    private var rowStroke: AnyShapeStyle {
        if toggle.isBlocked {
            return AnyShapeStyle(SITheme.warning.opacity(0.5))
        }
        if isOn {
            return AnyShapeStyle(SITheme.accent.opacity(0.65))
        }
        return AnyShapeStyle(SITheme.edgeStroke)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: tileColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)

                if isProcessing {
                    ProgressView()
                        .tint(SITheme.accent)
                        .scaleEffect(0.75)
                } else if toggle.isBlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SITheme.warning)
                } else {
                    Image(systemName: toggle.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isOn ? SITheme.accent : SITheme.ink.opacity(0.75))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(toggle.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(toggle.isBlocked ? SITheme.inkFaint : SITheme.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(toggle.category.rawValue.uppercased())
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.8)
                        .foregroundColor(isOn ? SITheme.accent : SITheme.inkSoft)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.07))
                        )

                    if toggle.isBlocked {
                        Text("En mantenimiento")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(SITheme.warning)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .tint(SITheme.accent)
            .scaleEffect(0.9)
            .disabled(isProcessing || toggle.isBlocked)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .siCard(
            radius: 12,
            stroke: rowStroke,
            tint: isOn ? SITheme.accent.opacity(0.08) : Color.clear,
            tab: false
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
                .foregroundColor(message.color)
            Text(message.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(SITheme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(SITheme.card))
        .overlay(Capsule().strokeBorder(SITheme.edgeStroke, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.5), radius: 14, y: 6)
    }
}

// MARK: - ====== Tema New iOS x Señor iOS (compartido: lo usan Login, ModeSelection y Splash) ======

enum SITheme {
    /// Imagen roja "Señor iOS" (fondo, ya trae fondo negro)
    static let backgroundImageName = "SIBackground"
    /// Imagen verde (logo principal)
    static let logoImageName = "SILogo"

    static let appName = "NEW iOS x SEÑOR iOS"

    static let ink = Color.white
    static let inkSoft = Color.white.opacity(0.62)
    static let inkFaint = Color.white.opacity(0.38)

    /// Verde neón del logo
    static let accent = Color(red: 0.16, green: 0.94, blue: 0.30)
    static let accentDeep = Color(red: 0.04, green: 0.50, blue: 0.14)
    /// Rojo del fondo
    static let accentRed = Color(red: 0.90, green: 0.09, blue: 0.11)

    static let warning = Color(red: 1.00, green: 0.62, blue: 0.20)
    static let ok = Color(red: 0.30, green: 0.90, blue: 0.45)
    static let danger = Color(red: 1.00, green: 0.36, blue: 0.36)

    static let card = Color(red: 0.055, green: 0.060, blue: 0.060)

    /// Borde: verde -> casi transparente -> rojo
    static var edgeStroke: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.55), Color.white.opacity(0.06), accentRed.opacity(0.50)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Aro del logo: verde -> rojo
    static var ringStroke: LinearGradient {
        LinearGradient(
            colors: [accent, accentRed],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Fondo (imagen roja centrada sobre negro)

struct SIBackground: View {
    /// Distancia desde arriba de la pantalla hasta la imagen
    var imageTop: CGFloat = 96
    /// Ancho de la imagen respecto al ancho de la pantalla
    var imageWidthRatio: CGFloat = 0.80

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width * imageWidthRatio, 460)

            ZStack(alignment: .top) {
                Color.black

                if UIImage(named: SITheme.backgroundImageName) != nil {
                    Image(SITheme.backgroundImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: side, height: side)
                        .frame(maxWidth: .infinity)
                        .padding(.top, imageTop)
                }

                // Brillo verde suave abajo (une con el logo)
                RadialGradient(
                    colors: [SITheme.accent.opacity(0.10), Color.clear],
                    center: .bottom,
                    startRadius: 10,
                    endRadius: 420
                )

                // Velo para que el contenido siempre se lea
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.0), location: 0.0),
                        .init(color: Color.black.opacity(0.25), location: 0.55),
                        .init(color: Color.black.opacity(0.70), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Logo principal (imagen verde en círculo)

struct SILogo: View {
    var size: CGFloat = 56

    var body: some View {
        Group {
            if UIImage(named: SITheme.logoImageName) != nil {
                Image(SITheme.logoImageName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.black
                    Image(systemName: "bolt.fill")
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundColor(SITheme.accent)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Tarjeta (oscura, con pestaña verde arriba a la izquierda)

struct SICard: ViewModifier {
    var radius: CGFloat = 14
    var stroke: AnyShapeStyle = AnyShapeStyle(SITheme.edgeStroke)
    var tint: Color = Color.clear
    var tab: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(SITheme.card.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(tint)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if tab {
                    Capsule()
                        .fill(SITheme.accentGradient)
                        .frame(width: 34, height: 3)
                        .padding(.leading, 18)
                        .offset(y: -1)
                }
            }
    }
}

extension View {
    func siCard(radius: CGFloat = 14,
                stroke: AnyShapeStyle = AnyShapeStyle(SITheme.edgeStroke),
                tint: Color = Color.clear,
                tab: Bool = true) -> some View {
        modifier(SICard(radius: radius, stroke: stroke, tint: tint, tab: tab))
    }
}