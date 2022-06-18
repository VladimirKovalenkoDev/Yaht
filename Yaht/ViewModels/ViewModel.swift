//
//  ViewModel.swift
//  Yaht
//
//  Created by Владимир Коваленко on 17.06.2022.
//

import Foundation

final class ViewModel: NSObject {
    
    private(set) var motionData: MotionData? {
        didSet {
            self.bindViewModelToController()
        }
    }
    
    var motionManager: MotionManagerProtocol?
    
    var bindViewModelToController : (() -> ()) = {}

    override init() {
        super.init()
        self.motionManager = MotionManager.shared
        getMotionData()
    }
    
    private func getMotionData() {
        motionManager?.startQueuedUpdates( { [weak self] motion in
            guard let self = self else { return }
            self.motionData = motion
        })
    }
    
    func convertToDegrees(_ number: Double?) -> String {
        guard let number = number else { return String() }
        return String(format: "%.1f", number * 180 / .pi)
    }
}
