import UIKit
import CalendarKit
import DateToolsSwift
import Alamofire
import SwiftyJSON
import SwiftMoment
import PopupDialog

import UIKit

class BookingsViewController: DayViewController, DatePickerControllerDelegate {
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
        _ = self.userDefault.object(forKey: "userInfo") as? [String : Any]
        
        var events = [Event]()
        
        for (index, booking) in bookingList.enumerated() {
            let event = Event()
            event.startDate = booking.start.date
            event.endDate = booking.end.date
            
            event.color = UIColor(red: 121.0/255.0, green: 121.0/255.0, blue: 121.0/255.0, alpha: 1.0)
            event.text = "User ID : \(booking.user_id) have been booked\nStatus: \(booking.status!)"
            event.userInfo = index
            events.append(event)
        }
        return events
    }
    
    
    // MARK: DayViewDelegate
    
    //長按新增booking https://github.com/richardtop/CalendarKit/issues/116
    override func dayViewDidLongPressTimelineAtHour(_ hour: Int) {
        print("dayViewDidLongPressTimelineAtHour", hour)
        //        let now = moment().date.hour;
        //        if now >= hour  {
        //            showAlertDialog(animated: true, message: "過去了")
        //        }else{
        //            var user = self.userDefault.object(forKey: "userInfo") as? [String : Any]
        //            let start = moment((dayView.state?.selectedDate)!).add(hour+8, .Hours)
        //            let end = start.add(1, .Hours)
        //            let parameters: Parameters = [
        //                "user_id": user!["id"]!,
        //                "room_id": room!.id,
        //                "start": start.date,
        //                "end":end.date
        //            ]
        //            showBookingDialog(parameters: parameters)
        //        }
        
    }
    
    
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        print(eventView)
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        
        print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo!))")
        showRemoveRoomDialog(index: Int(String(describing: descriptor.userInfo!))!, status: "a")
    }
    
    func showRemoveRoomDialog(animated: Bool = true, index: Int, status: String) {
        
        let booking = bookingList[index]
        
        // Prepare the popup
        let title = "確定修改Booking狀態?"
        let message = "User ID: \(booking.user_id)\nStatus: \(status) \n Time: \n \(booking.start.date) \n to \n \(booking.end.date) \n\n 請選擇以下狀態"
        
        // Create the dialog
        let popup = PopupDialog(title: title,
                                message: message,
                                buttonAlignment: .vertical,
                                transitionStyle: .bounceUp,
                                gestureDismissal: true,
                                hideStatusBar: true) {
                                    print("Completed")
        }
        
        // Create first button
        let dismiss = CancelButton(title: "Dismiss") {
        }
        
        // Create second button
        let absence_btn = DefaultButton(title: "Absence") {
            self.changeBookingStatus(booking_id: booking.id, status: "Absence")
        }
        
        let ready_btn = DefaultButton(title: "Ready") {
            self.changeBookingStatus(booking_id: booking.id, status: "Ready")
        }
        let attend_btn = DefaultButton(title: "Attend") {
            self.changeBookingStatus(booking_id: booking.id, status: "Attend")
        }
        let cancel_btn = DefaultButton(title: "Cancel") {
            self.changeBookingStatus(booking_id: booking.id, status: "Cancel")
        }
        
        
        // Add buttons to dialog
        popup.addButtons([dismiss, absence_btn, ready_btn, attend_btn, cancel_btn])
        
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
    
    func changeBookingStatus(booking_id:Int, status: String){
        
        let parameters: Parameters = [
            "booking_id": booking_id,
            "status" : status
        ]
        
        Alamofire.request("http://www.booking.wingpage.net/iOSUpdateStatus", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseString { response in
            
            switch response.result {
            case .success:
                self.getData()
            case .failure(let error):
                print(error)
            }
        }
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
//                        print(subJson["user"]["name"].string!)
                        let booking : Booking = Booking(id: subJson["id"].int!,
                                                        room_id: subJson["room_id"].int!,
                                                        user_id: subJson["user_id"].int!,
                                                        start: self.changeToMoment(date: subJson["start"].string!),
                                                        end: self.changeToMoment(date: subJson["end"].string!),
                                                        status: subJson["status"].string!,
                                                        room: Room(id: subJson["room"]["id"].int!, name: subJson["room"]["name"].string!, descriptions: subJson["room"]["description"].string!, address: subJson["room"]["address"].string!, backgroundImage: subJson["room"]["backgroundImage"].string!))
                        
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
