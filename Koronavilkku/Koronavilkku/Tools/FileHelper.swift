import Foundation
import ZIPFoundation

struct FileHelper {
    @discardableResult
    func createFile(name: String, extension ext: String, data: Data, relativeTo: URL) -> URL? {
        let fileURL = URL(fileURLWithPath: name, relativeTo: relativeTo).appendingPathExtension(ext)
        do {
            try data.write(to: fileURL)
            Log.d("File saved: \(fileURL.absoluteURL)")
            return fileURL
        } catch {
            Log.e("Got error while creating file: \(error.localizedDescription)")
            return nil
        }
    }
    
    func readFile(name: String, extension ext: String, relativeTo: URL) -> Data? {
        let fileURL = URL(fileURLWithPath: name, relativeTo: relativeTo).appendingPathExtension(ext)
        return try? Data(contentsOf: fileURL)
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
    
    func getListOfFileBatchUrls(in directory: URL) -> [URL]? {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            Log.e("Error while enumerating files \(directory.path): \(error.localizedDescription)")
            return nil
        }
    }
}
