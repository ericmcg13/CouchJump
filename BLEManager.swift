//
//  BLEManager.swift
//
//
//  Created by Eric McGaughey on 12/14/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//



import Foundation
import CoreBluetooth

/* Advertisment send the data snippet that details the data the perphial has to offer. if a matching advertisment string is received then the receiver should proceed with receiving the data (characteristic???) */

// TODO: UNFINISHED - Android development needs time to catch up before this can be finished and tested.

// Generate a new UUID for CouchJumping
let serviceUUID: CBUUID = CBUUID(string: "2A8EC204-B997-4153-A8C8-B1A9F7A1D855")
let characteristicUUID: CBUUID = CBUUID(string: "07DB788C-CE0D-45D0-A66A-112888F50FEA")


class BLEManager {
    
    private var centralManager: CBCentralManager
    private var peripheralManager: CBPeripheralManager
    private var bleHandler: BLEHandler
    
    var userObject: String = "" { didSet { self.bleHandler.passedUserObject = userObject } }
    
    init() {
        
        bleHandler = BLEHandler()
        bleHandler.passedUserObject = userObject
        
        centralManager = CBCentralManager(delegate: bleHandler, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: bleHandler, queue: nil)
    }
    
    func sendData(dataToSend: NSData) {
        
        // Break the data into 20 byte chunks and send it over to the receiver. (Is it necessary??)
        
    }
}

class BLEHandler: NSObject, CBCentralManagerDelegate {
    
    var passedUserObject: String?
    
    // Peripheral Variables
    private let bleService: CBMutableService = CBMutableService(type: serviceUUID, primary: true)
    
        
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        switch (central.state) {
            
        case .PoweredOff:
            print("Central is powered off")
            
        case .PoweredOn:
            print("Central is powered on so lets start scanning")
            // First parameter is an array of all the service UUID's that we are willing to subscribe to
            central.scanForPeripheralsWithServices([serviceUUID], options: nil)
        case .Resetting:
            print("Central is resetting")
            
        case .Unauthorized:
            print("Central is unauthorized")
            
        case .Unknown:
            print("Central is unknown")
            
        case.Unsupported:
            print("Central is unsupported")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Did discover: \(peripheral.name) with RSSI: \(RSSI) dBm")
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral")
        
        // TODO: Here is where we want to call a send data function to pass the info on to our connected device.
        // Need to specify the device(peripheral) we wish to connect to
    }
}

extension BLEHandler: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {

        switch peripheral.state {
            
        case .PoweredOff:
            print("Periperal Manager is powered off")
            
        case .PoweredOn:
            print("Periperal Manager is powered on")
            runServiceAdvertisment(peripheral)
        case .Resetting:
            print("Periperal Manager is resetting")
            
        case .Unauthorized:
            print("Periperal Manager is unauthorized")
            
        case .Unknown:
            print("Periperal Manager is unknown")
            
        case .Unsupported:
            print("Periperal Manager is unsupported")
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        // Started ads
        print("Started advertising")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        print("didAddService: \(service)")
    }
    
    func runServiceAdvertisment(peripheralDevice: CBPeripheralManager) {
        
        let characteristic: String? = passedUserObject
        
        // Build the characteristics for the service
        let characteristicString: NSData? = characteristic?.dataUsingEncoding(NSUTF8StringEncoding)
        
        // Here would could add another characteristic to the array in order to pass the user object with the click caller.
        let couchJumpingCharacteristics = CBMutableCharacteristic(type: characteristicUUID, properties: CBCharacteristicProperties.Read, value: characteristicString, permissions: CBAttributePermissions.Readable)
        
        // Add the characteristics to the service
        bleService.characteristics = [couchJumpingCharacteristics]
        
        // Create / add the service
        peripheralDevice.addService(bleService)
        
        // Create the advertisment data with name and UUID's
        let data: NSDictionary = [CBAdvertisementDataLocalNameKey: "CouchJumping" , CBAdvertisementDataServiceUUIDsKey: [serviceUUID, characteristicUUID]]
        
        // Start the advertising
        peripheralDevice.startAdvertising(data as? [String : AnyObject])
    }
}

extension BLEHandler: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        // Array of all the available services
        for service in peripheral.services! {
            print("Did discover service: \(service)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        // Show the available characteristics
        for characteristic in service.characteristics! {
            print(" Did discover charateristic: \(characteristic)")
            
            // Read the value for the characteristic (userString?)
            peripheral.readValueForCharacteristic(characteristic)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?) {
        print("Discovered included services: \(service)")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Discovered descriptors for characteristic: \(characteristic)")
    }
}