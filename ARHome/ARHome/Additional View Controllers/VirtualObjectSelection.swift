/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Popover view controller for choosing virtual objects to place in the AR scene.
*/

import UIKit

// MARK: - ObjectCell

class ObjectCell: UITableViewCell {
    static let reuseIdentifier = "ObjectCell"
    
    @IBOutlet weak var objectTitleLabel: UILabel!
    @IBOutlet weak var objectImageView: UIImageView!
        
    var modelName = "" {
        didSet {
            objectTitleLabel.text = modelName
        }
    }
    
    var modelImage = "" {
        didSet {
            objectImageView.loadImageWithUrl(imageUrl: modelImage)
        }
    }
}

// MARK: - VirtualObjectSelectionViewControllerDelegate

/// A protocol for reporting which objects have been selected.
protocol VirtualObjectSelectionViewControllerDelegate: class {
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didSelectObject: VirtualObject)
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didDeselectObject: VirtualObject)
}

/// A custom table view controller to allow users to select `VirtualObject`s for placement in the scene.
class VirtualObjectSelectionViewController: UITableViewController {
    
    /// The collection of `VirtualObject`s to select from.
    var virtualObjects = [VirtualObject]()
    var modelList:NSArray = []
    
    /// The rows of the currently selected `VirtualObject`s.
    private var selectedVirtualObjectRows = IndexSet()
    
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
        
        // 更改数据结构
//        let newModelList = NSMutableArray.init(capacity: modelList.count)
//        for obj in modelList {
//            var objDic = obj as! Dictionary<String, Any>
//            let mutableArray = NSMutableArray.init(capacity: 1)
//            let array = objDic["list"] as! NSArray
//            for dic in array {
//                var dicObj = dic as! Dictionary<String, Any>
//                dicObj["isIn"] = false // 增加辅助数据结构
//                mutableArray.add(dicObj)
//            }
//            objDic["list"] = mutableArray
//            //
//            newModelList.add(objDic)
//        }
//        modelList = newModelList
    }
    
    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let object = virtualObjects[indexPath.row]
        let dic = modelList[indexPath.section] as! Dictionary<String, Any>
        let list = dic["list"] as! NSArray
        var data = list[indexPath.row] as! Dictionary<String, Any>
        // 初始化模型
        let fileUrl = data["fileUrl"] as! String // 注意中文问题
        let encodedUrl = fileUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL.init(string: encodedUrl!)
        let object = VirtualObject.init(url: url!)
        
        var isIn = false
        if data.keys.contains("isIn") && data["isIn"] as! Bool == true {
            isIn = true
        }
        
        // Check if the current row is already selected, then deselect it.
        if isIn {
            delegate?.virtualObjectSelectionViewController(self, didDeselectObject: object!)
            data["isIn"] = false
        } else {
            delegate?.virtualObjectSelectionViewController(self, didSelectObject: object!)
            data["isIn"] = true
        }
        debugPrint("data: \(data)")

        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView,  heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
        view.backgroundColor = UIColor.lightGray
        let label = UILabel.init(frame: CGRect.init(x: 5, y: 0, width: 120, height: 40));
        label.text = "椅子"
        view.addSubview(label)
        return view
    }
        
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return modelList.count;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dic = modelList[section] as! Dictionary<String, Any>
        let list = dic["list"] as! NSArray
        return list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ObjectCell.reuseIdentifier, for: indexPath) as? ObjectCell else {
            fatalError("Expected `\(ObjectCell.self)` type for reuseIdentifier \(ObjectCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        let dic = modelList[indexPath.section] as! Dictionary<String, Any>
        let list = dic["list"] as! NSArray
        let data = list[indexPath.row] as! Dictionary<String, Any>
        cell.modelName = data["modelName"] as! String
        cell.modelImage = data["imageUrl"] as! String
        debugPrint("data: \(data)")
        
        // 是否被选中
        if data.keys.contains("isIn") && data["isIn"] as! Bool == true {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = .clear
    }
    
    func dealloc() {
        let weakSelf = self
        debugPrint("\(weakSelf) dealloc");
    }
}
