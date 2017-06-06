//
//  LiveViewController.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-16.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport
import PlaygroundBluetooth

@objc(LiveViewController)
public class LiveViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    @IBOutlet public var overlayView: UIView!
    @IBOutlet public var overlayContentView: UIView!
    
    let toyBox: ToyBox
    var toyBoxConnector: ToyBoxConnector?
    var connectedToy: SpheroV1Toy?
    
    let connectionHintArrowView = ConnectionHintArrowView()
    
    var aimingViewController: AimingViewController?
    var firmwareUpdateViewController: FirmwareUpdateViewController?
    
    private var topSafeAreaConstraint: NSLayoutConstraint?
    private var bottomSafeAreaConstraint: NSLayoutConstraint?
    
    fileprivate let passSound = Sound("Bell")
    fileprivate let failSounds: [Sound] = [
        Sound("No"),
        Sound("Sad"),
        Sound("Dizzy")
    ]
    
    public var toyBoxConnectorItems: [ToyBoxConnectorItem] {
        get {
            return [
                ToyBoxConnectorItem(prefix: SPRKToy.descriptor,
                                    defaultName: NSLocalizedString("toy.name.sprk", value: "SPRK+", comment: "SPRK+ robot"),
                                    icon: UIImage(named: "connection-sphero")!)
            ]
        }
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.toyBox = ToyBox()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.toyBox = ToyBox()
        super.init(coder: aDecoder)
    }
    
    public var shouldPresentAim: Bool {
        return true
    }
    
    public var shouldAutomaticallyConnectToToy = true
    
    var isLiveViewMessageConnectionOpened = false
    var toyConnectionView: PlaygroundBluetoothConnectionView?
    
    public override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            toyConnectionView?.removeFromSuperview()
            
            if let connectedToy = connectedToy {
                toyBox.putAway(toy: connectedToy)
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        toyBox.addListener(self)
        
        PlaygroundPage.current.needsIndefiniteExecution = true
        
        // Add the connection view.
        if shouldAutomaticallyConnectToToy {
            connectToNearest()
        }
        
        // Set up the constraints for the overlay view.
        if let overlayView = overlayView {
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0),
                overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0),
                ])
        }
        
        // Set up the constraints for the overlay content view.
        if let overlayContentView = overlayContentView {
            let liveAreaSafeFrame = liveViewSafeAreaGuide.layoutFrame
            let topConstraint = overlayContentView.topAnchor.constraint(equalTo: view.topAnchor, constant: liveAreaSafeFrame.minY)
            let bottomConstraint = overlayContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(view.bounds.size.height - liveAreaSafeFrame.maxY))
            
            NSLayoutConstraint.activate([
                bottomConstraint,
                topConstraint
                ])
            
            topSafeAreaConstraint = topConstraint
            bottomSafeAreaConstraint = bottomConstraint
        }
        
        if let toyConnectionView = toyConnectionView {
            view.insertSubview(connectionHintArrowView, belowSubview: toyConnectionView)
            connectionHintArrowView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                connectionHintArrowView.trailingAnchor.constraint(equalTo: toyConnectionView.leadingAnchor),
                connectionHintArrowView.topAnchor.constraint(equalTo: toyConnectionView.topAnchor)
            ])
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        aimingViewController?.safeAreaLayoutGuide = liveViewSafeAreaGuide
        firmwareUpdateViewController?.safeAreaLayoutGuide = liveViewSafeAreaGuide
        
        updateViewConstraints()
        view.setNeedsUpdateConstraints()
    }
    
    public override func updateViewConstraints() {
        if let topSafeConstraint = topSafeAreaConstraint, let bottomSafeConstraint = bottomSafeAreaConstraint {
            let liveAreaSafeFrame = liveViewSafeAreaGuide.layoutFrame
            topSafeConstraint.constant = liveAreaSafeFrame.minY == 0.0 ? 40.0 : liveAreaSafeFrame.minY
            bottomSafeConstraint.constant = -(view.bounds.size.height - liveAreaSafeFrame.maxY)
            
            view.setNeedsUpdateConstraints()
        }
        
        overlayView?.isHidden = isVeryCompact()
        
        super.updateViewConstraints()
    }
    
    @objc private func didEnterBackground() {
        guard let connectedToy = connectedToy else { return }
        toyBox.putAway(toy: connectedToy)
    }
    
    @objc private func willEnterForeground() {
        hideModalViewControllers()
    }
    
    private func heightScaleFactor() -> CGFloat {
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.size.height
        let currentWidth = liveViewSafeAreaGuide.layoutFrame.size.width
        
        let originalHeight: CGFloat
        if currentHeight > currentWidth {
            originalHeight = 1366.0
        } else {
            originalHeight = 1024.0
        }
        
        return currentHeight / originalHeight
    }
    
    private func widthScaleFactor() -> CGFloat {
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.size.height
        let currentWidth = liveViewSafeAreaGuide.layoutFrame.size.width
        
        let originalWidth: CGFloat
        if currentHeight > currentWidth {
            originalWidth = 1024.0
        } else {
            originalWidth = 1366.0
        }
        
        return currentWidth / originalWidth
    }
    
    public func isVeryCompact() -> Bool {
        return heightScaleFactor() < 0.45 && widthScaleFactor() < 0.45
    }
    
    public func isVerticallyCompact() -> Bool {
        return (view.bounds.size.height < 600.0)
    }
    
    public func isHorizontallyCompact() -> Bool {
        return (view.bounds.size.width < 600.0)
    }
    
    func connectToNearest() {
        if toyConnectionView == nil {
            toyBoxConnector = ToyBoxConnector(items: toyBoxConnectorItems)
            
            toyConnectionView = PlaygroundBluetoothConnectionView(centralManager: toyBox.centralManager, delegate: toyBoxConnector, dataSource: toyBoxConnector)
            view.addSubview(toyConnectionView!)
            
            NSLayoutConstraint.activate([
                toyConnectionView!.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 20),
                toyConnectionView!.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -20)
                ])
        }
    }
    
    func playAssessmentSound(playPassSound didPass: Bool) {
        if didPass {
            passSound.play()
        } else {
            let soundIndex = Int(arc4random_uniform(UInt32(failSounds.count)))
            failSounds[soundIndex].play()
        }
    }
    
    func addModalViewController(_ viewController: ModalViewController, callback: @escaping (Bool) -> Void) {
        viewController.safeAreaLayoutGuide = liveViewSafeAreaGuide
        if let toyConnectionView = toyConnectionView {
            view.insertSubview(viewController.view, belowSubview: toyConnectionView)
        } else {
            view.addSubview(viewController.view)
        }
        viewController.didMove(toParentViewController: self)

        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0),
            ])

        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, viewController.view)

        viewController.animateIn(callback: callback)
    }
    
    func removeModalViewController(_ viewController: ModalViewController, callback: @escaping (Bool) -> Void) {
        viewController.animateOut { (completed) in
            viewController.willMove(toParentViewController: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
            
            callback(completed)
        }
    }
    
    // TODO: refactor
    open func didReceiveRollMessage(heading: Double, speed: Double) { }
    open func didReceiveSetMainLedMessage(color: UIColor) { }
    open func didReceiveSetBackLedMesssage(brightness: Double) { }
    open func didReceiveSetStabilizationMesssage(state: SetStabilization.State) { }
    open func didReceiveEnableSensorsMessage(sensors: SensorMask) { }
    open func didReceiveSetCollisionDetectionMesssage(configuration: ConfigureCollisionDetection.Configuration) { }
    open func didReceiveCollision(data: CollisionData) { }
    open func didReceiveSensorData(_ data: SensorData) { }
    
    func onReceive(message: PlaygroundValue) { }
    
}

