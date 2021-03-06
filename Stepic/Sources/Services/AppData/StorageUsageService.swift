import Foundation

protocol StorageUsageServiceProtocol: AnyObject {
    typealias Bytes = UInt64

    /// Returns video stored file in bytes, otherwise returns nil if file not found.
    func getVideoFileSize(videoID: Video.IdType) -> Bytes?
    func getStepSize(step: Step) -> Bytes
    func getLessonSize(lesson: Lesson) -> Bytes
    func getUnitSize(unit: Unit) -> Bytes
    func getSectionSize(section: Section) -> Bytes
    func getCourseSize(course: Course) -> Bytes
}

extension StorageUsageServiceProtocol {
    func getLessonSize(lesson: Lesson) -> Bytes {
        lesson.steps.reduce(0) { $0 + self.getStepSize(step: $1) }
    }

    func getUnitSize(unit: Unit) -> Bytes {
        if let lesson = unit.lesson {
            return self.getLessonSize(lesson: lesson)
        }
        return 0
    }

    func getSectionSize(section: Section) -> Bytes {
        section.units.reduce(0) { $0 + self.getUnitSize(unit: $1) }
    }

    func getCourseSize(course: Course) -> Bytes {
        course.sections.reduce(0) { $0 + self.getSectionSize(section: $1) }
    }
}

final class StorageUsageService: StorageUsageServiceProtocol {
    private let videoFileManager: VideoStoredFileManagerProtocol
    private let imageFileManager: ImageStoredFileManagerProtocol

    init(
        videoFileManager: VideoStoredFileManagerProtocol,
        imageFileManager: ImageStoredFileManagerProtocol
    ) {
        self.videoFileManager = videoFileManager
        self.imageFileManager = imageFileManager
    }

    // MARK: Protocol Conforming

    func getVideoFileSize(videoID: Video.IdType) -> Bytes? {
        self.videoFileManager.getVideoStoredFile(videoID: videoID)?.size
    }

    func getStepSize(step: Step) -> Bytes {
        if step.block.type == .video, let videoID = step.block.video?.id {
            return self.getVideoFileSize(videoID: videoID) ?? 0
        } else {
            let cachedImagesSize = step.block.imageSourceURLs
                .compactMap { self.imageFileManager.getImageStoredFile(imageURL: $0) }
                .map { $0.size }
                .reduce(0, +)

            let textSize = UInt64((step.block.text ?? "").utf8.count)

            return textSize + cachedImagesSize
        }
    }
}
