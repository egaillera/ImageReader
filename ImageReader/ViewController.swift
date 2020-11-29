//
//  ViewController.swift
//  ImageReader
//
//  Created by Enrique Garcia Illera on 01/11/2020.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var textMessage:UILabel!
    @IBOutlet weak var progressMessage:UILabel!
    
    var numberImagesUploaded = 0
    var totalImages = 0
    var grantAccessToPhotos = false
    var imagesAndVideos:PHFetchResult<PHAsset>? = nil
    
    @IBAction func startAction() {
        print("Start button pressed")
        self.extractPhotosAndVideos(imageIndex:0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        textMessage.text = "0 photos read"
        progressMessage.text = "\(numberImagesUploaded) photos uploaded"
        // Do any additional setup after loading the view.
        
        checkAuthorizationForPhotoLibraryAndGet()
    }
    
    private func getPhotosAndVideos(){

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        imagesAndVideos = PHAsset.fetchAssets(with: fetchOptions)
        totalImages = imagesAndVideos!.count
        print("Found \(totalImages) photos")
        DispatchQueue.main.async {
            self.textMessage.text = "\(self.totalImages) photos read"
        }
        
    }
    
    private func extractPhotosAndVideos(imageIndex:Int) {
        
        let imageName = imagesAndVideos![imageIndex].localIdentifier.components(separatedBy: "/")[0]
        let assetToUpload = imagesAndVideos![imageIndex]
        print("Description of photo \(imageIndex): \(imageName)")
        
        let requestImageOption = PHImageRequestOptions()
        requestImageOption.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat

        let manager = PHImageManager.default()
        manager.requestImage(for: assetToUpload, targetSize: PHImageManagerMaximumSize, contentMode:PHImageContentMode.default, options: requestImageOption) { (image:UIImage?, _) in
            
            print("Got an UIImage")
            self.uploadImage(imageToUpload: image!, imageName: imageName)
    
        }
        
    }

    private func checkAuthorizationForPhotoLibraryAndGet(){
        let status = PHPhotoLibrary.authorizationStatus()

        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
            getPhotosAndVideos()
        }
        else {
            PHPhotoLibrary.requestAuthorization({ (newStatus) in

                if (newStatus == PHAuthorizationStatus.authorized) {
                    self.getPhotosAndVideos()
                }
                else {

                }
            })
        }
    }
    
    private func uploadImage(imageToUpload:UIImage, imageName:String) {
        
        print("Trying to upload image \(imageName)")

        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        // Set the URLRequest to POST and to the specified URL
        var urlRequest = URLRequest(url: URL(string: "http://192.168.1.39:8000")!)
        urlRequest.httpMethod = "POST"

        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()


        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"\(imageName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(imageToUpload.pngData()!)

        // End the raw http request data, note that there is 2 extra dash ("-") at the end, this is to indicate the end of the data
        // According to the HTTP 1.1 specification https://tools.ietf.org/html/rfc7230
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        // Send a POST request to the URL, with the data we created earlier
        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
            
            if(error != nil){
                print("\(error!.localizedDescription)")
            }
            
            guard let responseData = responseData else {
                print("no response data")
                return
            }
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("Server response: \(responseString)")
                self.numberImagesUploaded += 1
                DispatchQueue.main.async {
                    // Image uploaded. Extract next one
                    self.progressMessage.text = "\(self.numberImagesUploaded) photos uploaded"
                    if (self.numberImagesUploaded < self.totalImages) {
                        self.extractPhotosAndVideos(imageIndex: self.numberImagesUploaded)
                    }
                }
            }
        }).resume()
        
    }

}

