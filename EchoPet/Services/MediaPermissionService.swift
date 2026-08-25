import AVFoundation
import Foundation
import Photos

enum MediaPermissionKind: String, CaseIterable, Identifiable {
    case photoLibrary
    case camera
    case microphone

    var id: String {
        rawValue
    }

    var systemName: String {
        switch self {
        case .photoLibrary:
            return "photo.on.rectangle"
        case .camera:
            return "camera.fill"
        case .microphone:
            return "mic.fill"
        }
    }
}

enum MediaPermissionState: String, Equatable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
    case unavailable

}

@MainActor
final class MediaPermissionService: ObservableObject {
    @Published private(set) var statuses: [MediaPermissionKind: MediaPermissionState] = [:]

    init() {
        refresh()
    }

    func refresh() {
        statuses = Dictionary(
            uniqueKeysWithValues: MediaPermissionKind.allCases.map { kind in
                (kind, currentStatus(for: kind))
            }
        )
    }

    func request(_ kind: MediaPermissionKind) async {
        switch kind {
        case .photoLibrary:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            statuses[kind] = mapPhotoStatus(status)
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            statuses[kind] = granted ? .authorized : currentStatus(for: .camera)
        case .microphone:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            statuses[kind] = granted ? .authorized : currentStatus(for: .microphone)
        }
    }

    func status(for kind: MediaPermissionKind) -> MediaPermissionState {
        statuses[kind] ?? currentStatus(for: kind)
    }

    private func currentStatus(for kind: MediaPermissionKind) -> MediaPermissionState {
        switch kind {
        case .photoLibrary:
            return mapPhotoStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        case .camera:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        }
    }

    private func mapPhotoStatus(_ status: PHAuthorizationStatus) -> MediaPermissionState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }
    }

    private func mapAVStatus(_ status: AVAuthorizationStatus) -> MediaPermissionState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unavailable
        }
    }
}
