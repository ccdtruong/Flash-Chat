//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {
    
    var messages : [Message] = []

    let db = Firestore.firestore()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self

        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessage()
    }
    
    func loadMessage() {
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener() { querySnapshot, error in
            if error != nil{
                print("Fail to get data. \(error!)")
            }
            else if let snapshot = querySnapshot{
                self.messages.removeAll()
                for document in snapshot.documents {
                    if let messageSender = document[K.FStore.senderField] as? String, let message = document[K.FStore.messageField] as? String {
                        let newMessage = Message(sender: messageSender, message: message)
                        self.messages.append(newMessage)
                    }
                }
            }
            else {
                print("Data is nil")
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.scrollToRow(at: IndexPath(row: self.messages.count-1, section: 0), at: .top, animated: true)
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if messageTextfield.text == "" {
            return
        }
        if let messageSender = Auth.auth().currentUser?.email, let message = messageTextfield.text {
            
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField: messageSender,
                K.FStore.messageField: message,
                K.FStore.dateField: Date().timeIntervalSince1970
            ]) { error in
                if error != nil {
                    print("Fail to save data to firestore with error : \(error!)")
                }
                else{
                    print("Message added successful")
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                }
            }
        }
        
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        cell.messageLabel.text = message.message
        
        if message.sender == Auth.auth().currentUser?.email {
            cell.ownerAvatar.isHidden = false
            cell.otherUserAvatar.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.messageLabel.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        else{
            cell.ownerAvatar.isHidden = true
            cell.otherUserAvatar.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.messageLabel.textColor = UIColor(named: K.BrandColors.purple)
        }
        return cell
    }
    
    
}
