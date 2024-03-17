# UploadDownloadApi

Upload Download with progress indication Rest Api iOS (multipart request)

```
    func downloadImage() {
        
        let imageString = "https://img.fonwall.ru/o/kp/parig-eyfeleva-bashnya-rechka.jpg"
        let request = URLRequest(url: URL(string: imageString)!)
        
        let task = session.downloadTask(with: request) { [weak self] url, response, error in
            
            guard let self, let url, let data = try? Data(contentsOf: url) else { return }
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                self.imageView.image = image
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
    
    func uploadImage() {
        
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
```
