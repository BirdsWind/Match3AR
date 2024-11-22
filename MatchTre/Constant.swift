import SwiftUI

struct Constants {
    static let rows = 6
    static let columns = 8
    static let tileTypes = 3
    static let tileSize: Float = 0.1
    static let cameraPosition: Float = {
#if os(xrOS)
        return -2.0
#elseif os(iOS)
        return -3.5
#else
        // Default value for other platforms (e.g., macOS, tvOS)
        return -3.0
#endif
    }()
}
