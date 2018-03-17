
import UIKit
import SwipeCellKit
import Alamofire
import SwiftyJSON
import SwiftMoment
import CRRefresh
import PopupDialog
import EFQRCode

class MyCell: SwipeTableViewCell {
    //https://www.ralfebert.de/tutorials/ios-swift-uitableviewcontroller/custom-cells/
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var date_MM: UILabel!
    @IBOutlet weak var date_dd: UILabel!
    @IBOutlet weak var calendarView: UIView!
    @IBOutlet weak var status: UILabel!
}

class HistoryViewController: UITableViewController , SwipeTableViewCellDelegate{
    
    var bookedList = [Booking]()
    let userDefault = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        tableView.cr.addHeadRefresh(animator: FastAnimator()) { [weak self] in
            /// 开始刷新了
            /// 开始刷新的回调
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self?.getData()
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        //區域數量
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //每個區域的行數
        return bookedList.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MyCell
        cell.delegate = self
        
        //boredColor cannot setup in storyboard https://www.hackingwithswift.com/example-code/calayer/how-to-add-a-border-outline-color-to-a-uiview
        cell.calendarView.layer.borderColor = UIColor.lightGray.cgColor
        
        cell.date_MM?.text = "\(bookedList[indexPath.row].start.month)月"
        cell.date_dd?.text = "\(bookedList[indexPath.row].start.day)"
        
        cell.roomName?.text = bookedList[indexPath.row].room?.name
        cell.time?.text = "\(bookedList[indexPath.row].start.format("HH:mm")) - \(bookedList[indexPath.row].end.format("HH:mm"))"
        cell.address?.text = bookedList[indexPath.row].room?.address
        
        switch bookedList[indexPath.row].status!{
        case "Ready":
            let now = moment().date;
            
            if now > bookedList[indexPath.row].start.date{
                cell.status.text = "Absence";
                cell.status.backgroundColor = UIColor(red: 217.0/255.0, green: 83.0/255.0, blue: 78.0/255.0, alpha: 1.0)
            }else{
                cell.status.text = "Ready";
                cell.status.backgroundColor = UIColor(red: 90.0/255.0, green: 192.0/255.0, blue: 222.0/255.0, alpha: 1.0)
            }
            
        case "Attend":
            cell.status.text = "Attend";
            cell.status.backgroundColor = UIColor(red: 91.0/255.0, green: 184.0/255.0, blue: 91.0/255.0, alpha: 1.0)
            
        case "Cancel":
            cell.status.text = "Cancel";
            cell.status.backgroundColor = UIColor(red: 119.0/255.0, green: 119.0/255.0, blue: 119.0/255.0, alpha: 1.0)
            
        default: break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(bookedList[indexPath.row].id)
        if let qrCode = EFQRCode.generate(
            content: "\(bookedList[indexPath.row].id)"
            ) {
            //Create QRCode image success
            showQRCodeDialog(qrCode: UIImage(cgImage: qrCode))
        } else {
            showErrorDialog(error: "Create QRCode image failed!")
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        //左
        if orientation == .left {
//            let deleteAction = SwipeAction(style: .destructive, title: "Test") { action, indexPath in
//                print("delete")
//            }
//            return [deleteAction]
            return []
        }else{
            //右
            if bookedList[indexPath.row].status == "Ready"{
                if moment().date > bookedList[indexPath.row].start.date{
                    return []
                }else{
                    let cancelAction = SwipeAction(style: .default, title: nil) { action, indexPath in
                        
                        self.showBookingDialog(index: indexPath.row)
                    }
                    cancelAction.image = UIImage(named: "cancel")
                    return [cancelAction]
                }
            }
            return []
        }
    }
    
    func showQRCodeDialog(qrCode:UIImage) {
        
        let title = "Check In QRCode"
        let message = "Use this QRCode check in"
        
        let popup = PopupDialog(title: title, message: message, image: qrCode)
        
        let okButton = CancelButton(title: "OK") {
            print("You canceled the car dialog.")
        }
        popup.addButtons([okButton])
        popup.transitionStyle = .fadeIn
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func showErrorDialog(error:String) {
        
        let title = "Error"
        let message = error
        
        let popup = PopupDialog(title: title, message: message)
        
        let okButton = CancelButton(title: "OK") {
            print("You canceled the car dialog.")
        }
        popup.addButtons([okButton])
        popup.transitionStyle = .bounceUp
        
        self.present(popup, animated: true, completion: nil)
    }
    
    
    func showBookingDialog(animated: Bool = true, index: Int) {
        
        let booking = bookedList[index]
        
        let parameters: Parameters = [
            "booking_id": booking.id,
            "status": "Cancel"
        ]
        
        // Prepare the popup
        let title = "確認要取消booking嗎"
        let message = "時間: \n \(booking.start) \n to \n \(booking.end)"
        
        // Create the dialog
        let popup = PopupDialog(title: title,
                                message: message,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceUp,
                                gestureDismissal: true,
                                hideStatusBar: true) {
                                    print("Completed")
        }
        
        // Create first button
        let buttonOne = CancelButton(title: "CANCEL") {
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "OK") {
            Alamofire.request("http://www.booking.wingpage.net/iOSUpdateStatus", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseString { response in
                
                switch response.result {
                case .success:
                    print("Booking 已取消")
                    self.getData()
                case .failure(let error):
                    print("取消Booking 失敗")
                    print(error)
                }
            }
            
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    func getData(){
        
        //每load一次date 先刪除之前的date
        self.bookedList.removeAll()
        //method defaults to `.get`
        var user = self.userDefault.object(forKey: "userInfo") as? [String : Any]
        
        Alamofire.request("http://www.booking.wingpage.net/iOSGetBookingListByUserID/\(user!["id"]!)").response { response in
            if let data = response.data{
                do{
                    let events: JSON = try JSON(data: data)
                    for (_,subJson):(String, JSON) in events {
                        let booking : Booking = Booking(id: subJson["id"].int!,
                                                        room_id: subJson["room_id"].int!,
                                                        user_id: subJson["user_id"].int!,
                                                        start: self.changeToMoment(date: subJson["start"].string!),
                                                        end: self.changeToMoment(date: subJson["end"].string!),
                                                        status: subJson["status"].string!,
                                                        room: Room(id: subJson["room"]["id"].int!, name: subJson["room"]["name"].string!, descriptions: subJson["room"]["description"].string!, address: subJson["room"]["address"].string!, backgroundImage: subJson["room"]["backgroundImage"].string!))
                        self.bookedList.append(booking)
                    }
                    //sort by date
                    self.bookedList.sort(by: {$0.start > $1.start})
                    
                    self.tableView.cr.endHeaderRefresh()
                    self.tableView.reloadData();
                }catch let error {
                    print("getDate() error : ",error)
                }
            }
        }
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
