import SwiftUI

@main
struct PhotoPickerApp: App {
  var body: some Scene {
    WindowGroup {
      AppView(store: .init(
        initialState: .init(),
        reducer: AppReducer.init
      ))
    }
  }
}
