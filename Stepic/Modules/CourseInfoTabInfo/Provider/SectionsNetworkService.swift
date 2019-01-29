//
//  SectionsNetworkService.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 13/12/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

protocol SectionsNetworkServiceProtocol: class {
    func fetch(ids: [Section.IdType]) -> Promise<[Section]>
}

final class SectionsNetworkService: SectionsNetworkServiceProtocol {
    private let sectionsAPI: SectionsAPI

    init(sectionsAPI: SectionsAPI) {
        self.sectionsAPI = sectionsAPI
    }

    func fetch(ids: [Section.IdType]) -> Promise<[Section]> {
        return Promise { seal in
            self.sectionsAPI.retrieve(ids: ids).done { sections in
                let sections = sections.reordered(order: ids, transform: { $0.id })
                seal.fulfill(sections)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}
