import Flutter
import UIKit
import GoogleMaps // <-- 1. IMPORT THE GOOGLE MAPS SERVICE

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 2. PROVIDE THE API KEY
    GMSServices.provideAPIKey("AIzaSyCjnbZCaxorKVAjeHaW_Yn4VZ3H_KInN74")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}