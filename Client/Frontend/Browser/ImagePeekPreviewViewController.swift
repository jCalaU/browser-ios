//
//  ImagePeekPreviewViewController.swift
//  Client
//
//  Created by Chris Turner on 10/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import Shared
import Photos
import Alamofire

class ImagePeekPreviewViewController: UIViewController {

    public var imageUrl:URL?
    public var parentVC:UIViewController?
    
    convenience init(imageURLString:String){
        self.init()
        
        self.imageUrl = URL(string: imageURLString)
        
        if let imageData = try? Data(contentsOf: self.imageUrl!){
            let imageView = UIImageView(image: UIImage(data: imageData))
            imageView.contentMode = .scaleAspectFit
            self.view = imageView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var previewActionItems: [UIPreviewActionItem]{
        let saveAction = UIPreviewAction.init(title: "Save image", style: UIPreviewActionStyle.default) { (action, viewcontroller) in
            let photoAuthorizeStatus = PHPhotoLibrary.authorizationStatus()
            if photoAuthorizeStatus == PHAuthorizationStatus.authorized{
                
                Alamofire.request(self.imageUrl!)
                    .validate(statusCode: 200..<300)
                    .response { response in
                        if let data = response.data,
                            //let image = UIImage.dataIsGIF(data) ? UIImage.imageFromGIFDataThreadSafe(data) : UIImage.imageFromDataThreadSafe(data) {
                            let image = UIImage(data: data){
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }
                }
            } else {
                let accessDenied = UIAlertController(title: Strings.Brave_would_like_to_access_your_photos, message: Strings.This_allows_you_to_save_the_image_to_your_CameraRoll, preferredStyle: UIAlertControllerStyle.alert)
                let dismissAction = UIAlertAction(title: Strings.Cancel, style: UIAlertActionStyle.default, handler: nil)
                accessDenied.addAction(dismissAction)
                let settingsAction = UIAlertAction(title: Strings.Open_Settings, style: UIAlertActionStyle.default ) { (action: UIAlertAction!) -> Void in
                    UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString)! as URL)
                }
                accessDenied.addAction(settingsAction)
                self.parentVC!.present(accessDenied, animated: true, completion: nil)
            }
        }
        
        let copyAction = UIPreviewAction.init(title: "Copy Image", style: UIPreviewActionStyle.default) { (action, viewcontroller) in
            // put the actual image on the clipboard
            // do this asynchronously just in case we're in a low bandwidth situation
            let pasteboard = UIPasteboard.general
            pasteboard.url = self.imageUrl!
            let changeCount = pasteboard.changeCount
            let application = UIApplication.shared
            var taskId: UIBackgroundTaskIdentifier = 0
            taskId = application.beginBackgroundTask (expirationHandler: { _ in
                application.endBackgroundTask(taskId)
            })
            
            Alamofire.request(self.imageUrl!)
                .validate(statusCode: 200..<300)
                .response { response in
                    // Only set the image onto the pasteboard if the pasteboard hasn't changed since
                    // fetching the image; otherwise, in low-bandwidth situations,
                    // we might be overwriting something that the user has subsequently added.
                    if changeCount == pasteboard.changeCount, let imageData = response.data, response.error == nil {
                        pasteboard.addImageWithData(imageData, forURL: self.imageUrl!)
                    }
                    
                    application.endBackgroundTask(taskId)
            }
        }
        
        return [saveAction, copyAction]
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
