import Foundation
import SwiftUI

// MARK: - In-page network monitor (every request the browser tab makes)

struct RequestEntry: Identifiable, Equatable {
    let id: UUID
    /// Absolute URL.
    var url: String
    /// "doc", "fetch", "xhr", "img", "script", "link", "css", …
    var kind: String
    /// HTTP status; 0 = unknown (subresources don't expose one).
    var status: Int
    /// Duration in ms.
    var ms: Double
    /// Transfer size in bytes; 0 = unknown (cross-origin without TAO).
    var bytes: Int
    var date: Date

    init(url: String, kind: String, status: Int, ms: Double, bytes: Int = 0, date: Date = Date()) {
        self.id = UUID()
        self.url = url
        self.kind = kind
        self.status = status
        self.ms = ms
        self.bytes = bytes
        self.date = date
    }
}

/// Aggregates requests posted by the injected JS bridge (fetch/XHR/resource
/// timing) plus main-frame navigation statuses. Main thread only.
final class RequestStore: ObservableObject {
    static let shared = RequestStore()

    @Published private(set) var entries: [RequestEntry] = []
    private var pending: [RequestEntry] = []
    private var flushScheduled = false

    private static let cap = 600

    /// Called by the web view coordinator for every JS message.
    func record(js body: [String: Any]) {
        guard let url = body["u"] as? String, !url.isEmpty else { return }
        let entry = RequestEntry(
            url: url,
            kind: (body["k"] as? String) ?? "res",
            status: (body["s"] as? Int) ?? 0,
            ms: (body["d"] as? Double) ?? 0,
            bytes: (body["b"] as? Int) ?? 0)
        // The JS bridge can post in bursts (resource timing poll); coalesce
        // them into one UI update per runloop turn.
        pending.append(entry)
        scheduleFlush()
    }

    /// Main-frame navigations (with real HTTP status) come from the delegate.
    func recordNavigation(url: String, status: Int, ms: Double = 0) {
        guard !url.isEmpty else { return }
        pending.insert(RequestEntry(url: url, kind: "doc", status: status, ms: ms), at: 0)
        scheduleFlush()
    }

    private func scheduleFlush() {
        guard !flushScheduled else { return }
        flushScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.flushScheduled = false
            guard !self.pending.isEmpty else { return }
            let batch = self.pending
            self.pending.removeAll()
            self.entries = Array((batch + self.entries).prefix(RequestStore.cap))
        }
    }

    func clear() {
        pending.removeAll()
        entries = []
    }
}

// MARK: - Injected JS bridge (fetch / XHR / resource timing → Swift)

enum NetworkJS {
    static let source = """
    (function () {
      if (window.__lbNetInstalled) { return; }
      window.__lbNetInstalled = true;
      var post = function (o) {
        try { window.webkit.messageHandlers.lbNet.postMessage(o); } catch (e) {}
      };
      var abs = function (u) {
        try { return new URL(u, location.href).href; } catch (e) { return String(u); }
      };
      // fetch()
      if (window.fetch) {
        var origFetch = window.fetch;
        window.fetch = function () {
          var arg = arguments[0];
          var t0 = performance.now();
          var p = origFetch.apply(this, arguments);
          p.then(function (resp) {
            post({ u: abs(typeof arg === "string" ? arg : (arg && arg.url) || location.href),
                   k: "fetch", s: resp.status, d: Math.round(performance.now() - t0) });
          }, function () {
            post({ u: abs(typeof arg === "string" ? arg : String(arg)),
                   k: "fetch", s: 0, d: Math.round(performance.now() - t0) });
          });
          return p;
        };
      }
      // XMLHttpRequest
      var origOpen = XMLHttpRequest.prototype.open;
      var origSend = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.open = function (m, u) {
        this.__lbU = u; this.__lbM = m;
        return origOpen.apply(this, arguments);
      };
      XMLHttpRequest.prototype.send = function () {
        var self = this, t0 = performance.now();
        self.addEventListener("loadend", function () {
          post({ u: abs(self.__lbU || ""), k: "xhr",
                 s: self.status || 0, d: Math.round(performance.now() - t0) });
        });
        return origSend.apply(self, arguments);
      };
      // Everything else: images, scripts, styles, fonts, fetches already done.
      var seen = 0;
      setInterval(function () {
        try {
          var ents = performance.getEntriesByType("resource");
          for (var i = seen; i < ents.length; i++) {
            var e = ents[i];
            post({ u: e.name, k: e.initiatorType || "res",
                   s: 0, d: Math.round(e.duration),
                   b: e.transferSize || 0, t: Math.round(e.startTime) });
          }
          seen = ents.length;
          if (seen > 4000) { performance.clearResourceTimings(); seen = 0; }
        } catch (err) {}
      }, 1200);
    })();
    """
}