extension LiveViewController: ToyBoxListener {
    
    public func toyBoxReady(_ toyBox: ToyBox) {
        if shouldAutomaticallyConnectToToy {
            toyBox.connectToLastConnectedPeripheral()
        }
    }
    
    public func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) {
    }

    public func toyBox(_ toyBox: ToyBox, willReady descriptor: ToyDescriptor) {
        connectionHintArrowView.hide()
    }
    
    public func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
        guard let toy = toy as? SpheroV1Toy else { return }
        connectedToy = toy
        
        connectionHintArrowView.hide()

        if requiresFirmwareUpdate(for: toy) {
            toyConnectionView?.setFirmwareStatus(.outOfDate, forPeripheral: toy.peripheral)
            showFirmwareUpdateViewController()
            return
        }
        
        if let batteryLevel = connectedToy?.batteryLevel {
            toyConnectionView?.setBatteryLevel(batteryLevel, forPeripheral: toy.peripheral)
        }
        
        toy.setToyOptions([])
        toy.onCollisionDetected = { [weak self] data in
            self?.sendCollisionMessage(data: data)
            self?.didReceiveCollision(data: data)
        }
        toy.sensorControl.onDataReady = { [weak self] data in
            self?.sendSensorDataMessage(data: data)
            self?.didReceiveSensorData(data)
        }
        
        if isLiveViewMessageConnectionOpened {
            if shouldPresentAim {
                showAimingController()
            } else {
                sendToyReadyMessage()
            }
        }
    }

    public func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
        guard toy === connectedToy else { return }
        
        connectedToy = nil

        hideModalViewControllers()
    }
    
    func requiresFirmwareUpdate(for toy: Toy?) -> Bool {
        guard let toy = toy else { return false }
        guard let appVersion = toy.appVersion else { return false }
        switch toy {
        case is SPRKToy:
            return appVersion < AppVersion(major: "7", minor: "21")
        case is BB8Toy:
            return appVersion < AppVersion(major: "4", minor: "69")
        default:
            return false
        }
    }
    
    func showAimingController() {
        guard !requiresFirmwareUpdate(for: connectedToy) else { return }
        guard aimingViewController == nil else { return }
        
        connectedToy?.setMainLed(color: .black)
        connectedToy?.setStabilization(state: .off)
        connectedToy?.startAiming()
        
        aimingViewController = AimingViewController.instantiate(with: connectedToy, callback: { [weak self] aimingViewController in
            if let connectedToy = self?.connectedToy {
                connectedToy.stopAiming()
                connectedToy.setStabilization(state: .on)
                connectedToy.setMainLed(color: .blue)
                connectedToy.configureLocator(newX: 0, newY: 0, newYaw: 0)
            }
            if let aimingViewController = self?.aimingViewController {
                aimingViewController.animateOut { _ in
                    self?.removeModalViewController(aimingViewController) { (_) in
                        self?.sendToyReadyMessage()
                    }
                }
            }
        })
        
        addModalViewController(aimingViewController!) { (_) in
        }
    }
    
    func showFirmwareUpdateViewController() {
        guard firmwareUpdateViewController == nil else { return }
        
        firmwareUpdateViewController = FirmwareUpdateViewController.instantiate(with: connectedToy)
        addModalViewController(firmwareUpdateViewController!) { (_) in
        }
    }
    
    func hideModalViewControllers() {
        if let aimingViewController = aimingViewController {
            removeModalViewController(aimingViewController) { (_) in
                self.aimingViewController = nil
            }
        }
        if let firmwareUpdateViewController = firmwareUpdateViewController {
            removeModalViewController(firmwareUpdateViewController) { (_) in
                self.firmwareUpdateViewController = nil
            }
        }
    }
    
}
