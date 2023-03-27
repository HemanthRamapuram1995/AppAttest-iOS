//
//  AppAttestService.swift
//  AppAttestPOCiOS
//
//  Created by Hemanth Ramapuram on 21/03/23.
//

import Foundation
import AppAttest
import CryptoKit

class AppAttestService{
  private let challenge : String
  init(){
    self.challenge = "hemanh\(arc4random())"
  }
  
  var serverChallenge : String {
    return self.challenge
  }
  
  func checkKeyAttestation(data :Data? , keyId : String) -> P256.Signing.PublicKey?{
    
    let request = AppAttest.AttestationRequest(attestation: data!, keyID: Data(base64Encoded: keyId)!)
    let appID = AppAttest.AppID(teamID: "GMSGY63W5S", bundleID: "com.hdfc.payzapp.zetaregression")
    do {
      let result = try AppAttest.verifyAttestation(challenge: Data(challenge.utf8),
                                                   request: request,
                                                   appID: appID)
      
      UserDefaults.standard.set(result.publicKey.rawRepresentation , forKey: "publickey")
      UserDefaults.standard.set(0, forKey: "Counter")
      print(result)
      return result.publicKey
    } catch {
      return nil
        // Handle the error
    }
  }
  
  func verifyAssertion(publicKey : P256.Signing.PublicKey ,assertion : Data, clientDataHash : Data , challenge : Data) throws ->  Bool {
    
    
    var counter = 0
    if let useCount = UserDefaults.standard.value(forKey: "Counter") as? Int{
      counter =  useCount
    }
    
    let appID = AppAttest.AppID(teamID: "GMSGY63W5S", bundleID: "com.hdfc.payzapp.zetaregression")
    
    
    let assertionreq = AppAttest.AssertionRequest(assertion: assertion, 
                                                  clientData: clientDataHash, 
                                                  challenge: challenge)
    do{
      try AppAttest.verifyAssertion(challenge: challenge, 
                                    request: assertionreq,
                                    previousResult: nil,
                                    publicKey: publicKey, 
                                    appID: appID)
      return true
    }catch {
      return false
    }
    
    
  }
  
}
