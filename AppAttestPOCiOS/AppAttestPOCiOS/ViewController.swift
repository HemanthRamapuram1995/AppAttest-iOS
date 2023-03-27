//
//  ViewController.swift
//  AppAttestPOCiOS
//
//  Created by Hemanth Ramapuram on 21/03/23.
//

import UIKit
import DeviceCheck
import CryptoKit

enum AttestationStatus : String{
  case generateKey = "Generate Key"
  case attestKey = "Attest Key"
  case verifyAssertion = "Verify Assertion"
}

class ViewController: UIViewController {
  
  var keyId : String? 
  var attestationData : Data?
  var publicKey : P256.Signing.PublicKey?
  
  @IBOutlet var button : UIButton?
  @IBOutlet var statusText : UILabel?
  
  @IBAction func triggerAction(){
    guard let titleLabel = button?.titleLabel?.text else{
      return
    }
    switch AttestationStatus(rawValue: titleLabel) {
    case .verifyAssertion:
//      verifyAssertion()
      break
    case .attestKey:
      attestKey()
      break
    case .generateKey:
      generateKey()
      break
    default:
      print("nothing")
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let keyId = UserDefaults.standard.value(forKey: "AttestKeyId") as? String {
      self.keyId = keyId
     checkAndUpdateAttestationStatus()
    }else{
      buttonStatusGenerateKey()
    }
    
    // Do any additional setup after loading the view.
  }
  
  func checkAndUpdateAttestationStatus(){
    if let bStatus = UserDefaults.standard.value(forKey: "AttestationStatus") as? Bool , bStatus {
      buttonStatusVerifyAssertion()
    }else{
      buttonStatusAttestKey()
    }
  }
  
  func buttonStatusGenerateKey(){
    self.button?.setTitle(AttestationStatus.generateKey.rawValue, for: .normal)
  }
  
  func buttonStatusAttestKey(){
    self.button?.setTitle(AttestationStatus.attestKey.rawValue, for: .normal)
  }
  
  
  func buttonStatusVerifyAssertion(){
    self.button?.setTitle(AttestationStatus.verifyAssertion.rawValue, for: .normal)
  }
  
  func generateKey(){
    if let keyId = UserDefaults.standard.value(forKey: "AttestKeyId") as?  String {
      self.keyId = keyId
      buttonStatusAttestKey()
      return
    }
    DCAppAttestService.shared.generateKey { [weak self] keyId , error in
      if let error = error {
        print(error)
        return
      }
      UserDefaults.standard.set(keyId!, forKey: "AttestKeyId")
      self?.keyId = keyId
      self?.attestKey()
    }
  }
  
  func attestKey(){
    guard let keyId = keyId else {
      return
    }
    let service = AppAttestService()
    let challenge = service.serverChallenge
    
    
    let hash = Data(SHA256.hash(data: Data(challenge.utf8)))
    
    DCAppAttestService.shared.attestKey(keyId, clientDataHash: hash) { [weak self , keyId] attestationData, error in
      if let error = error {
        print(error)
        return
      }
      UserDefaults.standard.set(attestationData, forKey: "AttestationData")
      self?.attestationData = attestationData
      let result  = service.checkKeyAttestation(data: attestationData, keyId: keyId)
      self?.verifyAssertion(publicKey: result!)
    }
  }
  
  func verifyAssertion(publicKey : P256.Signing.PublicKey){
    guard let keyId = self.keyId else {
      return
    }
    
    let service = AppAttestService()
    
    let challenge = service.serverChallenge
    
    let clientData = ["name" : "Hemanth" , "challenge" : challenge]
    
    guard let data = try? JSONEncoder().encode(clientData) else { return }
    let clientDatahash = Data(SHA256.hash(data: data))
    
    
    DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDatahash) { assertion, error in
      guard let assertion = assertion else{return}
      guard let result  = try? service.verifyAssertion(publicKey: publicKey, assertion: assertion,
                                                         clientDataHash: data,
                                                                challenge: Data(challenge.utf8)) else{
        self.statusText?.text = "Failed Assertion"
        return
      }
      if result{
        self.statusText?.text = "Assertion Succeeded"
      }
    }
    
  }
  
  
  
}

