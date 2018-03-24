import UIKit
import CalendarKit
import DateToolsSwift
import Alamofire
import SwiftyJSON
import SwiftMoment
import PopupDialog

class RoomDetailViewController: DayViewController, DatePickerControllerDelegate {
    var room:Room?
    var data = [["已book"]]
    var bookingList = [Booking]()
    let userDefault = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("你已選擇:",room!)
        title = room!.name
        
        //右上角選擇時間個個button
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "calendar_icon"),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(RoomDetailViewController.presentDatePicker))
        
        
        navigationController?.navigationBar.isTranslucent = false
        
        dayView.scrollTo(hour24: Float(moment().hour))
        
        getData()
    }
    
    @objc func presentDatePicker() {
        let picker = DatePickerController()
        picker.date = dayView.state!.selectedDate
        picker.delegate = self
        let navC = UINavigationController(rootViewController: picker)
        navigationController?.present(navC, animated: true, completion: nil)
    }
    
    func datePicker(controller: DatePickerController, didSelect date: Date?) {
        if let date = date {
            dayView.state?.move(to: date)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: EventDataSource
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        print("eventsForDate")
        var user = self.userDefault.object(forKey: "userInfo") as? [String : Any]
        
        var events = [Event]()
        
        for booking in bookingList {
            // Create new EventView
            let event = Event()
            event.startDate = booking.start.date
            event.endDate = booking.end.date
            if booking.user_id == user!["id"] as! Int {
                event.color = UIColor(red: 115.0/255.0, green: 252.0/255.0, blue: 213.0/255.0, alpha: 1.0)
                event.text = "You have been booked"
            }else{
                event.color = UIColor(red: 121.0/255.0, green: 121.0/255.0, blue: 121.0/255.0, alpha: 1.0)
                event.text = "Others have been booked"
            }
            events.append(event)
        }
        
        return events
    }
    
    
    // MARK: DayViewDelegate
    
    //長按新增booking https://github.com/richardtop/CalendarKit/issues/116
    override func dayViewDidLongPressTimelineAtHour(_ hour: Int) {
        print("dayViewDidLongPressTimelineAtHour", hour)
        let now = moment().date.hour;
        if now >= hour  {
            showAlertDialog(animated: true, message: "過去了")
        }else{
            var user = self.userDefault.object(forKey: "userInfo") as? [String : Any]
            let start = moment((dayView.state?.selectedDate)!).add(hour+8, .Hours)
            let end = start.add(1, .Hours)
            let parameters: Parameters = [
                "user_id": user!["id"]!,
                "room_id": room!.id,
                "start": start.date,
                "end":end.date
            ]
            showBookingDialog(parameters: parameters)
        }
        
    }
    
    
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        print(eventView)
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    override func dayView(dayView: DayView, willMoveTo date: Date) {
        //    print("DayView = \(dayView) will move to: \(date)")
    }
    
    override func dayView(dayView: DayView, didMoveTo date: Date) {
        //    print("DayView = \(dayView) did move to: \(date)")
    }
    
    func showBookingDialog(animated: Bool = true, parameters: Parameters) {
        
        // Prepare the popup
        let title = "確認嗎"
        let message = "時間: \n \(parameters["start"]!) \n to \n \(parameters["end"]!)"
        
        // Create the dialog
        let popup = PopupDialog(title: title,
                                message: message,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceUp,
                                gestureDismissal: true,
                                hideStatusBar: false)
        // Create first button
        let cancel_Button = CancelButton(title: "CANCEL"){}
        
        // Create second button
        let booking_button = DefaultButton(title: "OK") {
            Alamofire.request("http://www.booking.wingpage.net/iOSBookRoom", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseJSON { response in
                
                switch response.result {
                case .success:
                    print("Booking 成功")
                    self.getData()
                case .failure(let error):
                    print("Booking 失敗")
                    print(error)
                }
            }
            
        }
        // Add buttons to dialog
        popup.addButtons([cancel_Button, booking_button])
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    func showAlertDialog(animated: Bool = true, message: String) {
        // Prepare the popup
        let title = "Alert"
        // Create the dialog
        let popup = PopupDialog(title: title,
                                message: message,
                                buttonAlignment: .horizontal,
                                transitionStyle: .zoomIn,
                                gestureDismissal: true,
                                hideStatusBar: false)
        // Create first button
        let cancel_Button = CancelButton(title: "OK") {}

        // Add buttons to dialog
        popup.addButtons([cancel_Button])
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    
    
    
    func getData(){
        //每load一次date 先刪除之前的date
        self.bookingList.removeAll()
        //method defaults to `.get`
        Alamofire.request("http://www.booking.wingpage.net/iOSGetBookingListByRoomID/\(room!.id)").response { response in
            if let data = response.data{
                do{
                    let events: JSON = try JSON(data: data)
                    for (_,subJson):(String, JSON) in events {
                        
//                        let booking : Booking = Booking(id: subJson["id"].int!,
//                                                        room_id: subJson["room_id"].int!,
//                                                        user_id: subJson["user_id"].int!,
//                                                        start: moment(subJson["start"].string!, dateFormat: "YYYY-MM-DD HH:mm:ss")!,
//                                                        end: moment(subJson["end"].string!, dateFormat: "YYYY-MM-DD HH:mm:ss")!)
                        
                        let booking : Booking = Booking(id: subJson["id"].int!,
                                                        room_id: subJson["room_id"].int!,
                                                        user_id: subJson["user_id"].int!,
                                                        start: self.changeToMoment(date: subJson["start"].string!),
                                                        end: self.changeToMoment(date: subJson["end"].string!))
                        
                        self.bookingList.append(booking)
                    }
                    
                    self.reloadData()
                }catch let error {
                    print(error)
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
