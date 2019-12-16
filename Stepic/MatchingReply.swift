//
//  MatchingReply.swift
//  Stepic
//
//  Created by Alexander Karpov on 16.01.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import SwiftyJSON
import UIKit

final class MatchingReply: Reply {
    var ordering: [Int]

    init(ordering: [Int]) {
        self.ordering = ordering
    }

    required init(json: JSON) {
        ordering = json["ordering"].arrayValue.map({ $0.intValue })
    }

    var dictValue: [String: Any] { ["ordering": ordering] }
}
