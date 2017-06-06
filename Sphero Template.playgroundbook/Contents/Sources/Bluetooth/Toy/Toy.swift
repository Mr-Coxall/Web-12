//
//  Toy.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-08.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol ToyCoreAsyncListener: class {
    func toyCore(_ toyCore: Toy.ToyCore, didReceiveAsyncResponse response: AsyncCommandResponse)
    func toyCore(_ toyCore: Toy.ToyCore, didReceiveDeviceResponse response: DeviceCommandResponse)
}

public class Toy {
    class var descriptor: String { return "" }
    
    let core: ToyCore
    let identifier: UUID
    weak var owner: ToyBox?
    
    init(identifier: UUID, core: ToyCore, owner: ToyBox) {
        self.identifier = identifier
        self.core = core
        self.owner = owner
    }
    
    public var appVersion: AppVersion? {
        get {
            return core.appVersion
        }
    }
    
    public var batteryLevel: Double? {
        get {
            return nil
        }
    }
    
    public var peripheral: CBPeripheral {
        get {
            return self.core.peripheral
        }
    }
    
    //mimic Apple here to hide the CBPeripheral code from code completion.
    final class ToyCore: NSObject, CBPeripheralDelegate {
        typealias ConnectionCallBack = ((_ didPrepareConnection: Bool, _ error: ConnectionError?) -> Void)
        
        private var wakeCharacteristic: CBCharacteristic!
        private var txPowerCharacteristic: CBCharacteristic!
        private var antiDoSCharacteristic: CBCharacteristic!
        private var commandsCharacteristic: CBCharacteristic!
        private var responseCharacteristic: CBCharacteristic!
        private var commandQueue: OperationQueue
        
        let peripheral: CBPeripheral
        lazy private var commandSequencer: CommandSequencer = CommandSequencer()
        
        var appVersion: AppVersion?
        var batteryVoltage: Double?
        
        init(peripheral: CBPeripheral) {
            self.peripheral = peripheral
            self.commandQueue = OperationQueue()
            self.commandQueue.maxConcurrentOperationCount = 1
            
            super.init()
            peripheral.delegate = self
        }
        
        class AsyncWeakWrapper {
            weak var value: ToyCoreAsyncListener?
            
            init(value: ToyCoreAsyncListener) {
                self.value = value
            }
        }
        
        private var asyncListeners = [AsyncWeakWrapper]()
        
        public func addAsyncListener(_ asyncListener: ToyCoreAsyncListener) {
            if !asyncListeners.contains() { $0 === asyncListener } {
                asyncListeners.append(AsyncWeakWrapper(value: asyncListener))
            }
        }
        
        public func removeAsyncListener(_ asyncListener: ToyCoreAsyncListener) {
            guard let index = asyncListeners.index(where: {$0 === asyncListener }) else { return }
            asyncListeners.remove(at: index)
        }
        
        func send(_ command: Command) {
            let commandOperation = CommandOperation(command, toyCore: self, commandSequencer: commandSequencer, characteristic: commandsCharacteristic)
            commandQueue.addOperation(commandOperation)
        }
        
        func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
            peripheral.writeValue(data, for: characteristic, type: type)
        }
        
        var preparationCallback: ConnectionCallBack?
        
        func prepareConnection(callback: @escaping ConnectionCallBack) {
            preparationCallback = callback
            peripheral.discoverServices([.robotControlService, .bleService])
        }
        
        //MARK - CBPeripheralDelegate
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            if let error = error {
                preparationCallback?(false, .peripheralFailed(error: error))
            }
            
            guard let services = peripheral.services else { return }
            
            for service in services {
                switch service.uuid {
                case CBUUID.bleService:
                    peripheral.discoverCharacteristics([.wakeCharacteristic, .txPowerCharacteristic, .antiDoSCharacteristic], for:service)
                case CBUUID.robotControlService:
                    peripheral.discoverCharacteristics([.commandsCharacteristic, .responseCharacteristic], for: service)
                default:
                    //don't care about these
                    continue
                }
            }
            
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            if let error = error {
                preparationCallback?(false, .peripheralFailed(error: error))
                preparationCallback = nil
                return
            }
            
            guard let characteristics = service.characteristics else { return }
            
            for characteristic in characteristics {
                switch characteristic.uuid {
                case CBUUID.wakeCharacteristic:
                    wakeCharacteristic = characteristic
                case CBUUID.txPowerCharacteristic:
                    txPowerCharacteristic = characteristic
                case CBUUID.antiDoSCharacteristic:
                    antiDoSCharacteristic = characteristic
                case CBUUID.commandsCharacteristic:
                    commandsCharacteristic = characteristic
                case CBUUID.responseCharacteristic:
                    responseCharacteristic = characteristic
                default:
                    // This is a characteristic we don't care about. Ignore it.
                    continue
                }
            }
            
            if wakeCharacteristic != nil && txPowerCharacteristic != nil && antiDoSCharacteristic != nil && commandsCharacteristic != nil && responseCharacteristic != nil {
                peripheral.writeValue("011i3".data(using: String.Encoding.ascii)!, for: antiDoSCharacteristic, type: .withResponse)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            if characteristic === responseCharacteristic {
                if let error = error {
                    preparationCallback?(false, .peripheralFailed(error: error))
                    preparationCallback = nil
                    return
                }
                
                // Send a versioning comment to try to start the connection.
                send(VersioningCommand())
            }
        }
        
        var onCharacteristicWrite: ((_ peripheral: CBPeripheral, _ characteristic: CBCharacteristic, _ error: Error?) -> Void)?
        
        func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
            if let error = error {
                preparationCallback?(false, .peripheralFailed(error: error))
                preparationCallback = nil
                return
            }
            
            onCharacteristicWrite?(peripheral, characteristic, error)
            
            if characteristic === antiDoSCharacteristic {
                peripheral.writeValue(Data(bytes: [7]), for: txPowerCharacteristic, type: .withResponse)
            } else if characteristic === txPowerCharacteristic {
                peripheral.writeValue(Data(bytes: [1]), for: wakeCharacteristic, type: .withResponse)
            } else if characteristic === wakeCharacteristic {
                peripheral.setNotifyValue(true, for: responseCharacteristic)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            if let error = error {
                preparationCallback?(false, .peripheralFailed(error: error))
                preparationCallback = nil
                return
            }
            
            guard characteristic === responseCharacteristic, let response = characteristic.value else { return }
            commandSequencer.parseResponseFromToy(response) { [unowned self] (sequencer, commandResponse) in
                switch commandResponse {
                case let versionsCommandResponse as VersionsCommandResponse:
                    self.appVersion = versionsCommandResponse.appVersion
                    self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveDeviceResponse: versionsCommandResponse) }
                    self.send(PowerStateCommand())
                    
                case let powerState as PowerStateResponse:
                    self.batteryVoltage = powerState.batteryVoltage
                    self.preparationCallback?(true, nil)
                    self.preparationCallback = nil
                    
                case let asyncCommandResponse as AsyncCommandResponse:
                    self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveAsyncResponse: asyncCommandResponse) }
                    
                case let deviceCommandResponse as DeviceCommandResponse:
                    self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveDeviceResponse: deviceCommandResponse) }
                    
                default:
                    break
                }
            }
            
        }
    }
    
}
