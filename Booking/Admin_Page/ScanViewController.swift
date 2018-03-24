

import UIKit
import NVActivityIndicatorView
import PopupDialog
import Alamofire
import SwiftyJSON
import SwiftMoment

class ScanViewController: UIViewController, UINavigationControllerDelegate, NVActivityIndicatorViewable{
    let userDefault = UserDefaults.standard
    var sessionManager:AVCaptureSessionManager?
    var link: CADisplayLink?
    var torchState = false
    
    @IBOutlet weak var scanTop: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AVCaptureSessionManager.checkAuthorizationStatusForCamera(grant: {
            self.link = CADisplayLink(target: self, selector: #selector(self.scan))
            
            self.sessionManager = AVCaptureSessionManager(captureType: .AVCaptureTypeBoth, scanRect: CGRect.null, success: { (result) in
                if let r = result {
                    self.showResult(result: r)
                }
            })
            self.sessionManager?.showPreViewLayerIn(view: self.view)
            self.sessionManager?.isPlaySound = true
        }){
            let action = UIAlertAction(title: "確定", style: UIAlertActionStyle.default, handler: { (action) in
                let url = URL(string: UIApplicationOpenSettingsURLString)
                let options = [UIApplicationOpenURLOptionUniversalLinksOnly : false]
                UIApplication.shared.open(url!, options: options, completionHandler: nil)
            })
            let con = UIAlertController(title: "權限未開啓", message: "您未開啓相機權限，點擊確定跳轉至系統設置開啓", preferredStyle: UIAlertControllerStyle.alert)
            con.addAction(action)
            self.present(con, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        link?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        sessionManager?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        link?.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
        sessionManager?.stop()
    }
    
    @objc func scan() {
        scanTop.constant -= 1;
        if (scanTop.constant <= -170) {
            scanTop.constant = 170;
        }
    }
    
    @IBAction func changeState(_ sender: UIButton) {
        torchState = !torchState
        let str = torchState ? "關閉閃光燈" : "開啓閃光燈"
        sessionManager?.turnTorch(state: torchState)
        sender.setTitle(str, for: .normal)
    }
    
    
    func showResult(result: String) {
        start_loadingView()
        
        Alamofire.request("http://www.booking.wingpage.net/iOSGetBookingByBookingID/\(result)").response { response in
            if let data = response.data{
                do{
                    let bookingData: JSON = try JSON(data: data)
                    
                    let message =
                        "User : \(bookingData["user"]["name"].string!)\n\n" +
                            "Room : \(bookingData["room"]["name"].string!)\n" +
                    "Time :\n\n \(self.changeToMoment(date: bookingData["start"].string!)) \nto\n \(self.changeToMoment(date: bookingData["end"].string!))\n"
                    
                    
                    self.showDialog(title: "Info", message: message,booking_id: bookingData["id"].int!)
                }catch _ {
                    //self.showDialog(title: "Error", message: error.localizedDescription, booking_id: nil);
                    self.showDialog(title: "Error", message: "Cannot find record", booking_id: nil);
                }
            }
        }
        
    }
    
    @IBAction func logout(_ sender: UIBarButtonItem) {
        //https://coderwall.com/p/cjuzng/swift-instantiate-a-view-controller-using-its-storyboard-name-in-xcode
        //移除儲存在userDefault的user資料
        self.userDefault.removeObject(forKey: "userInfo")
        //利用Storyboard ID 去翻個Login頁面
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginPage") as UIViewController
        self.present(viewController, animated: false, completion: nil)
    }
    
    func showDialog(animated: Bool = true, title: String,message: String, booking_id: Int?) {
        self.stop_loadingView()
        // Create the dialog
        let popup = PopupDialog(title: title,
                                message: message,
                                buttonAlignment: .vertical,
                                transitionStyle: .bounceUp,
                                gestureDismissal: false,
                                hideStatusBar: true)

        if (booking_id == nil){
            let ok_Button = CancelButton(title: "OK") {
                self.sessionManager?.start()
            }
            popup.addButtons([ok_Button])
        }else{
            let checkIn_Button = DefaultButton(title: "Check In", dismissOnTap: false) {
                
                let parameters: Parameters = [
                    "booking_id": booking_id!,
                    "status": "Attend"
                ]
                Alamofire.request("http://www.booking.wingpage.net/iOSUpdateStatus", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseString { response in

                    switch response.result {
                    case .success:
                        popup.dismiss()
                    case .failure(let error):
                        print(error)
                        popup.shake()
                    }
                }
                self.sessionManager?.start()
            }
            
            let cancel_Button = CancelButton(title: "Cancel") {
                self.sessionManager?.start()
            }
            popup.addButtons([checkIn_Button,cancel_Button])
        }
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    func start_loadingView() {
        let size = CGSize(width: 30, height: 30)
        startAnimating(size, message: "Loading...", type: NVActivityIndicatorType(rawValue: 17)!)
        
    }
    
    func stop_loadingView() {
        stopAnimating()
    }
    
    
    func changeToMoment(date : String) -> Moment{
        //因為moment有問題 https://github.com/akosma/SwiftMoment/issues/101
        //臨時解決方法：直接用moment(year,month,day,hour,minute,second) 可以避免個bug
        //eg: 2018-01-04 11:00:00
        //硬柝String
        let year = Int(date[0...3]!)
        let month = Int(date[5...6]!)
        let day = Int(date[8...9]!)
        let hour = Int(date[11...12]!)
        let minute = Int(date[14...15]!)
        let second = Int(date[17...18]!)
        
        return moment([year!, month!, day!, hour!, minute!, second!])!
    }
}
