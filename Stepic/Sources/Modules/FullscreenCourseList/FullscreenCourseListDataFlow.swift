import Foundation

enum FullscreenCourseList {
    // MARK: Use cases

    /// Present course syllabus
    enum CourseSyllabusPresentation {
        struct Response {
            let course: Course
            let courseViewSource: AnalyticsEvent.CourseViewSource
        }

        struct ViewModel {
            let courseID: Course.IdType
            let courseViewSource: AnalyticsEvent.CourseViewSource
        }
    }

    /// Present course info
    enum CourseInfoPresentation {
        struct Response {
            let course: Course
            let courseViewSource: AnalyticsEvent.CourseViewSource
        }

        struct ViewModel {
            let courseID: Course.IdType
            let courseViewSource: AnalyticsEvent.CourseViewSource
        }
    }

    /// Present last step in course
    enum LastStepPresentation {
        struct Response {
            let course: Course
            let isAdaptive: Bool
            let courseViewSource: AnalyticsEvent.CourseViewSource
        }

        struct ViewModel {
            @available(*, deprecated, message: "Target modules can't be initialized w/o model")
            let course: Course
            @available(*, deprecated, message: "Target modules can't be initialized w/o model")
            let isAdaptive: Bool
            let courseViewSource: AnalyticsEvent.CourseViewSource
        }
    }

    /// Present web view for paid course
    enum PaidCourseBuyingPresentation {
        struct Response {
            let course: Course
        }

        struct ViewModel {
            let urlPath: String
        }
    }

    /// Try to set online status
    enum OnlineModeReset {
        struct Request {
            let module: CourseListInputProtocol
        }
    }

    enum PresentAuthorization {
        struct Response {}

        struct ViewModel {}
    }

    enum PresentPlaceholder {
        enum PlaceholderState {
            case error
            case empty
        }

        struct Response {
            let state: PlaceholderState
        }

        struct ViewModel {
            let state: PlaceholderState
        }
    }

    enum HidePlaceholder {
        struct Response {}

        struct ViewModel {}
    }
}
