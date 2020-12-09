import UIKit
import Flutter

enum ChannelName {
    static let interstitial = "ironsource.tombolapp.net/interstitial";
    static let interstitialEvents = "ironsource.tombolapp.net/interstitialEvents"
    static let rewardedVideo = "ironsource.tombolapp.net/rewardedVideo";
    static let rewardedVideoEvents = "ironsource.tombolapp.net/rewardedVideoEvents"
}

enum InterstitialState {
    static let loaded = "loaded"
    static let opened = "opened"
    static let closed = "closed"
    static let shown = "shown"
    static let clicked = "clicked"
    static let loadError = "loadedError"
    static let showError = "showError"
}

enum RewardedVideoState {
    static let availabilityChanged = "availabilityChanged"
    static let rewardReceived = "rewardReceived"
    static let showError = "showError"
    static let opened = "opened"
    static let closed = "closed"
    static let started = "started"
    static let ended = "ended"
    static let clicked = "clicked"
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var interstitialEventSynk: FlutterEventSink?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        IronSource.initWithAppKey("e210f449", adUnits:[IS_REWARDED_VIDEO,IS_INTERSTITIAL,IS_OFFERWALL, IS_BANNER]);
        ISIntegrationHelper.validateIntegration()
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let interstitialChannel = FlutterMethodChannel(name: ChannelName.interstitial,
                                                       binaryMessenger: controller.binaryMessenger)
        interstitialChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            // Note: this method is invoked on the UI thread.
            switch call.method {
            case "loadInterstitial":
                self?.loadInterstitial(result: result)
                break;
            case "showInterstitial":
                self?.showInterstitial(result: result)
                break;
            default:
                result(FlutterMethodNotImplemented)
                break;
            }
        })
        let interstitialEventsChannel = FlutterEventChannel(name: ChannelName.interstitialEvents, binaryMessenger: controller.binaryMessenger)
        interstitialEventsChannel.setStreamHandler(InterstitalStreamHandler())
        let rewardedVideoChannel = FlutterMethodChannel(name: ChannelName.rewardedVideo, binaryMessenger: controller.binaryMessenger)
        rewardedVideoChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            // Note: this method is invoked on the UI thread.
            switch call.method {
            case "showRewardedVideo":
                self?.showRewardedVideo(result: result)
                break;
            default:
                result(FlutterMethodNotImplemented)
                break;
            }
        })
        let rewardedVideoEventsChannel = FlutterEventChannel(name: ChannelName.rewardedVideoEvents, binaryMessenger: controller.binaryMessenger)
        rewardedVideoEventsChannel.setStreamHandler(RewardedVideoStreamHandler())
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    private func loadInterstitial(result: FlutterResult) {
        IronSource.loadInterstitial();
        result(nil)
        //      let device = UIDevice.current
        //         result(FlutterError(code: "UNAVAILABLE",
        //                            message: "Battery info unavailable",
        //                            details: nil))
        //      } else {
        //        result(Int(device.batteryLevel * 100))
        //      }
    }
    
    private func showInterstitial(result: FlutterResult) {
        IronSource.showInterstitial(with: window?.rootViewController as! FlutterViewController)
        result(nil)
    }
    
    private func showRewardedVideo(result: FlutterResult) {
        IronSource.showRewardedVideo(with: window?.rootViewController as! FlutterViewController)
        result(nil)
    }
}

class InterstitalStreamHandler: NSObject, FlutterStreamHandler, ISInterstitialDelegate {
    private var eventSynk: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        IronSource.setInterstitialDelegate(self)
        self.eventSynk = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSynk = nil
        return nil
    }
    
    func interstitialDidLoad() {
        NSLog("interstitialDidLoad")
        sendInterstitialEvent(InterstitialState.loaded)
    }
    
    func interstitialDidFailToLoadWithError(_ error: Error!) {
        NSLog("interstitialDidFailToLoadWithError")
        sendInterstitialEvent(InterstitialState.loadError)
    }
    
    func interstitialDidOpen() {
        NSLog("interstitialDidOpen")
        sendInterstitialEvent(InterstitialState.opened)
    }
    
    func interstitialDidClose() {
        sendInterstitialEvent(InterstitialState.closed)
    }
    
    func interstitialDidShow() {
        sendInterstitialEvent(InterstitialState.shown)
    }
    
    func interstitialDidFailToShowWithError(_ error: Error!) {
        sendInterstitialEvent(InterstitialState.showError)
    }
    
    func didClickInterstitial() {
        sendInterstitialEvent(InterstitialState.clicked)
    }
    
    private func sendInterstitialEvent(_ state: String) {
        guard let eventSink = eventSynk else {
            return
        }
        eventSink(state)
    }
}

class RewardedVideoStreamHandler: NSObject, FlutterStreamHandler, ISRewardedVideoDelegate {
    private var eventSynk: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        IronSource.setRewardedVideoDelegate(self)
        self.eventSynk = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSynk = nil
        return nil
    }
    
    
    func rewardedVideoHasChangedAvailability(_ available: Bool) {
        sendRewardedVideoEvent(RewardedVideoState.availabilityChanged)
    }
    
    func didReceiveReward(forPlacement placementInfo: ISPlacementInfo!) {
        sendRewardedVideoEvent(RewardedVideoState.rewardReceived)
    }
    
    func rewardedVideoDidFailToShowWithError(_ error: Error!) {
        sendRewardedVideoEvent(RewardedVideoState.showError)
    }
    
    func rewardedVideoDidOpen() {
        sendRewardedVideoEvent(RewardedVideoState.opened)
    }
    
    func rewardedVideoDidClose() {
        sendRewardedVideoEvent(RewardedVideoState.closed)
    }
    
    func rewardedVideoDidStart() {
        sendRewardedVideoEvent(RewardedVideoState.started)
    }
    
    func rewardedVideoDidEnd() {
        sendRewardedVideoEvent(RewardedVideoState.ended)
    }
    
    func didClickRewardedVideo(_ placementInfo: ISPlacementInfo!) {
        sendRewardedVideoEvent(RewardedVideoState.clicked)
    }
    
    private func sendRewardedVideoEvent(_ state: String) {
        guard let eventSink = eventSynk else {
            return
        }
        eventSink(state)
    }
    
}
