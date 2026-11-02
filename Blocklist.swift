import Foundation

// MARK: - Ad / tracker domains used by the in-page content blocker.
//
// Compiled into a WKContentRuleList by `ContentBlocker` (ContentView.swift),
// so requests to these hosts are refused before they leave the page.

enum SharedBlocklist {
    static let domains: [String] = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "googletagmanager.com", "google-analytics.com", "googletagservices.com",
        "facebook.com", "connect.facebook.net", "fbcdn.net",
        "ads.tiktok.com", "adnxs.com", "criteo.com", "criteo.net",
        "taboola.com", "outbrain.com", "scorecardresearch.com", "comscore.com",
        "hotjar.com", "mixpanel.com", "segment.io", "segment.com",
        "amplitude.com", "branch.io", "appsflyer.com", "adjust.com",
        "matomo.org", "openx.net", "rubiconproject.com", "pubmatic.com",
        "smartadserver.com", "zedo.com", "moatads.com", "adform.net",
        "adcolony.com", "applovin.com", "inmobi.com", "mopub.com",
        "fullstory.com", "clarity.ms", "crazyegg.com", "optimizely.com",
        "newrelic.com", "nr-data.net", "doubleverify.com", "adtrafficquality.google",
        // Tracking pixels and telemetry endpoints caught by the URL rules.
        "ads.yahoo.com", "advertising.com", "serving-sys.com",
        "cassavaengine.com", "zerostats.com", "appsdt.com",
        "engine.adcontextpartners.com", "onetag-sys.com", "permutive.com",
        "bat.bing.com", "clarity-prod.westus.cloudapp.azure.com",
    ]

    /// Exact-or-suffix match: a host is blocked only if it or a parent domain
    /// is on the list ("ads.example.com" does not match "doubleclick.net").
    static func isBlocked(_ host: String) -> Bool {
        let h = host.lowercased()
        guard !h.isEmpty else { return false }
        return domains.contains { h == $0 || h.hasSuffix("." + $0) }
    }
}
