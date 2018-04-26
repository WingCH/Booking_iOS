//
//  AddRoomViewController.swift
//  Booking
//
//  Created by Chan Hong Wing on 26/4/2018.
//  Copyright © 2018年 BookingTeam. All rights reserved.
//

import UIKit
import Alamofire

class AddRoomViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var roomName: UITextField!
    
    @IBOutlet weak var roomDescription: UITextField!
    
    @IBOutlet weak var roomAddress: UITextField!
    
    
    @IBOutlet weak var roomPhotoVC: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func selertRoomPhoto(_ sender: UIButton) {
        let imagePickerVC = UIImagePickerController()
        // 設定相片的來源為行動裝置內的相本
        imagePickerVC.sourceType = .photoLibrary
        imagePickerVC.delegate = self
        
        // 設定顯示模式為popover
        imagePickerVC.modalPresentationStyle = .popover
        let popover = imagePickerVC.popoverPresentationController
        // 設定popover視窗與哪一個view元件有關連
        popover?.sourceView = sender
        
        // 以下兩行處理popover的箭頭位置
        popover?.sourceRect = sender.bounds
        popover?.permittedArrowDirections = .any
        
        show(imagePickerVC, sender: self)

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        roomPhotoVC.image = image
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func submitBtn(_ sender: UIButton) {
        let roomName = self.roomName.text!
        let roomDescription = self.roomDescription.text!
        let roomAddress = self.roomAddress.text!
        let roomPhoto = self.roomPhotoVC.image!
        
        let parameters: Parameters = [
            "name": roomName,
            "description" : roomDescription,
            "address":roomAddress
        ]
        
//        Alamofire.request("http://www.booking.wingpage.net/iOSAddRoom", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseString { response in
//            print(response)
//        }
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(UIImageJPEGRepresentation(roomPhoto, 1)!, withName: "background",fileName: "file.jpg", mimeType: "image/jpg")
            for (key, value) in parameters {
                multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
            } //Optional for extra parameters
        },
                         to:"http://www.booking.wingpage.net/iOSAddRoom")
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
//                upload.uploadProgress(closure: { (progress) in
//                })
                
                upload.responseJSON { response in
                    self.navigationController?.popToRootViewController(animated: true)
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
