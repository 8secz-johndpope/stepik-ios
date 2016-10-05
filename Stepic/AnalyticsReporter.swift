//
//  AnalyticsReporter.swift
//  Stepic
//
//  Created by Alexander Karpov on 18.08.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation
import Firebase

class AnalyticsReporter {
    static func reportEvent(_ event: String, parameters: [String: NSObject]?) {
        FIRAnalytics.logEvent(withName: event, parameters: parameters)
    }
}
