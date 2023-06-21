import SwiftUI
import PhotosUI
import Photos
import ComposableArchitecture

struct AppReducer: ReducerProtocol {
  struct State: Equatable {
    var status: PHAuthorizationStatus = .notDetermined
    var item: PhotosPickerItem?
    var data: Data?
  }
  
  enum Action: Equatable {
    case task
    case getPermissions
    case setPermissions(PHAuthorizationStatus)
    case openSettings
    case setItem(PhotosPickerItem?)
    case decodeImage(TaskResult<Data?>)
  }
  
  @Dependency(\.photos) var photos
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .task:
        state.status = photos.getAuthorizationStatus()
        return .none
        
      case .getPermissions:
        return .run { send in
          let status = await photos.requestAuthorization()
          await send(.setPermissions(status))
        }
      
      case let .setPermissions(value):
        state.status = value
        return .none
      
      case .openSettings:
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        return .none
        
      case let .setItem(value):
        guard let value else { return .none }
        return .task {
          await .decodeImage(TaskResult {
            try await value.loadTransferable(type: Data.self)
          })
        }
      
      case let .decodeImage(.success(value)):
        state.data = value
        return .none
        
      case .decodeImage(.failure(_)):
        return .none
      }
    }
  }
}

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        List {
          Button("Request Photo Permissions \(viewStore.status.description)") {
            viewStore.send(.getPermissions)
          }
          Button("Settings") {
            viewStore.send(.openSettings)
          }
          PhotosPicker(
            selection: viewStore.binding(
              get: \.item,
              send: { .setItem($0) }
            ),
            matching: .images,
            preferredItemEncoding: .automatic,
            photoLibrary: .shared()
          ) {
            Text("Pick Image")
          }
          
          if let data = viewStore.data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
              .resizable()
              .frame(width: 300, height: 300)
          }
        }
        .task { await viewStore.send(.task).finish() }
        .navigationTitle("PhotoPicker")
      }
    }
  }
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(store: .init(
      initialState: .init(),
      reducer: AppReducer.init
    ))
  }
}
