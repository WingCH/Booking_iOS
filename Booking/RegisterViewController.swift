
import UIKit
import Alamofire

class RegisterViewController: UIViewController {
    
    
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    
    @IBOutlet weak var confirmLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    @IBAction func submit(_ sender: UIButton) {
        
        let parameters: Parameters = [
            "name": nameLabel.text!,
            "email": emailLabel.text!,
            "password": passwordLabel.text!
        ]
        
        Alamofire.request("http://www.booking.wingpage.net/iOSRegister", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseJSON { response in
            
            switch response.result {
            case .success:
                print("註冊帳號 成功")
                //去番Login個頁
                self.navigationController?.popToRootViewController(animated: true)
            case .failure(let error):
                print("註冊帳號 失敗!!!")
                print(error)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //點擊空白收起鍵盤
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(false)
    }
    
}
