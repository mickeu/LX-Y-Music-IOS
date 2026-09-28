import Foundation
import Network

/// Spotify API 代理服务器：监听 localhost:36123，返回洛雪播放器的播放信息，伪装成 Spotify API。
/// 配合 Surge URL Rewrite 把 api.spotify.com 重定向到 localhost:36123。
class SpotifyProxyServer {
    static let shared = SpotifyProxyServer()
    private var listener: NWListener?
    private let port: UInt16 = 36123

    var songName = ""
    var artist = ""
    var progressMs: Int = 0
    var durationMs: Int = 0
    var isPlaying = false

    func start() {
        guard listener == nil else { return }
        do {
            let p = NWEndpoint.Port(rawValue: port)!
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: p)
            listener?.newConnectionHandler = { [weak self] conn in
                self?.handle(conn)
            }
            listener?.start(queue: .global())
            NSLog("[SpotifyProxy] Listening on :\(port)")
        } catch {
            NSLog("[SpotifyProxy] Start failed: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private var storedRedirectUri = "dynamic-lyrics://spotify-callback"

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global())
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, err in
            guard let self = self, let data = data, !data.isEmpty, err == nil else {
                conn.cancel(); return
            }
            let req = String(data: data, encoding: .utf8) ?? ""
            var isRedirect = false
            let body = self.makeBody(req, isRedirect: &isRedirect)

            if isRedirect {
                let loc = String(data: body, encoding: .utf8) ?? ""
                let h = "HTTP/1.1 302 Found\r\nLocation: \(loc)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                conn.send(content: h.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
            } else {
                conn.send(content: self.makeResponse(body), completion: .contentProcessed { _ in conn.cancel() })
            }
        }
    }

    private func makeBody(_ request: String, isRedirect: inout Bool) -> Data {
        let line = request.components(separatedBy: "\r\n").first ?? ""
        let path = line.components(separatedBy: " ").count > 1
            ? line.components(separatedBy: " ")[1] : ""

        // 1. OAuth /authorize — 跳过登录，直接 302 到 redirect_uri 带 fake code
        if path.contains("/authorize") {
            if let uri = extractParam("redirect_uri", from: path) {
                storedRedirectUri = uri
            }
            let fakeCode = "fake_code_\(Int(Date().timeIntervalSince1970 * 1000))"
            let redirect = "\(storedRedirectUri)?code=\(fakeCode)"
            isRedirect = true
            return redirect.data(using: .utf8) ?? Data()
        }

        // 2. OAuth /api/token — 返回假 access_token + refresh_token
        if path.contains("/api/token") || path.contains("/token") {
            let json: [String: Any] = [
                "access_token": "fake_access_token_abc123",
                "refresh_token": "fake_refresh_token_xyz",
                "token_type": "Bearer",
                "expires_in": 3600,
                "scope": "user-read-playback-state user-read-currently-playing playlist-read-private"
            ]
            return try? JSONSerialization.data(withJSONObject: json) ?? Data()
        }

        // 3. GET /v1/me/player/currently-playing — 当前播放（必须在 /v1/me/player 之前）
        if path.contains("/currently-playing") || path.contains("/player/currently-playing") {
            let json: [String: Any] = [
                "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                "progress_ms": progressMs,
                "is_playing": isPlaying,
                "item": [
                    "id": "lx_track", "uri": "spotify:track:lx_track",
                    "name": songName, "duration_ms": durationMs,
                    "artists": [["id": "lx_artist", "name": artist, "type": "artist", "uri": "spotify:artist:lx_artist"]],
                    "album": ["id": "lx_album", "name": songName, "album_type": "album", "images": []]
                ]
            ]
            return try? JSONSerialization.data(withJSONObject: json) ?? Data()
        }

        // 4. GET /v1/me/player — 播放器状态
        if path.contains("/v1/me/player") {
            let json: [String: Any] = ["device_id": "lx_device", "is_active": true, "is_private_session": false, "shuffle": false, "repeat_mode": "off"]
            return try? JSONSerialization.data(withJSONObject: json) ?? Data()
        }

        // 5. GET /v1/me — 用户信息
        if path.contains("/v1/me") {
            let json: [String: Any] = ["id": "lx_user", "display_name": "LX User", "type": "user", "uri": "spotify:user:lx_user", "product": "premium"]
            return try? JSONSerialization.data(withJSONObject: json) ?? Data()
        }

        // 6. 其他端点
        let empty: [String: Any] = ["count": 0, "items": [], "href": ""]
        return try? JSONSerialization.data(withJSONObject: empty) ?? Data()
    }

    private func extractParam(_ key: String, from path: String) -> String? {
        guard let qIdx = path.firstIndex(of: "?") else { return nil }
        let query = String(path[qIdx...]).dropFirst()
        for pair in query.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            if parts.count >= 2, parts[0] == key {
                return parts[1]
            }
        }
        return nil
    }

    private func makeResponse(_ body: Data) -> Data {
        var s = "HTTP/1.1 200 OK\r\n"
        s += "Content-Type: application/json; charset=utf-8\r\n"
        s += "Content-Length: \(body.count)\r\n"
        s += "Access-Control-Allow-Origin: *\r\n"
        s += "Cache-Control: no-store\r\n\r\n"
        var d = s.data(using: .utf8) ?? Data()
        d.append(body)
        return d
    }
}
