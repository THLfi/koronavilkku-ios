import Foundation
import os.log

struct Log {
    
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let application = OSLog(subsystem: subsystem, category: "application")
    
    static func e(_ message: Any) {
        Log.message(String(describing: message), type: .error)
    }
    
    static func i(_ message: Any) {
        Log.message(String(describing: message), type: .info)
    }
    
    static func d(_ message: Any) {
        Log.message(String(describing: message), type: .debug)
    }
    
    static func message(_ message: String, type: OSLogType) {
        #if DEBUG
        os_log("%@", log: application, type: type, message)
        #endif
    }
}
