//
//  ViewController.swift
//  Yaht
//
//  Created by Владимир Коваленко on 17.06.2022.
//

import UIKit
import SnapKit
import MapKit
import CoreLocation

final class ViewController: UIViewController {
    
    private var viewModel: ViewModel!
    private var locationManager: CLLocationManager = CLLocationManager()
    
    private var latUser: Double = .init()
    private var lonUser: Double = .init()
    private var drawableLocations: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
    private var timer: Timer?
    
    lazy private var pitchView: DataSubview = {
        let view = DataSubview()
        view.nameLabel.text = "Pitch"
        view.layer.cornerRadius = 5
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.7
        view.layer.shadowRadius = 5
        return view
    }()
    
    lazy private var rollView: DataSubview = {
        let view = DataSubview()
        view.layer.cornerRadius = 5
        view.nameLabel.text = "Heel"
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.7
        view.layer.shadowRadius = 8
        return view
    }()
    
    lazy private var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 24
        stack.distribution = .fillEqually
        stack.alignment = .fill
        [
            self.pitchView,
            self.rollView
        ].forEach { stack.addArrangedSubview($0) }
        return stack
    }()
    
    private lazy var clearWayButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.setTitle("Clear", for: .normal)
        button.addTarget(self, action:  #selector(clearUserWay), for: .touchUpInside)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        return button
    }()
    
    private var mapView: MKMapView!
    
    private let frame = CGRect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        getData()
        setUpMapView()
        getCurrentLocation()
        setView()
        drawUserWay()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }
    
    private func setView() {
        view.addSubview(mapView)
        view.addSubview(stackView)
        view.addSubview(clearWayButton)
        mapView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.top.equalToSuperview().offset(56)
            make.height.equalTo(UIScreen.main.bounds.height/2)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(18)
            make.left.equalToSuperview().offset(36)
            make.right.equalToSuperview().offset(-36)
            make.height.equalTo(100)
        }
        clearWayButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(36)
        }
    }
    
    private func getData() {
        self.viewModel = ViewModel()
        self.viewModel.bindViewModelToController = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let pitch = self.viewModel.convertToDegrees(self.viewModel.motionData?.pitch)
                let roll = self.viewModel.convertToDegrees(self.viewModel.motionData?.roll)
                self.pitchView.valueLabel.text = pitch
                self.rollView.valueLabel.text = roll
            }
        }
    }
    
    @objc private func clearUserWay(_ sender: UIButton!) {
        mapView.removeOverlays(mapView.overlays)
        drawableLocations.removeAll()
    }
}

// MARK: - set map and current location methods
extension ViewController {
    private func setUpMapView() {
        mapView = MKMapView(frame: frame)
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        let userLocation = CLLocation(latitude: latUser, longitude: lonUser)
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 6000
        )
        mapView.setCameraBoundary(
            MKMapView.CameraBoundary(coordinateRegion: region),
            animated: true)
        mapView.setRegion(region, animated: true)
    }
    
    private func getCurrentLocation() {
        locationManager.delegate = self
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let userLocation = CLLocationCoordinate2D(
            latitude: latUser,
            longitude: lonUser
        )
        mapView.setCenter(userLocation, animated: true)
    }
    
    private func drawUserWay() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            let polyline = MKPolyline(
                coordinates: self.drawableLocations,
                count: self.drawableLocations.count
            )
            self.mapView.addOverlay(polyline)
        })
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        if let location = locations.last {
            drawableLocations.append(CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ))
            latUser = location.coordinate.latitude
            lonUser  = location.coordinate.longitude
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("\(error.localizedDescription)")
    }
}

// MARK: - MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let routePolyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.strokeColor = UIColor.black
            renderer.lineWidth = 1
            return renderer
        }
        
        return MKOverlayRenderer()
    }
}
