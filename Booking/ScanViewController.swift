

import UIKit

class ScanViewController: UIViewController, UINavigationControllerDelegate{
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
                    self .showResult(result: r)
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
        let alert = UIAlertController(title: "掃描結果", message: result, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK!", style: .default) { (UIAlertAction) in
            self.sessionManager?.start()
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logout(_ sender: UIBarButtonItem) {
        //https://coderwall.com/p/cjuzng/swift-instantiate-a-view-controller-using-its-storyboard-name-in-xcode
        self.userDefault.removeObject(forKey: "userInfo")
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginPage") as UIViewController
        self.present(viewController, animated: false, completion: nil)

    }
    



}
