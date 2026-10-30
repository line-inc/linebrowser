import Foundation
import Combine

class BrowserModel: ObservableObject {
    @Published var currentUrl: String = "https://lineinc.ro"
    @Published var inputUrl: String = "https://lineinc.ro"
    @Published var isLoading: Bool = false
    @Published var title: String = "Line Inc."
    @Published var bookmarks: [String] = ["https://lineinc.ro"]
    @Published var history: [String] = []
    @Published var showSettings: Bool = false
}
