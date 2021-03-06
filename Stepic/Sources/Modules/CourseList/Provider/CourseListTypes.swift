import Foundation

// MARK: - Course types

protocol CourseListType {
    // It's just a marker
    var analyticName: String { get }
}

struct PopularCourseListType: CourseListType {
    let language: ContentLanguage

    var analyticName: String { "popular_course_list" }
}

struct EnrolledCourseListType: CourseListType {
    var analyticName: String { "enrolled_course_list" }
}

struct FavoriteCourseListType: CourseListType {
    var analyticName: String { "favorite_course_list" }
}

struct ArchivedCourseListType: CourseListType {
    var analyticName: String { "archived_course_list" }
}

struct TagCourseListType: CourseListType {
    let id: Int
    let language: ContentLanguage

    var analyticName: String { "tag_course_list" }
}

struct CollectionCourseListType: CourseListType {
    let ids: [Course.IdType]

    var analyticName: String { "collection_course_list" }
}

struct SearchResultCourseListType: CourseListType {
    let query: String
    let filterQuery: CourseListFilterQuery?
    let language: ContentLanguage

    var analyticName: String { "search_result_course_list" }
}

struct TeacherCourseListType: CourseListType {
    let teacherID: User.IdType

    var analyticName: String { "teacher_course_list" }
}

struct VisitedCourseListType: CourseListType {
    var analyticName: String { "visited_course_list" }
}

struct DeepLinkCourseListType: CourseListType {
    let ids: [Course.IdType]

    var analyticName: String { "deep_link_course_list" }
}

// MARK: - Services factory

final class CourseListServicesFactory {
    let type: CourseListType
    private let coursesAPI: CoursesAPI
    private let userCoursesAPI: UserCoursesAPI
    private let searchResultsAPI: SearchResultsAPI
    private let visitedCoursesAPI: VisitedCoursesAPI

    init(
        type: CourseListType,
        coursesAPI: CoursesAPI = CoursesAPI(),
        userCoursesAPI: UserCoursesAPI = UserCoursesAPI(),
        searchResultsAPI: SearchResultsAPI = SearchResultsAPI(),
        visitedCoursesAPI: VisitedCoursesAPI = VisitedCoursesAPI()
    ) {
        self.type = type
        self.coursesAPI = coursesAPI
        self.userCoursesAPI = userCoursesAPI
        self.searchResultsAPI = searchResultsAPI
        self.visitedCoursesAPI = visitedCoursesAPI
    }

    func makePersistenceService() -> CourseListPersistenceServiceProtocol? {
        if self.type is EnrolledCourseListType {
            return CourseListPersistenceService(
                storage: DefaultsCourseListPersistenceStorage(
                    cacheID: "MyCoursesInfo"
                )
            )
        } else if self.type is FavoriteCourseListType {
            return CourseListPersistenceService(
                storage: DefaultsCourseListPersistenceStorage(
                    cacheID: "MyCoursesInfoFavorite"
                )
            )
        } else if self.type is ArchivedCourseListType {
            return CourseListPersistenceService(
                storage: DefaultsCourseListPersistenceStorage(
                    cacheID: "MyCoursesInfoArchived"
                )
            )
        } else if let type = self.type as? PopularCourseListType {
            return CourseListPersistenceService(
                storage: DefaultsCourseListPersistenceStorage(
                    cacheID: "PopularCoursesInfo_\(type.language.languageString)"
                )
            )
        } else if self.type is TagCourseListType {
            return nil
        } else if let type = self.type as? CollectionCourseListType {
            return CourseListPersistenceService(
                storage: PassiveCourseListPersistenceStorage(
                    cachedList: type.ids
                )
            )
        } else if self.type is SearchResultCourseListType {
            return nil
        } else if let type = self.type as? TeacherCourseListType {
            return CourseListPersistenceService(
                storage: CreatedCoursesCourseListPersistenceStorage(teacherID: type.teacherID)
            )
        } else if self.type is VisitedCourseListType {
            return VisitedCourseListPersistenceService(
                storage: DefaultsCourseListPersistenceStorage(cacheID: "VisitedCoursesInfo")
            )
        } else if let type = self.type as? DeepLinkCourseListType {
            return CourseListPersistenceService(
                storage: PassiveCourseListPersistenceStorage(
                    cachedList: type.ids
                )
            )
        } else {
            fatalError("Unsupported course list type")
        }
    }

    func makeNetworkService() -> CourseListNetworkServiceProtocol {
        if self.type is EnrolledCourseListType
               || self.type is FavoriteCourseListType
               || self.type is ArchivedCourseListType {
            return UserCoursesCourseListNetworkService(
                type: self.type,
                coursesAPI: self.coursesAPI,
                userCoursesAPI: self.userCoursesAPI
            )
        } else if let type = self.type as? PopularCourseListType {
            return PopularCourseListNetworkService(type: type, coursesAPI: self.coursesAPI)
        } else if let type = self.type as? TagCourseListType {
            return TagCourseListNetworkService(type: type, coursesAPI: self.coursesAPI)
        } else if let type = self.type as? CollectionCourseListType {
            return CollectionCourseListNetworkService(type: type, coursesAPI: self.coursesAPI)
        } else if let type = self.type as? SearchResultCourseListType {
            return SearchResultCourseListNetworkService(
                type: type,
                coursesAPI: self.coursesAPI,
                searchResultsAPI: self.searchResultsAPI
            )
        } else if let type = self.type as? TeacherCourseListType {
            return TeacherCourseListNetworkService(type: type, coursesAPI: self.coursesAPI)
        } else if let type = self.type as? VisitedCourseListType {
            return VisitedCourseListNetworkService(
                type: type,
                coursesAPI: self.coursesAPI,
                visitedCoursesAPI: self.visitedCoursesAPI
            )
        } else if let type = self.type as? DeepLinkCourseListType {
            return DeepLinkCourseListNetworkService(type: type, coursesAPI: self.coursesAPI)
        } else {
            fatalError("Unsupported course list type")
        }
    }
}
