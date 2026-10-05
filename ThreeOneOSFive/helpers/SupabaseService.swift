import Foundation
import Combine

// MARK: - Modelos

struct SupabaseKey: Codable, Identifiable {
    let id: String
    let keyValue: String
    let isActive: Bool
    let isBanned: Bool
    let label: String?
    let expiresAt: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case keyValue = "key_value"
        case isActive = "is_active"
        case isBanned = "is_banned"
        case label
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
    
    var isValid: Bool {
        guard isActive && !isBanned else { return false }
        if let expiresAt, let date = ISO8601DateFormatter().date(from: expiresAt) {
            return date > Date()
        }
        return true
    }
}

enum SupabaseError: Error {
    case invalidURL
    case noData
    case decodingFailed
    case keyNotFound
    case keyBanned
    case keyExpired
    case keyInactive
    case deviceLimitReached
    case deviceBanned
    case networkError(Error)
}

// MARK: - Servicio

@MainActor
final class SupabaseService: ObservableObject {
    
    // ⚠️ CONFIGURACIÓN
    static let supabaseURL = "https://abjckyamghjwdltnhinw.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiamNreWFtZ2hqd2RsdG5oaW53Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5ODQ5ODEsImV4cCI6MjEwNjU2MDk4MX0.XKhp8PhX1H-VWX8NEriZOV8v4vR6i8d0ILD7HntAbvI"
    
    // MARK: - Publicados
    
    @Published var currentKey: SupabaseKey?
    @Published var isKeyRevoked: Bool = false
    @Published var isKeyFrozen: Bool = false       // ← 🆕 NUEVO
    @Published var isConnected: Bool = false
    @Published var isMaintenanceMode: Bool = false
    @Published var maintenanceMessage: String = "El servicio está en mantenimiento. Vuelve pronto."
    
    // MARK: - Internos (nonisolated para evitar warnings de concurrencia)
    
    nonisolated(unsafe) private var keyWebSocketTask: URLSessionWebSocketTask?
    nonisolated(unsafe) private var maintenanceWebSocketTask: URLSessionWebSocketTask?
    nonisolated(unsafe) private var heartbeatTimer: Timer?
    nonisolated(unsafe) private var maintenanceHeartbeatTimer: Timer?
    
    // MARK: - Device ID persistente
    
