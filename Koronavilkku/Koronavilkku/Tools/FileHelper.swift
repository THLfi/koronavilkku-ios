import Foundation
import ZIPFoundation

class FileHelper {
    
    enum Directories {
        case batches
        case municipalities
        
        var url: URL {
            switch self {
            case .batches:
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("batches", isDirectory: true)
            case .municipalities:
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("municipalities", isDirectory: true)
            }
        }
    }
    
    init() {
        try? FileManager.default.createDirectory(atPath: Directories.batches.url.path,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        try? FileManager.default.createDirectory(atPath: Directories.municipalities.url.path,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
    
    @discardableResult
    func createFile(name: String, extension ext: String, data: Data, relativeTo: Directories = .batches) -> URL? {
        let fileURL = URL(fileURLWithPath: name, relativeTo: relativeTo.url).appendingPathExtension(ext)
        do {
            try data.write(to: fileURL)
            Log.d("File saved: \(fileURL.absoluteURL)")
            return fileURL
        } catch {
            Log.e("Got error while creating file: \(error.localizedDescription)")
            return nil
        }
    }
    
    func readFile(name: String, extension ext: String, relativeTo: Directories = .batches) -> Data? {
        let fileURL = URL(fileURLWithPath: name, relativeTo: relativeTo.url).appendingPathExtension(ext)
        return try? Data(contentsOf: fileURL)
    }
    
    func getUrlsFor(batchId: String) -> [URL] {
        return [
            URL(fileURLWithPath: batchId, relativeTo: Directories.batches.url),
            URL(fileURLWithPath: batchId, relativeTo: Directories.batches.url).appendingPathExtension("zip")
        ]
    }
    
    func deleteFiles(urls: [URL]) {
        urls.forEach { url in
            deleteFile(url: url)
        }
    }
    
    func deleteFile(url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                Log.e("Deleting contents of path: \(url.path)")
                try fileManager.removeItem(at: url)
            } catch {
                Log.e("Deleting contents failed: \(error.localizedDescription)")
            }
        } else {
            Log.e("File not found at \(url.absoluteString)")
        }
    }
    
    func decompressZip(fileUrl: URL) -> URL? {
        do {
            let unzippedUrl = fileUrl.deletingPathExtension()
            try FileManager.default.unzipItem(at: fileUrl, to: unzippedUrl)
            return unzippedUrl
        } catch  {
            Log.e("Error while unzipping: \(error.localizedDescription)")
            return nil
        }
    }
    
    @discardableResult
    func renameFile(newName: String, fileUrl: URL) -> URL? {
        do {
            let fileExtension = fileUrl.pathExtension
            let newFileUrl = fileUrl
                .deletingLastPathComponent()
                .appendingPathComponent(newName)
                .appendingPathExtension(fileExtension)
            try FileManager.default.moveItem(
                at: fileUrl,
                to: newFileUrl
            )
            return newFileUrl
        } catch {
            Log.e("Renaming file failed: \(error)")
            return nil
        }
    }
    
    func getFileUrls(forBatchId id: String) -> [URL] {
        if let urls = getListOfFileUrlsInDirectory(directoryUrl: Directories.batches.url.appendingPathComponent(id)) {
            return urls
        }
        return []
    }
    
    func getListOfFileUrlsInDirectory(directoryUrl: URL) -> [URL]? {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            Log.e("Error while enumerating files \(directoryUrl.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    func getListOfFileBatchUrls() -> [URL]? {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: Directories.batches.url, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            Log.e("Error while enumerating files \(Directories.batches.url.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteAllBatches() {
        if let files = getListOfFileBatchUrls() {
            Log.d("Delete all batch files")
            deleteFiles(urls: files)
        } else {
            Log.d("Nothing to delete")
        }
    }
}
