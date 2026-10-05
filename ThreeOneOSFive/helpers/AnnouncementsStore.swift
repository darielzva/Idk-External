import Foundation
import Combine

// MARK: - Modelo

struct RemoteAnnouncement: Codable, Identifiable {
    let id: String
    let message: String
    let type: String                  // "info" | "success" | "warning" | "danger"
    let isActive: Bool
    let expiresAt: String?
    let createdAt: String
    
    // 🆕 Campos nuevos
    let displayStyle: String          // "banner" | "popup"
    let canDismiss: Bool
    let forceRestart: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case type
        case isActive = "is_active"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case displayStyle = "display_style"
        case canDismiss = "can_dismiss"
        case forceRestart = "force_restart"
    }
    
    var isExpired: Bool {
        guard let expiresAt,
              let date = parseSupabaseDate(expiresAt) else {
            return false
        }
        return date <= Date()
    }
    
    var isVisible: Bool {
        return isActive && !isExpired
    }
    
    var isPopup: Bool {
        return displayStyle == "popup"
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
        
        return nil
    }
}

// MARK: - Store

@MainActor
final class AnnouncementsStore: ObservableObject {
    
    // MARK: - Publicados
    
    @Published var announcements: [RemoteAnnouncement] = []
    @Published var dismissedIDs: Set<String> = []
    
    // MARK: - Configuración
    
    private let supabaseURL = SupabaseService.supabaseURL
    private let supabaseAnonKey = SupabaseService.supabaseAnonKey
    
    nonisolated(unsafe) private var webSocketTask: URLSessionWebSocketTask?
    nonisolated(unsafe) private var heartbeatTimer: Timer?
    
    private let dismissedKey = "dismissed_announcements"
    
    init() {
        loadDismissed()
    }
    
    // MARK: - Anuncios visibles (todos)
    
    var visibleAnnouncements: [RemoteAnnouncement] {
        return announcements.filter { ann in
            ann.isVisible && !dismissedIDs.contains(ann.id)
        }
    }
    
    // 🆕 Solo banners (pequeños, arriba del panel)
    var visibleBanners: [RemoteAnnouncement] {
        return visibleAnnouncements.filter { !$0.isPopup }
    }
    
    // 🆕 Solo popups (grandes, modal centrado)
    var visiblePopups: [RemoteAnnouncement] {
        return visibleAnnouncements.filter { $0.isPopup }
    }
    
    // MARK: - Descargar anuncios (REST inicial)
    
    func fetchAnnouncements() async throws -> [RemoteAnnouncement] {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/announcements?is_active=eq.true&order=created_at.desc") else {
            throw NSError(domain: "AnnouncementsStore", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "AnnouncementsStore", code: -2)
        }
        
        let list = try JSONDecoder().decode([RemoteAnnouncement].self, from: data)
        self.announcements = list
        log("announcements: \(list.count) descargados (\(visibleAnnouncements.count) visibles, \(visibleBanners.count) banners, \(visiblePopups.count) popups)")
        return list
    }
    
    // MARK: - Realtime: Suscribirse a cambios
    
    func subscribeToAnnouncements() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        heartbeatTimer?.invalidate()
        
        let wsURLString = supabaseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        guard let url = URL(string: "\(wsURLString)/realtime/v1/websocket?apikey=\(supabaseAnonKey)&vsn=1.0.0") else {
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()
        
        log("announcements: realtime connected")
        
        // Heartbeat cada 25 segundos
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.sendHeartbeat()
        }
        
        // Suscribirse al canal de announcements
        let topic = "realtime:public:announcements"
        let joinPayload: [String: Any] = [
            "topic": topic,
            "event": "phx_join",
            "payload": [
                "config": [
                    "broadcast": ["self": false],
                    "presence": ["key": ""],
                    "postgres_changes": [
                        [
                            "event": "*",
                            "schema": "public",
                            "table": "announcements"
                        ]
                    ]
                ]
            ],
            "ref": "announcements"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: joinPayload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            task.send(.string(jsonString)) { error in
                if let error {
                    log("announcements: join error \(error)")
                }
            }
        }
        
        // Escuchar mensajes
        Task { [weak self] in
            await self?.listenForMessages()
        }
    }
    
    private func listenForMessages() async {
        guard let task = webSocketTask else { return }
        
        while true {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                log("announcements: ws error \(error)")
                
                // Reconectar después de 5 segundos
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                subscribeToAnnouncements()
                return
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let event = json["event"] as? String,
           event == "postgres_changes",
           let payload = json["payload"] as? [String: Any],
           let dataObj = payload["data"] as? [String: Any],
           let type = dataObj["type"] as? String {
            
            switch type {
            case "INSERT":
                // 🆕 Nuevo anuncio
                if let record = dataObj["record"] as? [String: Any],
                   let newAnn = decodeAnnouncement(from: record) {
                    log("announcements: nuevo anuncio recibido (\(newAnn.displayStyle))")
                    self.announcements.insert(newAnn, at: 0)
                }
                
            case "UPDATE":
                // 🔄 Anuncio actualizado (activado/desactivado)
                if let record = dataObj["record"] as? [String: Any],
                   let updatedAnn = decodeAnnouncement(from: record) {
                    log("announcements: anuncio actualizado")
                    if let index = self.announcements.firstIndex(where: { $0.id == updatedAnn.id }) {
                        self.announcements[index] = updatedAnn
                    } else {
                        self.announcements.insert(updatedAnn, at: 0)
                    }
                }
                
            case "DELETE":
                // 🗑️ Anuncio eliminado
                if let oldRecord = dataObj["old_record"] as? [String: Any],
                   let id = oldRecord["id"] as? String {
                    log("announcements: anuncio eliminado")
                    self.announcements.removeAll { $0.id == id }
                }
                
            default:
                break
            }
        }
    }
    
    private func decodeAnnouncement(from record: [String: Any]) -> RemoteAnnouncement? {
        guard let id = record["id"] as? String,
              let message = record["message"] as? String,
              let type = record["type"] as? String,
              let isActive = record["is_active"] as? Bool,
              let createdAt = record["created_at"] as? String else {
            return nil
        }
        
        let expiresAt = record["expires_at"] as? String
        
        // 🆕 Campos nuevos (con defaults por si no existen)
        let displayStyle = record["display_style"] as? String ?? "banner"
        let canDismiss = record["can_dismiss"] as? Bool ?? true
        let forceRestart = record["force_restart"] as? Bool ?? false
        
        return RemoteAnnouncement(
            id: id,
            message: message,
            type: type,
            isActive: isActive,
            expiresAt: expiresAt,
            createdAt: createdAt,
            displayStyle: displayStyle,
            canDismiss: canDismiss,
            forceRestart: forceRestart
        )
    }
    
    private func sendHeartbeat() {
        guard let task = webSocketTask else { return }
        
        let heartbeat: [String: Any] = [
            "topic": "phoenix",
            "event": "heartbeat",
            "payload": [:],
            "ref": UUID().uuidString
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: heartbeat),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            task.send(.string(jsonString)) { _ in }
        }
    }
    
    // MARK: - Cerrar un anuncio
    
    func dismiss(_ id: String) {
        dismissedIDs.insert(id)
        saveDismissed()
    }
    
    private func saveDismissed() {
        let array = Array(dismissedIDs)
        UserDefaults.standard.set(array, forKey: dismissedKey)
    }
    
    private func loadDismissed() {
        if let array = UserDefaults.standard.array(forKey: dismissedKey) as? [String] {
            dismissedIDs = Set(array)
        }
    }
    
    // MARK: - Desconectar
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
}
