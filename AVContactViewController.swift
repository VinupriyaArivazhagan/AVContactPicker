//
//  AVContactViewController.swift
//  AVContactPicker
//
//  Created by Vinupriya Arivazhagan on 12/26/16.
//  Copyright © 2016 Vinupriya. All rights reserved.
//

import UIKit
import Contacts

private struct LocalConstants {
    //
    static let ContactNameKey = "name"
    static let ContactPhoneKey = "phone"
    static let ContactNumberKey = "number"
    static let ContactLabelKey = "label"
    static let ContactHashKey = "#"
    
    //
    static let SearchResultsEmpty = "No search results"
    static let SearchResultsAvailable = "Search results"
    
    //
    static let AnimationKeyPath = "position"
    
    //
    static let NamePredicate = "self.name contains[cd] %@"
    static let NumberPredicate = "self.number contains[cd] %@"
    
    static let ErrorFetchingContacts = "Error fetching Contacts"
    static let AllowAccessForContacts = "Please allow the app to access your contacts through the Settings."
    static let Contact = "Contact"
    static let LineBreak = "\n"
}

protocol AVContactDelegate: class {
    func pickedContacts(contacts: [Contact])
}

struct Contact {
    let name: String
    let mobile: String
}

class AVContactViewController: UIViewController {

