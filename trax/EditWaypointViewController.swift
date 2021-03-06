//
//  AppDelegate.swift
//  trax
//
//  Created by Cristina Rodriguez Fernandez on 15/8/16.
//  Copyright © 2016 CrisRodFe. All rights reserved.
//

import UIKit

class EditWaypointViewController: UIViewController, UITextFieldDelegate
{
    // MARK: Public API

    var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        nameTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenToTextFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToTextFields()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        preferredContentSize = view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
        
    // MARK: Private Implementation
    
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    @IBOutlet weak var infoTextField: UITextField! { didSet { infoTextField.delegate = self } }

    fileprivate func updateUI() {
        nameTextField?.text = waypointToEdit?.name
        infoTextField?.text = waypointToEdit?.info
    }
    
    fileprivate var ntfObserver: NSObjectProtocol?
    fileprivate var itfObserver: NSObjectProtocol?

    //Recogeremos todos los cambios que tengan cada uno de los textFields
    fileprivate func listenToTextFields()
    {
        let center = NotificationCenter.default
        let queue = OperationQueue.main
        
        ntfObserver = center.addObserver(
            forName: NSNotification.Name.UITextFieldTextDidChange,
            object: nameTextField,
            queue: queue)
        { notification in
            if let waypoint = self.waypointToEdit {
                waypoint.name = self.nameTextField.text
            }
        }
        itfObserver = center.addObserver(
            forName: NSNotification.Name.UITextFieldTextDidChange,
            object: infoTextField,
            queue: queue)
        { notification in
            if let waypoint = self.waypointToEdit {
                waypoint.info = self.infoTextField.text
            }
        }
    }
    
    //Elimina los observers que estan pendientes de los cambios en los textEdit
    fileprivate func stopListeningToTextFields() {
        if let observer = ntfObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = itfObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
