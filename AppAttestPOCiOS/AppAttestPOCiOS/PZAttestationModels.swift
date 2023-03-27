//
//  PZAttestationModels.swift
//  AppAttestPOCiOS
//
//  Created by Hemanth Ramapuram on 24/03/23.
//

import Foundation
import Anchor

struct PZStatement : Equatable {
  let certificates : [X509.Certificate]
  let receipt : Data
}
