

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher
import SwipeCellKit
import PopupDialog

class RoomsManageCell: UITableViewCell {
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    //https://www.jianshu.com/p/01f61359b30d
    //http://blog.csdn.net/json_6/article/details/51890313
    //重寫cell的frame 製造tabel cell 間隔
    override var frame:CGRect{
        didSet {
            var newFrame = frame
            newFrame.origin.y += 10
            newFrame.size.height -= 10
            super.frame = newFrame
        }
    }
    
}

class RoomsManageViewController: UITableViewController{
    
    var roomList = [Room]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //https://www.andrewcbancroft.com/2015/03/17/basics-of-pull-to-refresh-for-swift-developers/
        self.refreshControl?.addTarget(self, action: #selector(RoomsViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        getData()
    }
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            self.getData()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return roomList.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "roomsCell", for: indexPath) as! RoomsManageCell
        // /photo/rooms/Meeting Room.jpg -> /photo/rooms/Meeting%20Room.jpg
        let path = roomList[indexPath.row].backgroundImage.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let image_url = URL(string: "http://www.booking.wingpage.net\(path!)")
        
        cell.name.text = roomList[indexPath.row].name
        cell.background.kf.setImage(with: image_url!)

        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Click \(indexPath.row)")
                self.performSegue(withIdentifier: "roomToDetail", sender: roomList[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            print("more button tapped \(self.roomList[indexPath.row].name)")
            self.showRemoveRoomDialog(index: indexPath.row)
        }
        return [delete]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func getData() {
        self.roomList.removeAll()
        Alamofire.request("http://www.booking.wingpage.net/iOSGetRoomList").response { response in
            // method defaults to `.get`
            if let data = response.data{
                do{
                    let json: JSON = try JSON(data: data)
                    
                    for (_,subJson):(String, JSON) in json {
                        let room : Room = Room(id: subJson["id"].int!, name: subJson["name"].string!, descriptions: subJson["description"].string!, address: subJson["address"].string!, backgroundImage: subJson["backgroundImage"].string!)
                        
                        self.roomList.append(room)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        self.refreshControl?.endRefreshing()
                    })
                    
                    self.tableView?.reloadData()
                    
                }catch let error {
                    print(error)
                }
            }
        }
    }
    
    func showRemoveRoomDialog(animated: Bool = true, index: Int) {
        
        let room = roomList[index]
        
        let parameters: Parameters = [
            "room_id": room.id
        ]
        
        // Prepare the popup
        let title = "確認要刪除 \(room.name) 嗎"
        let message = ""
        
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
            Alamofire.request("http://www.booking.wingpage.net/iOSDeleteRoom", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseString { response in
                
                switch response.result {
                case .success:
                    self.getData()
                case .failure(let error):
                    print(error)
                }
            }
            
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "roomToDetail"{
            let controller = segue.destination as! BookingsViewController
            controller.room = sender as? Room
        }
    }
    
}
