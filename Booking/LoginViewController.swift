

import UIKit
import Alamofire
import SwiftyJSON

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    

    

    let userDefault = UserDefaults.standard
    
    
    //進入頁面時隱藏navbar
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        
        
        if let user:[String : Any] = self.userDefault.object(forKey: "userInfo") as? [String : Any] {
            print(user)
            self.performSegue(withIdentifier: "loginToList", sender: nil)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel.text = "abc@demo.com";
        passwordLabel.text = "123456";
        // Do any additional setup after loading the view, typically from a nib.

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(_ sender: UIButton) {
        
        let parameters: Parameters = [
            "email": emailLabel.text!,
            "password": passwordLabel.text!
        ]
        
        print(parameters);
        
        Alamofire.request("http://www.booking.wingpage.net/iOSLogin", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseJSON { response in
            
            switch response.result {
            case .success:
                if let data = response.data{
                    print("Login成功")
                    
                    do{
                        // get return data
                        let json: JSON = try JSON(data: data)
                        print(json)
                        // user data
                        let userArray : [String : Any] =
                            ["name":json["name"].string!,
                             "email":json["email"].string!,
                             "id":json["id"].int!]
                        //save data to userDefault
                        self.userDefault.set(userArray, forKey: "userInfo")
                        self.userDefault.synchronize()
                        self.performSegue(withIdentifier: "loginToList", sender: nil)
                    }catch let error {
                        print(error)
                    }
                    
                    
                }
            case .failure(let error):
                print("Login失敗")
                print(error)
            }
        }
    }
    
    //離開頁面時取消隱藏navbar
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    //點擊空白收起鍵盤
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(false)
    }
    
}

