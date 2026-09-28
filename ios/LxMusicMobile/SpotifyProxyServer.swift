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

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global())
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, err in
            guard let self = self, let data = data, !data.isEmpty, err == nil else {
                conn.cancel(); return
            }
            let req = String(data: data, encoding: .utf8) ?? ""
            let body = self.makeBody(req)
            let resp = self.makeResponse(body)
            conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
        }
    }

    private func makeBody(_ request: String) -> Data {
        // 解析 HTTP 第一行: GET /v1/me/player/currently-playing HTTP/1.1
        let line = request.components(separatedBy: "\r\n").first ?? ""
        let path = line.components(separatedBy: " ").count > 1
            ? line.components(separatedBy: " ")[1] : ""

        if path.contains("/v1/me/player/currently-playing") {
            let json: [String: Any] = [
                "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                "progress_ms": progressMs,
                "is_playing": isPlaying,
                "item": [
                    "id": "lx_track",
                    "uri": "spotify:track:lx_track",
                    "name": songName,
                    "duration_ms": durationMs,
                    "artists": [["id": "lx_artist", "name": artist, "type": "artist", "uri": "spotify:artist:lx_artist"]],
                    "album": ["id": "lx_album", "name": songName, "album_type": "album", "images": []]
                ]
            ]
            return try? JSONSerialization.data(withJSONObject: json) ?? Data()
        } else if path.contains("/v1/me") {
            let json: [String: Any] = ["id": "lx_user", "display_name": "LX User", "type": "user", "uri": "spotify:user:lx_user", "product": "premium"]
            return try? JSONSerialization.data(withJSONObject: json) ?? Data()
        }
        return Data()
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
