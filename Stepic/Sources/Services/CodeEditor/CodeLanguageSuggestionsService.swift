import Foundation
import PromiseKit

protocol CodeLanguageSuggestionsServiceProtocol: AnyObject {
    func suggest(stepID: Step.IdType) -> Guarantee<CodeLanguage?>
    func update(language: CodeLanguage, stepID: Step.IdType) -> Promise<Void>
}

final class CodeLanguageSuggestionsService: CodeLanguageSuggestionsServiceProtocol {
    private let stepsPersistenceService: StepsPersistenceServiceProtocol

    init(stepsPersistenceService: StepsPersistenceServiceProtocol) {
        self.stepsPersistenceService = stepsPersistenceService
    }

    func suggest(stepID: Step.IdType) -> Guarantee<CodeLanguage?> {
        Guarantee { seal in
            self.stepsPersistenceService.fetch(ids: [stepID]).done { steps in
                guard let step = steps.first else {
                    return seal(nil)
                }

                guard let course = LastStepGlobalContext.context.course else {
                    return seal(self.getMostPopularLanguage(step: step))
                }

                if let lastCodeLanguage = course.lastCodeLanguage,
                   let language = lastCodeLanguage.language,
                   step.options?.languages.contains(language) ?? false {
                    seal(language)
                } else {
                    seal(self.getMostPopularLanguage(step: step))
                }
            }.catch { _ in
                seal(nil)
            }
        }
    }

    func update(language: CodeLanguage, stepID: Step.IdType) -> Promise<Void> {
        Promise { seal in
            guard let course = LastStepGlobalContext.context.course else {
                return seal.reject(Error.fetchFailed)
            }

            if course.lastCodeLanguage != nil {
                course.lastCodeLanguage?.languageString = language.rawValue
            } else {
                course.lastCodeLanguage = LastCodeLanguage(language: language)
            }

            CoreDataHelper.shared.save()

            seal.fulfill(())
        }
    }

    // MARK: - Private API

    private func getMostPopularLanguage(step: Step) -> CodeLanguage? {
        guard let options = step.options else {
            return nil
        }

        let ordering = Dictionary(
            uniqueKeysWithValues: CodeLanguage.priorityOrder.enumerated().map { ($1, $0) }
        )

        return options.languages.min { lhs, rhs -> Bool in
            if let first = ordering[lhs],
               let second = ordering[rhs] {
                return first < second
            }
            return false
        }
    }

    // MARK: - Inner Types

    enum Error: Swift.Error {
        case fetchFailed
    }
}
