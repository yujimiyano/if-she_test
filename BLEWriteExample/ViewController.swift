//
//  ViewController.swift
//  BLEScanExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var isScanning = false
    var statusLED2 = false
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var settingCharacteristic: CBCharacteristic!
//    var pullupCharacteristic: CBCharacteristic! // I/Oのプルアップ用
    var outputCharacteristic: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セントラルマネージャ初期化
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // =========================================================================
    // MARK: CBCentralManagerDelegate
    
    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        print("state: \(central.state)")
    }
    
    // ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber)
    {
        print("発見したBLEデバイス: \(peripheral)")
      
        if peripheral.name != nil { // nilを検出した場合は先に進まない
      
          if peripheral.name!.hasPrefix("konashi") {
            
            // 接続停止処理
            self.centralManager.stopScan() // 接続停止
//            sender.setTitle("START SCAN", forState: UIControlState.Normal) // ボタンのラベルも戻したいけどやり方不明で一旦放置
            isScanning = false
            
            self.peripheral = peripheral
            
            // 接続開始
            self.centralManager.connect(self.peripheral, options: nil)
          }
        }
    }
    
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager,
        didConnect peripheral: CBPeripheral)
    {
        print("接続成功！")

        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        
        // サービス探索開始
        peripheral.discoverServices(nil)
    }
    
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?)
    {
        print("接続失敗・・・")
    }

    
    // =========================================================================
    // MARK:CBPeripheralDelegate
    
    // サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if (error != nil) {
            print("エラー: \(error)")
            return
        }
        
        let services: NSArray = peripheral.services! as NSArray

        print("\(services.count) 個のサービスを発見！ \(services)")

        for obj in services {
            
            if let service = obj as? CBService {
                
                // キャラクタリスティック探索開始
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?)
    {
        if (error != nil) {
            print("エラー: \(error)")
            return
        }
        
        let characteristics: NSArray = service.characteristics! as NSArray
        print("\(characteristics.count) 個のキャラクタリスティックを発見！ \(characteristics)")
        
        for obj in characteristics {
            
            if let characteristic = obj as? CBCharacteristic {
                
//                if characteristic.UUID.isEqual(CBUUID(string: "3000")) {  // konashi 2.0では3000、3001の値が229B3000-03FB-40DA-98A7-B0DEF65C2D4Bに変更されている。詳細はiOS x BLE本のp.226参照
              if characteristic.uuid.isEqual(CBUUID(string: "229B3000-03FB-40DA-98A7-B0DEF65C2D4B")) {  // konashi 2.0では3000、3001の値が229B3000-03FB-40DA-98A7-B0DEF65C2D4Bに変更されている。詳細はiOS x BLE本のp.226参照
                
                    self.settingCharacteristic = characteristic
                    print("KONASHI_PIO_SETTING_UUID を発見！")
                }
//                else if characteristic.UUID.isEqual(CBUUID(string: "3001")) {
//                
//                    self.pullupCharacteristic = characteristic // 変数名を新しく定義したものに変える。プルアップできるようにする。
//                    println("KONASHI_PIO_PULLUP_UUID を発見！")
//                  
//                    // PIOの0のみプルアップ
//                    var value: CUnsignedChar = 0x01    // 0000 0001
//                    let data: NSData = NSData(bytes: &value, length: 1)
//                  
//                    // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
//                    self.peripheral.writeValue(
//                      data,
//                      forCharacteristic: self.pullupCharacteristic,
//                      type: CBCharacteristicWriteType.WithoutResponse)
//                  
//                }
                
//                else if characteristic.UUID.isEqual(CBUUID(string: "3002")) {
              else if characteristic.uuid.isEqual(CBUUID(string: "229B3002-03FB-40DA-98A7-B0DEF65C2D4B")) {
              
                    self.outputCharacteristic = characteristic
                    print("KONASHI_PIO_OUTPUT_UUID を発見！")
                }
                // konashi の PIO_INPUT_NOTIFICATION キャラクタリスティック
                // PIO0
//                else if characteristic.UUID.isEqual(CBUUID(string: "3003")) {
              else if characteristic.uuid.isEqual(CBUUID(string: "229B3003-03FB-40DA-98A7-B0DEF65C2D4B")) {
              
                  // 更新通知受け取りを開始する
                  peripheral.setNotifyValue(
                    true,
                    for: characteristic)
                }
            }
        }
    }

    // データ書き込みが完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
      didWriteValueFor characteristic: CBCharacteristic,
      error: Error?)
    {
      if (error != nil) {
        print("書き込み失敗...error: \(error), characteristic uuid: \(characteristic.uuid)")
        return
      }
        
      print("書き込み成功！service uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid), value: \(characteristic.value)")
    }

    // Notify開始／停止時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
      didUpdateNotificationStateFor characteristic: CBCharacteristic,
      error: Error?)
    {
      if error != nil {
      
        print("Notify状態更新失敗...error: \(error)")
      }
      else {
        print("Notify状態更新成功！characteristic UUID:\(characteristic.uuid), isNotifying: \(characteristic.isNotifying)")
      }
    }
  
    // データ更新時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
      didUpdateValueFor characteristic: CBCharacteristic,
      error: Error?)
    {
      if error != nil {
        print("データ更新通知エラー: \(error)")
        return
      }
      print("データ更新！ characteristic UUID: \(characteristic.uuid), value: \(characteristic.value)")
      
      // SW1が押されたらLED2を点灯
      if characteristic.uuid.isEqual(CBUUID(string: "229B3003-03FB-40DA-98A7-B0DEF65C2D4B")) {
          print("スイッチの状態変更")
        
        var valueSW: NSInteger = 0
        (characteristic.value! as NSData).getBytes(&valueSW, length: MemoryLayout<NSInteger>.size) // NSData -> NSIntegerに変換
        
        ledPrep()
        
        if (valueSW == 1) {
          print("LED2 ON")
          ledOn()
        }
        else if (valueSW == 0) {
          print("LED2 OFF")
          ledOff()
        }
        
      }
      
      //
    }

  func ledPrep(){
    // 書き込みデータ生成（LED2）
    var value: CUnsignedChar = 0x01 << 1    // 0000 0010
//    let data: Data = Data(bytes: UnsafePointer<UInt8>(&value), count: 1)
    let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))

    
    // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
    self.peripheral.writeValue(
      data,
      for: self.settingCharacteristic,
      type: CBCharacteristicWriteType.withoutResponse)
    
  }
  
  func ledOn(){
    // 書き込みデータ生成（LED2）
    var value: CUnsignedChar = 0x01 << 1    // 0000 0010
//    let data: Data = Data(bytes: UnsafePointer<UInt8>(&value), count: 1)
    let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    
    // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
    self.peripheral.writeValue(
      data,
      for: self.outputCharacteristic,
      type: CBCharacteristicWriteType.withoutResponse)
  }
  
  func ledOff(){
    // 書き込みデータ生成（LED2）
    var value: CUnsignedChar = 0x00 << 1
//    let data: Data = Data(bytes: UnsafePointer<UInt8>(&value), count: 1)
    let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    
    // konashiの digitalWrite:value: で LED2 を LOW にすることに相当
    self.peripheral.writeValue(
      data,
      for: self.outputCharacteristic,
      type: CBCharacteristicWriteType.withoutResponse)
  }
  
    // =========================================================================
    // MARK: Actions

    @IBAction func scanBtnTapped(_ sender: UIButton) {
        
        if !isScanning {
            
            isScanning = true
            
            self.centralManager.scanForPeripherals(withServices: nil, options: nil) // 第一引数がnilだとすべてのペリフェラルを検出対象とする
          
            sender.setTitle("STOP SCAN", for: UIControlState())
        }
        else {
            
            self.centralManager.stopScan()
            
            sender.setTitle("START SCAN", for: UIControlState())
            
            isScanning = false
        }
    }

    @IBAction func ledBtnTapped(_ sender: UIButton) {

        if self.settingCharacteristic == nil || self.outputCharacteristic == nil {
            
            print("Konashi is not ready!")
            return
        }

        // LED2を光らせる

      ledPrep()
//      // 書き込みデータ生成（LED2）
//      var value: CUnsignedChar = 0x01 << 1    // 0000 0010
//      let data: NSData = NSData(bytes: &value, length: 1)
//      
//      // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
//      self.peripheral.writeValue(
//        data,
//        forCharacteristic: self.settingCharacteristic,
//        type: CBCharacteristicWriteType.WithoutResponse)
      
      if !statusLED2{
        
        statusLED2 = true

        ledOn()
//        // 書き込みデータ生成（LED2）
//        var value: CUnsignedChar = 0x01 << 1    // 0000 0010
//        let data: NSData = NSData(bytes: &value, length: 1)
//        
//        // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
//        self.peripheral.writeValue(
//          data,
//          forCharacteristic: self.outputCharacteristic,
//          type: CBCharacteristicWriteType.WithoutResponse)
      
        sender.setTitle("LED2 OFF", for: UIControlState())
      }
      else {
        
        statusLED2 = false

        ledOff()
//        // 書き込みデータ生成（LED2）
//        var value: CUnsignedChar = 0x00 << 1
//        let data: NSData = NSData(bytes: &value, length: 1)
//        
//        // konashiの digitalWrite:value: で LED2 を LOW にすることに相当
//        self.peripheral.writeValue(
//          data,
//          forCharacteristic: self.outputCharacteristic,
//          type: CBCharacteristicWriteType.WithoutResponse)
        
        sender.setTitle("LED2 ON", for: UIControlState())
        
      }
    }
}

