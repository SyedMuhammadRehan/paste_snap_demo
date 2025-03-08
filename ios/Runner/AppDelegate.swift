import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let imageChannel = FlutterMethodChannel(name: "clipboard/image",
                                                binaryMessenger: controller.binaryMessenger)
        imageChannel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "getClipboardImage" {
                self?.getClipboardImage(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func getClipboardImage(result: FlutterResult) {
        if let image = UIPasteboard.general.image,
           let data = image.jpegData(compressionQuality: 0.9) {
            result(data)
        } else {
            result(nil)
        }
    }
}
