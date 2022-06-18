//
//  MotionManager.swift
//  Yaht
//
//  Created by Владимир Коваленко on 17.06.2022.
//

import Foundation
import CoreMotion

protocol MotionManagerProtocol {
    func startQueuedUpdates(_ completion: @escaping (MotionData) -> ())
}

final class MotionManager: MotionManagerProtocol {

    static let shared = MotionManager()
    
    private let motion = CMMotionManager()
    private let queue = OperationQueue()
    
    func startQueuedUpdates(_ completion: @escaping (MotionData) -> () ) {
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 0.5
            motion.showsDeviceMovementDisplay = true
            motion.startDeviceMotionUpdates(
                using: .xMagneticNorthZVertical,
                to: self.queue,
                withHandler: { (data, error) in
                    if let validData = data {
                        let pitch = validData.attitude.pitch
                        let roll = validData.attitude.roll
                        completion(
                            MotionData(
                                pitch: pitch,
                                roll: roll
                        )
                        )
                    }
                })
        }
    }
}
