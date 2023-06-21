import Dependencies
import Photos
import PhotosUI

struct PhotosClient: DependencyKey {
  var requestAuthorization: @Sendable () async -> PHAuthorizationStatus
  var getAuthorizationStatus: @Sendable () -> PHAuthorizationStatus

  struct Failure: Equatable, Error {}
}

extension DependencyValues {
  var photos: PhotosClient {
    get { self[PhotosClient.self] }
    set { self[PhotosClient.self] = newValue }
  }
}

extension PhotosClient {
  static var liveValue = Self.live
//  static var previewValue = Self.preview
//  static var testValue = Self.test
}

extension PhotosClient {
  static var live: Self {
    return Self(
      requestAuthorization: {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      },
      getAuthorizationStatus: {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
      }
    )
  }
}

extension PHAuthorizationStatus: CustomStringConvertible {
  public var description: String {
    switch self {
    case .notDetermined:
      return "not-determined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .limited:
      return "limited"
    @unknown default:
      return "unkown"
    }
  }
}

