//
//  ViewController.swift
//  UploadDownload
//
//  Created by Volochaeva Tatiana on 17.03.2024.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var getRequestButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var textView: UITextView!
    
    // Observing for uploading or downloading
    var observer: NSKeyValueObservation?
    let session = URLSession.shared
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        uploadButton.isEnabled = false
        uploadButton.alpha = 0.5
        progressView.progress = 0
    }

    @IBAction func onClickGetRequest(_ sender: Any) {
        
        progressView.progress = 0
        textView.text = ""
        Task {
            await getRequest()
        }
    }
    
    @IBAction func onClickDownload(_ sender: Any) {
        // Cannot use `async await` if we need to observe of downloading
        progressView.progress = 0
        textView.text = ""
        downloadImage()
    }
    
    @IBAction func onClickUpload(_ sender: Any) {
        // Cannot use `async await` if we need to observe of uploading
        progressView.progress = 0
        textView.text = ""
        uploadImage()
    }
    
    private func downloadImage() {
        
        let imageString = "https://img.fonwall.ru/o/kp/parig-eyfeleva-bashnya-rechka.jpg"
        let request = URLRequest(url: URL(string: imageString)!)
        
        let task = session.downloadTask(with: request) { [weak self] url, response, error in
            
            guard let self, let url, let data = try? Data(contentsOf: url) else { return }
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                self.imageView.image = image
                
                // To allow uploading the saved image:
                self.uploadButton.isEnabled = true
                self.uploadButton.alpha = 1
            }
        }
        
        observer = task.progress.observe(\.fractionCompleted) { progress, change in
            
            DispatchQueue.main.async {
                self.progressView.progress = Float(progress.fractionCompleted)
                if task.state == .canceling || task.state == .completed { self.observer = nil }
            }
        }
        task.resume()
    }
    
    private func uploadImage() {
        
        guard let data = imageView.image?.pngData() else { return }
        
        guard let (multipartData, boundary) = try? MultipartDataBuilder()
            .appendingChunk(.init(fileName: "eyfeleva", body: data))
            .appendingChunk(.init(name: "additionalMetadata", body: "Some informations".data(using: .utf8) ?? Data()))
            .get() else {
            return
        }
        
        var request = URLRequest(url: URL(string: "https://petstore.swagger.io/v2/pet/34353123/uploadImage")!)
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:  "Content-Type")
        request.addValue(String(multipartData.count), forHTTPHeaderField: "Content-Length")
        request.httpMethod = "POST"
        
        let task = session.uploadTask(with: request, from: multipartData) { [weak self] data, response, error in
            guard let self else { return }
            if let data {
                updateText(string: data.prettyPrintedJsonString)
            } else {
                updateText(string: "error = \(error?.localizedDescription ?? "")")
            }
        }
        
        observer = task.progress.observe(\.fractionCompleted) { progress, change in
            
            DispatchQueue.main.async {
                self.progressView.progress = Float(progress.fractionCompleted)
                if task.state == .canceling || task.state == .completed { self.observer = nil }
            }
        }
        task.resume()
    }
    
    func getRequest() async {
        
        let url = "https://jsonplaceholder.typicode.com/posts"
        guard let url = URL(string: url) else { return }
        let request: URLRequest = URLRequest(url: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let messages = try JSONDecoder().decode([MessageApiModel].self, from: data)
            updateText(string: messages.map { $0.title }.joined(separator: "\n\n"))
        } catch {
            updateText(string: "error = \(error.localizedDescription)")
        }
    }
      
    private func updateText(string: String?) {
        DispatchQueue.main.async {
            self.textView.text = string
        }
    }
}

struct MessageApiModel: Codable {
    var id: Int
    var userId: Int
    var title: String
    var body: String
}

extension Data {
    
    var prettyPrintedJsonString: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: [.fragmentsAllowed]),
              let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            return String(data: self, encoding: .utf8)
        }
        return String(data: data, encoding: .utf8)
    }
}
