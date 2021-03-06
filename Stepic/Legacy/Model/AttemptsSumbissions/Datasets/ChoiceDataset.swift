import SwiftyJSON
import UIKit

final class ChoiceDataset: Dataset {
    var isMultipleChoice: Bool
    var options: [String]

    override var hash: Int {
        var result = self.isMultipleChoice.hashValue
        result = result &* 31 &+ self.options.hashValue
        return result
    }

    override var description: String {
        "ChoiceDataset(isMultipleChoice: \(self.isMultipleChoice), options: \(self.options))"
    }

    /* Example data:
     {
       "is_multiple_choice": false,
       "options": [
         "502",
         "5002",
         "520",
         "52"
       ]
     }
     */
    required init(json: JSON) {
        self.isMultipleChoice = json[JSONKey.isMultipleChoice.rawValue].boolValue
        self.options = json[JSONKey.options.rawValue].arrayValue.map { $0.stringValue }

        super.init(json: json)
    }

    required init?(coder: NSCoder) {
        guard let options = coder.decodeObject(forKey: JSONKey.options.rawValue) as? [String] else {
            return nil
        }

        self.isMultipleChoice = coder.decodeBool(forKey: JSONKey.isMultipleChoice.rawValue)
        self.options = options

        super.init(coder: coder)
    }

    private override init() {
        self.isMultipleChoice = false
        self.options = []

        super.init()
    }

    override func encode(with coder: NSCoder) {
        coder.encode(self.isMultipleChoice, forKey: JSONKey.isMultipleChoice.rawValue)
        coder.encode(self.options, forKey: JSONKey.options.rawValue)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ChoiceDataset else {
            return false
        }
        if self === object { return true }
        if type(of: self) != type(of: object) { return false }
        if self.isMultipleChoice != object.isMultipleChoice { return false }
        if self.options != object.options { return false }
        return true
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = ChoiceDataset()
        copy.isMultipleChoice = self.isMultipleChoice
        copy.options = self.options
        return copy
    }

    enum JSONKey: String {
        case isMultipleChoice = "is_multiple_choice"
        case options
    }
}
