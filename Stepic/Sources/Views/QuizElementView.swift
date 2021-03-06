import SnapKit
import UIKit

extension QuizElementView {
    struct Appearance {
        let cornerRadius: CGFloat = 6
        let borderWidth: CGFloat = 1
    }
}

final class QuizElementView: UIView {
    let appearance: Appearance

    private lazy var borderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.lineWidth = self.appearance.borderWidth
        borderLayer.fillColor = UIColor.clear.cgColor
        return borderLayer
    }()

    var state = State.default {
        didSet {
            self.updateState()
        }
    }

    /// Disable rounded corners on bottom
    var useCornersOnlyOnTop = false {
        didSet {
            self.updateState()
        }
    }

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        DispatchQueue.main.async {
            self.updateState()
        }
    }

    private func updateState() {
        self.backgroundColor = self.state.backgroundColor
        self.borderLayer.strokeColor = self.state.borderColor.cgColor
        self.updateCorners()
    }

    private func updateCorners() {
        let path = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: self.useCornersOnlyOnTop ? [.topLeft, .topRight] : .allCorners,
            cornerRadii: CGSize(width: self.appearance.cornerRadius, height: self.appearance.cornerRadius)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask

        let borderPath = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: self.useCornersOnlyOnTop ? [.topLeft, .topRight] : .allCorners,
            cornerRadii: CGSize(width: self.appearance.cornerRadius, height: self.appearance.cornerRadius)
        )
        self.borderLayer.path = borderPath.cgPath
        self.borderLayer.frame = self.bounds
    }

    enum State {
        case `default`
        case correct
        case wrong
        case selected

        var borderColor: UIColor {
            switch self {
            case .default:
                return .quizElementDefaultBorder
            case .correct:
                return .quizElementCorrectBorder
            case .wrong:
                return .quizElementWrongBorder
            case .selected:
                return .quizElementSelectedBorder
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .default:
                return .quizElementDefaultBackground
            case .correct:
                return .quizElementCorrectBackground
            case .wrong:
                return .quizElementWrongBackground
            case .selected:
                return .quizElementSelectedBackground
            }
        }
    }
}

extension QuizElementView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.layer.addSublayer(self.borderLayer)

        self.updateState()
    }
}
