//
//  CoreDataManager.swift
//  NoPassSDK
//
//  Created by Vlad Krupnik on 26.07.2020.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation
import CoreData


class CoreDataManager {
    
    public static let shared = CoreDataManager()
    
    let identifier: String  = "psa.nopass.framework.NoPassSDK"       //Framework bundle ID
    let model: String       = "NoPass"                      //Model name
    
    
    public var onAccountsChange:   (() -> ())?
    
    var persistentContainer: NSPersistentContainer
    
    public init() {
        let messageKitBundle = Bundle(identifier: self.identifier)
        let modelURL = messageKitBundle!.url(forResource: self.model, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)
        
        
        let container = NSPersistentContainer(name: self.model, managedObjectModel: managedObjectModel!)
        container.loadPersistentStores { (storeDescription, error) in
            
            if let err = error{
                logMessage("❌ Loading of store failed:\(err)")
            }
        }
        
        persistentContainer = container
        subscribe()
    }
    
    func subscribe() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contextWillSave(_:)), name: Notification.Name.NSManagedObjectContextWillSave, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(contextDidSave(_:)), name: Notification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    
    @objc func contextObjectsDidChange(_ notification: Notification) {
        logMessage(notification.debugDescription)
    }

    @objc func contextWillSave(_ notification: Notification) {
        logMessage(notification.debugDescription)
    }

    @objc func contextDidSave(_ notification: Notification) {
        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
            print(insertedObjects)
        }

        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
            print(updatedObjects)
        }

        if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
            print(deletedObjects)
        }

        if let refreshedObjects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>, !refreshedObjects.isEmpty {
            print(refreshedObjects)
        }

        if let invalidatedObjects = notification.userInfo?[NSInvalidatedObjectsKey] as? Set<NSManagedObject>, !invalidatedObjects.isEmpty {
            print(invalidatedObjects)
        }

        if let areInvalidatedAllObjects = notification.userInfo?[NSInvalidatedAllObjectsKey] as? Bool {
            print(areInvalidatedAllObjects)
        }
        
        self.onAccountsChange?()
    }
    
    func createAccount(userCode: String, userName: String, portalId: String, portalName: String, userseed: String, portalUrl: String, serverUrl: String, alias: String, createdDate: Date, hex: String){
        
        let context = persistentContainer.viewContext
        let account = NSEntityDescription.insertNewObject(forEntityName: "Account", into: context) as! Account
        
        account.userCode = userCode
        account.userName  = userName
        account.portalId = portalId
        account.portalName = portalName
        
        account.userseed = userseed
        account.portalUrl = portalUrl
        account.serverUrl = serverUrl
        account.alias = alias
        account.createdDate = createdDate
        account.hex = hex
        
        do {
            try context.save()
            logMessage("✅ Account saved succesfuly")
            
        } catch let error {
            logMessage("❌ Failed to create Account: \(error.localizedDescription)")
        }
    }
    
    func getAccount(userCode: String) -> Account? {
        return getAccounts().first(where: {$0.userCode == userCode})
    }
    
    func getAccount(userCode: String, portalId: String) -> Account? {
        return getAccounts().first(where: { $0.userCode == userCode && $0.portalId == portalId })
    }
    
    func getAccount(userName: String, portalId: String) -> Account? {
        return getAccounts().first(where: { $0.userName == userName && $0.portalId == portalId })
    }
    
    func getAccounts() -> [Account] {
        let context = persistentContainer.viewContext
        
        do{
            let fetchRequest = NSFetchRequest<Account>(entityName: "Account")
            
            let account = try context.fetch(fetchRequest)
            
            return account
            
        }catch let fetchErr {
            logMessage("❌ Failed to fetch Account: \(fetchErr.localizedDescription)")
            return []
        }
        
    }
    
    
    func removeAccount(account: Account)  {
        let context = persistentContainer.viewContext
        
        context.delete(account)
        
        do {
            try context.save()
        } catch {
            logMessage("❌ Failed to remove Account")
        }
    }
    
    
    
    func update(userCode: String, name:String) {
        let context = persistentContainer.viewContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Account")
        let predicate = NSPredicate(format: "userCode = '\(userCode)'")
        fetchRequest.predicate = predicate
        do
        {
            let object = try context.fetch(fetchRequest)
            if object.count == 1
            {
                if let objectUpdate = object.first as? NSManagedObject {
                    objectUpdate.setValue(name, forKey: "userName")
                    do{
                        logMessage("✅ Account update succesfuly")
                        try context.save()
                    }
                    catch {
                        logMessage("❌ Failed to update Account")
                    }
                }
                
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func update(userCode: String, isAccountBackup:Bool) {
        let context = persistentContainer.viewContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Account")
        let predicate = NSPredicate(format: "userCode = '\(userCode)'")
        fetchRequest.predicate = predicate
        do
        {
            let object = try context.fetch(fetchRequest)
            if object.count == 1
            {
                if let objectUpdate = object.first as? NSManagedObject {
                    objectUpdate.setValue(isAccountBackup, forKey: "isAccountBackup")
                    do{
                        logMessage("✅ Account update succesfuly")
                        try context.save()
                    }
                    catch {
                        logMessage("❌ Failed to update Account")
                    }
                }                
            }
        }
        catch
        {
            print(error)
        }
    }
}


extension CoreDataManager {
    func createAuthHistory(userCode: String, userName: String, portalUrl: String, authDate: Date, hex: String, isSuccesAuth: Bool){
        
        let context = persistentContainer.viewContext
        let history = NSEntityDescription.insertNewObject(forEntityName: "AuthHistory", into: context) as! AuthHistory
        
        history.userCode = userCode
        history.userName  = userName
        history.portalUrl = portalUrl
        
        
        history.portalUrl = portalUrl
        history.isSuccesAuth = isSuccesAuth
        history.authDate = authDate
        history.hex = hex
                
        do {
            try context.save()
            logMessage("✅ History saved succesfuly")
            
        } catch let error {
            logMessage("❌ Failed to create History: \(error.localizedDescription)")
        }
    }
    
    
    func getHistory() -> [AuthHistory] {
        let context = persistentContainer.viewContext
        
        do{
            let fetchRequest = NSFetchRequest<AuthHistory>(entityName: "AuthHistory")
            
            let history = try context.fetch(fetchRequest)
            
            return history
            
        }catch let fetchErr {
            logMessage("❌ Failed to fetch History: \(fetchErr.localizedDescription)")
            return []
        }
        
    }
}

extension Account {
    var serverName: String {
        return (serverUrl ?? "").replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "")
    }
}
