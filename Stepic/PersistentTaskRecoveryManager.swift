//
//  PersistentTaskRecoveryManager.swift
//  Stepic
//
//  Created by Alexander Karpov on 06.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

/*
 Strategy class for recovering the correct task from store
 */
class PersistentTaskRecoveryManager : PersistentRecoveryManager {
    override func recoverObjectFromDictionary(dictionary: [String : AnyObject]) -> DictionarySerializable? {
        let typeStringOrNil = dictionary["type"] as? String
        if let type = ExecutableTaskType(rawValue: typeStringOrNil ?? "") {
            
            switch type {
            case .DeleteDevice: 
                return  DeleteDeviceExecutableTask(dictionary: dictionary)
            }
            
        } else {
            return nil
        }
    }
    
    func recoverTask(name name: String) -> Executable? {
        return recoverObjectWithKey(name) as? Executable
    }
    
    func writeTask(task: protocol<Executable, DictionarySerializable>, name: String) {
        return writeObjectWithKey(name, object: task)
    }
}