
import UIKit

//Room class
class Room: NSObject {
    var id : Int
    var name : String
    var descriptions : String
    var address : String
    var backgroundImage : String
    
    init(id: Int, name: String, descriptions : String, address : String, backgroundImage : String) {
        self.id = id
        self.name = name
        self.descriptions = descriptions
        self.address = address
        self.backgroundImage = backgroundImage
    }
}