    let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 64))
    
    let searchBar = UISearchBar(frame: CGRect(x: 0, y: 64, width: UIScreen.main.bounds.size.width, height: 44))
    
    let tblView = UITableView(frame: CGRect(x: 0, y: 110, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 110))
    
    let closeButton = UIButton(frame: CGRect(x: 8, y: 25, width: 78, height: 28))
    
    let pickButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width - 78 - 8 , y: 25, width: 78, height: 28))
    
    let loadingView = UIView(frame: CGRect(x: 0, y: 64, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 64))
    
    let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    weak var delegate: AVContactDelegate?
    
    
    fileprivate var maxCount = 1
    
    fileprivate var indexes = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J","K", "L", "M", "N", "O", "P", "Q", "R" ,"S", "T","U", "V", "W", "X","Y", "Z","#"]
    
    fileprivate var sectionTitles = [String]()
    
    fileprivate var contacts = [[String:String]]()
    
    fileprivate var splittedContacts = [[[String : String]]]()
    
    fileprivate var searchedContacts = [[String : String]]()
    
    fileprivate var pickedContacts = [[String:String]]()
    
    fileprivate var isShowingContacts : Bool = false
    
    //MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }

    override func viewDidAppear(_ animated: Bool) {
        if !isShowingContacts {
            loadingView.isHidden = false
            activityIndicatorView.startAnimating()
            
            // Do any additional setup after loading the view, typically from a nib.
            getAccessGranted()
            
            isShowingContacts = true
        }
    }
    
    // MARK: convenience
    
    @objc fileprivate func close(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func pickContacts(_ sender: AnyObject) {
        var contacts = [Contact]()
        for contact in pickedContacts {
            if let name = contact[LocalConstants.ContactNameKey],
                let mobile = contact[LocalConstants.ContactPhoneKey] {
                
                contacts.append(Contact(name: name, mobile: mobile))
            }
        }
        delegate?.pickedContacts(contacts: contacts)
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - class Function
    
    class func present(title: String?, maximumContactCount: Int?, updateDesign: ((_ controller: AVContactViewController) -> ())?) {
        //programmatically creating 'AVContactViewController'
        let controller = AVContactViewController()
        controller.view = UIView(frame: UIScreen.main.bounds)
        controller.view.backgroundColor = UIColor.white
        
        //Programmatically creating 'UINavigationBar' to hold 'UISearchBar'
        controller.navigationBar.topItem?.title = title ?? ""
        controller.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        controller.view.addSubview(controller.navigationBar)
        
        //setup close button
        controller.closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        controller.closeButton.setTitle("Close", for: .normal)
        controller.closeButton.setTitleColor(UIColor.black, for: .normal)
        controller.closeButton.addTarget(controller, action: #selector(controller.close(_:)), for: .touchUpInside)
        controller.navigationBar.addSubview(controller.closeButton)
        
        //setup pick button
        controller.pickButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        controller.pickButton.setTitle("Pick", for: .normal)
        controller.pickButton.setTitleColor(UIColor.black, for: .normal)
        controller.pickButton.addTarget(controller, action: #selector(controller.pickContacts(_:)), for: .touchUpInside)
        controller.navigationBar.addSubview(controller.pickButton)
        
        //setup 'UISearchBar'
        controller.searchBar.delegate = controller
        controller.view.addSubview(controller.searchBar)
        
        //setup TableView
        controller.tblView.delegate = controller
        controller.tblView.dataSource = controller
        controller.tblView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        controller.view.addSubview(controller.tblView)
        
        //setUp loading and activityIndicator views
        controller.loadingView.backgroundColor = UIColor.white
        controller.view.addSubview(controller.loadingView)
        
        controller.activityIndicatorView.color = UIColor.black
        controller.activityIndicatorView.center = controller.loadingView.center
        controller.loadingView.addSubview(controller.activityIndicatorView)
        
        controller.maxCount = maximumContactCount ?? 1
        
        if let delegate = UIApplication.shared.delegate?.window??.visibleViewController as? AVContactDelegate {
            controller.delegate =  delegate
        }
        
        updateDesign?(controller)
        
        UIApplication.shared.delegate?.window??.visibleViewController?.present(controller, animated: true, completion: nil)
    }

}

//MARK: - Contacts

fileprivate extension AVContactViewController {
    
    @available(iOS 9.0, *)
    fileprivate func getAccessGranted() {
        self.requestForAccess { (accessGranted) -> Void in
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                weak var weakSelf = self
                
                guard let strongSelf = weakSelf else { return }
                
                if accessGranted {
                    var message: String!
                    let contactStore = CNContactStore()
                    let keysToFetch = [
                        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactPhoneNumbersKey,CNContactGivenNameKey, CNContactFamilyNameKey] as [Any]
                    
                    // Get all the containers
                    var allContainers: [CNContainer] = []
                    do {
                        allContainers = try contactStore.containers(matching: nil)
                    } catch {
                        message = LocalConstants.ErrorFetchingContacts
                    }
                    
                    var contacts: [CNContact] = []
                    
                    // Iterate all containers and append their contacts to our results array
                    for container in allContainers {
                        let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                        
                        do {
                            let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                            contacts.append(contentsOf: containerResults)
                        } catch {
                            message = LocalConstants.ErrorFetchingContacts
                        }
                    }
                    
                    if contacts.count != 0
                    {
                        self.didFetchContacts(contacts)
                    }
                    else
                    {
                        message = LocalConstants.ErrorFetchingContacts
                    }
                    
                    if message != nil {
                        DispatchQueue.main.async{
                            let alertController = UIAlertController(title: LocalConstants.Contact , message: message , preferredStyle: .alert)
                            /// Present alert controller
                            self.present(alertController, animated: true, completion: nil)
                            strongSelf.activityIndicatorView.stopAnimating()
                            strongSelf.activityIndicatorView.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    @available(iOS 9.0, *)
    fileprivate func requestForAccess(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let contactStore = CNContactStore()
        
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus {
        case .authorized:
            completionHandler(true)
            
        case .denied, .notDetermined:
            contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                    weak var weakSelf = self
                    
                    guard let strongSelf = weakSelf else { return }
                    
                    if access {
                        completionHandler(access)
                    }
                    else {
                        if authorizationStatus == CNAuthorizationStatus.denied {
                            DispatchQueue.main.async{
                                let message = accessError!.localizedDescription + LocalConstants.LineBreak + LocalConstants.LineBreak + LocalConstants.AllowAccessForContacts
                                let alertController = UIAlertController(title: LocalConstants.Contact , message: message , preferredStyle: .alert)
                                /// Present alert controller
                                self.present(alertController, animated: true, completion: nil)
                                strongSelf.activityIndicatorView.stopAnimating()
                                strongSelf.activityIndicatorView.isHidden = true
                            }
                        }
                    }
                }
            })
            
        default:
            completionHandler(false)
        }
    }
    
    @available(iOS 9.0, *)
    fileprivate func didFetchContacts(_ contacts: [CNContact]) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            weak var weakSelf = self
            
            guard let strongSelf = weakSelf else { return }
            
            for contact in contacts {
                
                if (contact.isKeyAvailable(CNContactPhoneNumbersKey)) {
                    for phoneNumber:CNLabeledValue in contact.phoneNumbers {
                        let num : CNPhoneNumber = phoneNumber.value as CNPhoneNumber
                        let name =  contact.givenName.trimmingCharacters(in: CharacterSet.whitespaces) + " " + contact.familyName.trimmingCharacters(in: CharacterSet.whitespaces)
                        let value = num.stringValue
                        var contactDictionary = [String : String]()
                        
                        if ((name.trimmingCharacters(in: CharacterSet.whitespaces).characters.count > 0 ) && (value.characters.count > 0)) {
                            contactDictionary[LocalConstants.ContactNameKey] = name.trimmingCharacters(in: CharacterSet.whitespaces)
                            contactDictionary[LocalConstants.ContactNumberKey] = value
                            
                            if let label : String = phoneNumber.label
                            {
                                contactDictionary[LocalConstants.ContactLabelKey] = strongSelf.removeSpecialCharsFromString(label)
                            }
                            strongSelf.contacts.append(contactDictionary)
                        }
                    }
                }
            }
            
            var dictContact = [String : [[String : String]]]()
            strongSelf.sectionTitles.removeAll()
            strongSelf.splittedContacts.removeAll()
            
            for dict in self.contacts
            {
                let name = dict[LocalConstants.ContactNameKey]!
                
                if dictContact[name[0].uppercased()] != nil
                {
                    dictContact[name[0].uppercased()]?.append(dict)
                }
                else if !strongSelf.indexes.contains(name[0].uppercased())
                {
                    if dictContact[LocalConstants.ContactHashKey] != nil
                    {
                        dictContact[LocalConstants.ContactHashKey]?.append(dict)
                    }
                    else
                    {
                        dictContact[LocalConstants.ContactHashKey] = [dict]
                    }
                }
                else
                {
                    dictContact[name[0].uppercased()] = [dict]
                }
            }
            
            strongSelf.sectionTitles = Array(dictContact.keys).sorted(by: <)
            
            if strongSelf.sectionTitles.count > 0
            {
                if strongSelf.sectionTitles[0] == LocalConstants.ContactHashKey
                {
                    let indexFirst = strongSelf.sectionTitles[0]
                    strongSelf.sectionTitles.removeFirst()
                    strongSelf.sectionTitles.append(indexFirst)
                }
            }
            for key in strongSelf.sectionTitles {
                if let arrSectionContact = dictContact[key] {
                    strongSelf.splittedContacts.append(arrSectionContact)
                }
            }
            
            strongSelf.searchedContacts = strongSelf.contacts
            //            weak var weakSelf = self
            DispatchQueue.main.async{
                strongSelf.loadingView.isHidden = true
                strongSelf.activityIndicatorView.stopAnimating()
                strongSelf.tblView.reloadData()
            }
        }
    }
    
    fileprivate func removeSpecialCharsFromString(_ text: String) -> String {
        let okayChars : Set<Character> = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
}

//MARK: - UITableview Datasource and Delegate extension

extension AVContactViewController: UITableViewDataSource, UITableViewDelegate {

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if searchBar.text != "" {
            
            return nil
        }
        
        return indexes
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchBar.text != "" {
            if searchedContacts.count > 0 {
                
                return LocalConstants.SearchResultsAvailable
            }
            
            return LocalConstants.SearchResultsEmpty
        }
        
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchBar.text != "" {
            
            return searchedContacts.count
        }
        
        return splittedContacts[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if searchBar.text != "" {
            
            return 1
        }
        
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var contactAtIndex : [String : String] = [String : String]()
        
        if searchBar.text != "" {
            contactAtIndex = searchedContacts[indexPath.row]
        }
        else {
            contactAtIndex = splittedContacts[indexPath.section][indexPath.row]
        }
        
        let cell : ContactCell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        cell.initialize()
        
        let value = contactAtIndex[LocalConstants.ContactNumberKey]
        cell.nameLabel.text = contactAtIndex[LocalConstants.ContactNameKey]
        
        if let label = contactAtIndex[LocalConstants.ContactLabelKey] {
            cell.mobileLable.text = "\(value!) - \(label)"
        }
        else {
            cell.mobileLable.text = "\(value!)"
        }
        
        if pickedContacts.contains(where: { (contact) -> Bool in
            if contact == [LocalConstants.ContactNameKey : contactAtIndex[LocalConstants.ContactNameKey]!, LocalConstants.ContactPhoneKey : contactAtIndex[LocalConstants.ContactNumberKey]!] {
                return true
            }
            
            return false
        }) {
            cell.checkMarkLabel.text = "☑"
        }
        else {
            cell.checkMarkLabel.text = "☐"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var contactAtIndex = [String : String]()
        
        if searchBar.text != "" {
            contactAtIndex = searchedContacts[indexPath.row]
        }
        else {
            contactAtIndex = splittedContacts[indexPath.section][indexPath.row]
        }
        searchBar.resignFirstResponder()
        
        let cell : ContactCell = tableView.cellForRow(at: indexPath) as! ContactCell
        
        if !pickedContacts.contains(where: { (contact) -> Bool in
            if contact == [LocalConstants.ContactNameKey : contactAtIndex[LocalConstants.ContactNameKey]!, LocalConstants.ContactPhoneKey : contactAtIndex[LocalConstants.ContactNumberKey]!] {
                return true
            }
            
            return false
        }) {
            if pickedContacts.count < maxCount
            {
                cell.checkMarkLabel.text = "☑"
                pickedContacts.append([LocalConstants.ContactNameKey : contactAtIndex[LocalConstants.ContactNameKey]!, LocalConstants.ContactPhoneKey : contactAtIndex[LocalConstants.ContactNumberKey]!])
            }
            else
            {
                cell.shake()
            }
        }
        else
        {
            cell.checkMarkLabel.text = "☐"
            if let index = pickedContacts.index(where: { (contact) -> Bool in
                if contact == [LocalConstants.ContactNameKey : contactAtIndex[LocalConstants.ContactNameKey]!, LocalConstants.ContactPhoneKey : contactAtIndex[LocalConstants.ContactNumberKey]!] {
                    return true
                }
                
                return false
            }) {
                pickedContacts.remove(at: index)
            }
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    {
        searchBar.resignFirstResponder()
    }
}

//MARK: - UISearchBar delegate

extension AVContactViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.becomeFirstResponder()
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchText.characters.count == 0) {
            searchedContacts = contacts
        } else {
            let namePredicate = NSPredicate(format: LocalConstants.NamePredicate, searchText)
            let numberPredicate = NSPredicate(format: LocalConstants.NumberPredicate, searchText)
            let resultPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [namePredicate, numberPredicate])
            searchedContacts = contacts.filter { resultPredicate.evaluate(with: $0) }
        }
        self.tblView.reloadData()
    }
}

//MARK: - ContactCell

fileprivate class ContactCell: UITableViewCell {
    
    let checkMarkLabel = UILabel(frame: CGRect(x: 8, y: 12, width: 22, height: 22))
    let nameLabel = UILabel(frame: CGRect(x: 45, y: 6, width: UIScreen.main.bounds.size.width-45-8, height: 18))
    let mobileLable = UILabel(frame: CGRect(x: 45, y: 24, width: UIScreen.main.bounds.width-45-8, height: 15))
    
    func initialize() {
        super.awakeFromNib()
        
        checkMarkLabel.textColor = UIColor.black
        checkMarkLabel.text = "☐"
        checkMarkLabel.font = UIFont.systemFont(ofSize: 15)
        self.addSubview(checkMarkLabel)
        
        nameLabel.textColor = UIColor.black
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.text = ""
        self.addSubview(nameLabel)
        
        mobileLable.textColor = UIColor.gray
        mobileLable.font = UIFont.systemFont(ofSize: 13)
        mobileLable.text = ""
        self.addSubview(mobileLable)
    }
}

//MARK: - Utilities

fileprivate extension UIWindow {
    
    fileprivate var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(self.rootViewController)
    }
    
    fileprivate static func getVisibleViewControllerFrom(_ vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(pvc)
            } else {
                return vc
            }
        }
    }
}

fileprivate extension String {
    
    fileprivate subscript (i: Int) -> String {
        return String(self[self.characters.index(self.startIndex, offsetBy: i)])
    }
}

fileprivate extension UITableViewCell {
    
    fileprivate func shake () {
        let position : CGPoint = self.center
        
        let path : UIBezierPath = UIBezierPath()
        path.move(to: CGPoint(x: position.x, y: position.y))
        path.addLine(to: CGPoint(x: position.x-10, y: position.y))
        path.addLine(to: CGPoint(x: position.x+10, y: position.y))
        path.addLine(to: CGPoint(x: position.x-10, y: position.y))
        path.addLine(to: CGPoint(x: position.x+10, y: position.y))
        path.addLine(to: CGPoint(x: position.x, y: position.y))
        let positionAnimation : CAKeyframeAnimation = CAKeyframeAnimation(keyPath: LocalConstants.AnimationKeyPath)
        positionAnimation.path = path.cgPath
        positionAnimation.duration = 0.5
        positionAnimation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)]
        CATransaction.begin()
        self.layer.add(positionAnimation, forKey: nil)
        CATransaction.commit()
    }
}
