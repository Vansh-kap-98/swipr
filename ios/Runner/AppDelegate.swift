import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeAppDataFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Swipr's database (sqflite stores it in Documents) stays on this device:
  /// keep it out of iCloud and computer backups.
  private func excludeAppDataFromBackup() {
    guard var documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return
    }
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? documents.setResourceValues(values)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