    private var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: "device_id") {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "device_id")
        return new
    }
    
    // MARK: - Verificar Key
    
    func verifyKey(_ keyValue: String) async throws -> SupabaseKey {
        guard let encodedKey = keyValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Self.supabaseURL)/rest/v1/keys?key_value=eq.\(encodedKey)&select=*") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Self.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw SupabaseError.networkError(
                    NSError(domain: "Supabase", code: 0)
                )
            }
            
            let keys = try JSONDecoder().decode([SupabaseKey].self, from: data)
            
            guard let key = keys.first else {
                throw SupabaseError.keyNotFound
            }
            
            // Validaciones básicas
            if !key.isActive {
                throw SupabaseError.keyInactive
            }
            if key.isBanned {
                throw SupabaseError.keyBanned
            }
            if let expiresAt = key.expiresAt,
               let date = ISO8601DateFormatter().date(from: expiresAt),
               date <= Date() {
                throw SupabaseError.keyExpired
            }
            
            // Verificar límite de dispositivos
            try await checkDeviceLimit(keyID: key.id)
            
            // Registrar dispositivo
            await registerDevice(keyID: key.id)
            
            // Guardar key actual
            self.currentKey = key
            
            // Resetear estados al verificar exitosamente
            self.isKeyRevoked = false
            self.isKeyFrozen = false
            
            // Log de acceso
            Task {
                await logAccess(keyValue: keyValue, action: "login")
            }
            
            // Suscribirse a cambios en tiempo real
            subscribeToKeyChanges(keyID: key.id)
            
            return key
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Verificar límite de dispositivos
    
    private func checkDeviceLimit(keyID: String) async throws {
        guard let keyURL = URL(string: "\(Self.supabaseURL)/rest/v1/keys?id=eq.\(keyID)&select=max_devices"),
              let keyData = try? await fetchData(url: keyURL),
              let keyArray = try? JSONSerialization.jsonObject(with: keyData) as? [[String: Any]],
              let maxDevices = keyArray.first?["max_devices"] as? Int,
              maxDevices > 0 else {
            return
        }
        
        guard let devicesURL = URL(string: "\(Self.supabaseURL)/rest/v1/key_devices?key_id=eq.\(keyID)&select=device_id"),
              let devicesData = try? await fetchData(url: devicesURL),
              let devicesArray = try? JSONSerialization.jsonObject(with: devicesData) as? [[String: Any]] else {
            return
        }
        
        let currentCount = devicesArray.count
        let thisDeviceID = deviceID
        
        let isThisDeviceRegistered = devicesArray.contains { device in
            (device["device_id"] as? String) == thisDeviceID
        }
        
        if currentCount >= maxDevices && !isThisDeviceRegistered {
            throw SupabaseError.deviceLimitReached
        }
    }
    
    // MARK: - Registrar dispositivo
    
    private func registerDevice(keyID: String) async {
        guard let url = URL(string: "\(Self.supabaseURL)/rest/v1/key_devices") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Self.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
            "key_id": keyID,
            "device_id": deviceID,
            "last_seen": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
    
    // MARK: - Log de acceso
    
    private func logAccess(keyValue: String, action: String) async {
        guard let url = URL(string: "\(Self.supabaseURL)/rest/v1/access_logs") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Self.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
            "key_value": keyValue,
            "device_id": deviceID,
            "action": action
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
    
    // MARK: - Realtime: Escuchar cambios en la key
    
    private func subscribeToKeyChanges(keyID: String) {
        keyWebSocketTask?.cancel(with: .goingAway, reason: nil)
        heartbeatTimer?.invalidate()
        
        let wsURLString = Self.supabaseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        guard let url = URL(string: "\(wsURLString)/realtime/v1/websocket?apikey=\(Self.supabaseAnonKey)&vsn=1.0.0") else {
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.keyWebSocketTask = task
        task.resume()
        
        isConnected = true
        log("supabase: realtime connected for key \(keyID)")
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.sendKeyHeartbeat()
        }
        
        let topic = "realtime:public:keys:id=eq.\(keyID)"
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
                            "table": "keys",
                            "filter": "id=eq.\(keyID)"
                        ]
                    ]
                ]
            ],
            "ref": "key_\(keyID)"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: joinPayload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            task.send(.string(jsonString)) { error in
                if let error {
                    log("supabase: key join error \(error)")
                }
            }
        }
        
        Task { [weak self] in
            await self?.listenForKeyMessages(keyID: keyID)
        }
    }
    
    private func listenForKeyMessages(keyID: String) async {
        guard let task = keyWebSocketTask else { return }
        
        while isConnected {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    handleKeyMessage(text, keyID: keyID)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleKeyMessage(text, keyID: keyID)
                    }
                @unknown default:
                    break
                }
            } catch {
                log("supabase: key ws error \(error)")
                isConnected = false
                
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if !isConnected {
                    subscribeToKeyChanges(keyID: keyID)
                }
                return
            }
        }
    }
    
    // ⚡ handleKeyMessage MODIFICADO
    private func handleKeyMessage(_ text: String, keyID: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let event = json["event"] as? String,
           event == "postgres_changes",
           let payload = json["payload"] as? [String: Any],
           let dataObj = payload["data"] as? [String: Any] {
            
            if let eventType = dataObj["type"] as? String {
                switch eventType {
                case "DELETE":
                    log("supabase: KEY DELETED — kicking user")
                    self.isKeyRevoked = true
                    self.isKeyFrozen = false
                    return
                    
                case "UPDATE", "INSERT":
                    if let record = dataObj["record"] as? [String: Any] {
                        let isBanned = record["is_banned"] as? Bool ?? false
                        let isActive = record["is_active"] as? Bool ?? true
                        let expiresAt = record["expires_at"] as? String
                        
                        // 🚫 BANEADA → revocada
                        if isBanned {
                            log("supabase: KEY BANNED — kicking user")
                            self.isKeyRevoked = true
                            self.isKeyFrozen = false
                            return
                        }
                        
                        // ⏰ EXPIRADA → revocada
                        if let expiresAt,
                           let date = ISO8601DateFormatter().date(from: expiresAt),
                           date <= Date() {
                            log("supabase: KEY EXPIRED — kicking user")
                            self.isKeyRevoked = true
                            self.isKeyFrozen = false
                            return
                        }
                        
                        // ❄️ CONGELADA → pantalla de congelada (NO revocada)
                        if !isActive {
                            log("supabase: KEY FROZEN — showing frozen screen")
                            self.isKeyFrozen = true
                            self.isKeyRevoked = false
                            return
                        }
                        
                        // ✅ Activa → resetear ambos
                        self.isKeyFrozen = false
                        self.isKeyRevoked = false
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    private func sendKeyHeartbeat() {
        guard let task = keyWebSocketTask else { return }
        
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
    
    // MARK: - Realtime: Escuchar cambios de mantenimiento
    
    func subscribeToMaintenance() {
        maintenanceWebSocketTask?.cancel(with: .goingAway, reason: nil)
        maintenanceHeartbeatTimer?.invalidate()
        
        let wsURLString = Self.supabaseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        guard let url = URL(string: "\(wsURLString)/realtime/v1/websocket?apikey=\(Self.supabaseAnonKey)&vsn=1.0.0") else {
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.maintenanceWebSocketTask = task
        task.resume()
        
        log("supabase: maintenance realtime connected")
        
        maintenanceHeartbeatTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.sendMaintenanceHeartbeat()
        }
        
        let topic = "realtime:public:app_config:id=eq.1"
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
                            "table": "app_config",
                            "filter": "id=eq.1"
                        ]
                    ]
                ]
            ],
            "ref": "maintenance"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: joinPayload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            task.send(.string(jsonString)) { error in
                if let error {
                    log("supabase: maintenance join error \(error)")
                }
            }
        }
        
        Task { [weak self] in
            await self?.listenForMaintenanceMessages()
        }
    }
    
    private func listenForMaintenanceMessages() async {
        guard let task = maintenanceWebSocketTask else { return }
        
        while true {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    handleMaintenanceMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMaintenanceMessage(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                log("supabase: maintenance ws error \(error)")
                
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                subscribeToMaintenance()
                return
            }
        }
    }
    
    private func handleMaintenanceMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let event = json["event"] as? String,
           event == "postgres_changes",
           let payload = json["payload"] as? [String: Any],
           let dataObj = payload["data"] as? [String: Any],
           let record = dataObj["record"] as? [String: Any] {
            
            let isMaintenance = record["maintenance_mode"] as? Bool ?? false
            let message = record["maintenance_message"] as? String ?? ""
            
            self.isMaintenanceMode = isMaintenance
            self.maintenanceMessage = message.isEmpty
                ? "El servicio está en mantenimiento. Vuelve pronto."
                : message
            
            log("supabase: maintenance mode = \(isMaintenance)")
        }
    }
    
    private func sendMaintenanceHeartbeat() {
        guard let task = maintenanceWebSocketTask else { return }
        
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
    
    // MARK: - Check inicial de mantenimiento
    
    func checkMaintenanceStatus() async {
        guard let url = URL(string: "\(Self.supabaseURL)/rest/v1/app_config?id=eq.1&select=*") else { return }
        
        do {
            let data = try await fetchData(url: url)
            if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let config = array.first {
                let isMaintenance = config["maintenance_mode"] as? Bool ?? false
                let message = config["maintenance_message"] as? String ?? ""
                
                self.isMaintenanceMode = isMaintenance
                self.maintenanceMessage = message.isEmpty
                    ? "El servicio está en mantenimiento. Vuelve pronto."
                    : message
                
                log("supabase: initial maintenance mode = \(isMaintenance)")
            }
        } catch {
            log("supabase: maintenance check failed — \(error)")
        }
    }
    
    // MARK: - Fetch helper
    
    private func fetchData(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Self.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseError.networkError(
                NSError(domain: "Supabase", code: 0)
            )
        }
        
        return data
    }
    
    // MARK: - Desconectar
    
    func disconnect() {
        keyWebSocketTask?.cancel(with: .goingAway, reason: nil)
        maintenanceWebSocketTask?.cancel(with: .goingAway, reason: nil)
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        maintenanceHeartbeatTimer?.invalidate()
        maintenanceHeartbeatTimer = nil
        isConnected = false
        currentKey = nil
        isKeyFrozen = false       // ← 🆕 AÑADIR
        isKeyRevoked = false      // ← 🆕 AÑADIR
    }
}
