
import UIKit
import SwiftMoment


class Booking: NSObject {
    var id : Int
    var room_id : Int
    var user_id : Int
    var start : Moment
    var end : Moment
    var status : String?
    var room : Room?//Optional
    
    //for RoomDetailViewController
    init(id: Int, room_id : Int, user_id : Int, start : Moment, end : Moment) {
        self.id = id
        self.room_id = room_id
        self.user_id = user_id
        self.start = start
        self.end = end
    }
    
    //for HistoryViewController
    init(id: Int, room_id : Int, user_id : Int, start : Moment, end : Moment, status : String, room : Room) {
        self.id = id
        self.room_id = room_id
        self.user_id = user_id
        self.start = start
        self.end = end
        
        //database不會有Absence的status
        //如果status是Ready，但遲過現在時間的話，即係Absence
        switch status {
        case "Ready":
            let now = moment().date;
            if now > start.date{
                self.status = "Absence"
            }else{
                self.status = status
            }
        default:
            self.status = status
        }
        
        self.room = room
    }
    
}
