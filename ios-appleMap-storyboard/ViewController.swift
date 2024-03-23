//
//  ViewController.swift
//  ios-appleMap-storyboard
//
//  Created by Sarbajit Biswal on 12/02/24.
//

import UIKit
import MapKit
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var currentBtn: UIButton?
    @IBOutlet weak var searchBar: UITextField?
    @IBOutlet weak var mapView: MKMapView?
    var sourcePostiton: CLLocationCoordinate2D?
    var locationManager = CLLocationManager()
    var tappedLocation: CLLocationCoordinate2D?
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapRecognizer.delegate = self
        mapView?.addGestureRecognizer(tapRecognizer)
        self.mapView?.register(CustomAnnotation.self, forAnnotationViewWithReuseIdentifier: "CustomAnnotation")
        self.mapView?.delegate = self
        self.locationManager.delegate = self
        addExamplePoints()

    }
    func showLocationPermissionPopUp() {
        // Show PopUp that Location services are not enabled and on tap of OK button take user back to previous screen
        print("Permisson not granted")
    }
    func setNavButton() {
        self.currentBtn?.setTitle("", for: .normal)
        self.currentBtn?.backgroundColor = .white
        self.currentBtn?.setImage(UIImage(systemName: ""), for: .normal)
    }

    @IBAction func currentBtnTapped(_ sender: Any) {
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.delegate = nil
        manager.stopUpdatingLocation()
        guard let latestLocation = locations.first else {return}
        sourcePostiton = latestLocation.coordinate
    }
    func zoomToLatestLocation(coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView?.setRegion(zoomRegion, animated: true)
    }
    func beginLocationUpdated(manager: CLLocationManager) {
        mapView?.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            self.showLocationPermissionPopUp()
        case .authorizedWhenInUse, .authorizedAlways:
            beginLocationUpdated(manager: manager)
        @unknown default:
            self.showLocationPermissionPopUp()
        }
    }
    @objc
    func handleMapTap(_ gestureReconizer: UITapGestureRecognizer) {
        let touchLocation = gestureReconizer.location(in: mapView)
        let locationCoordinate = mapView?.convert(touchLocation,toCoordinateFrom: mapView)
        if let locationCoordinate = locationCoordinate {
            print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            //fetchLocationDetails(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)) { (placemarks, error) in
                guard let placemark = placemarks?.first else {
                    print("No placemark found")
                    return
                }
                // Use placemark to get the address
                if let address = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                    let formattedAddress = address.joined(separator: ", ")
                    print("Formatted Address: \(formattedAddress)")
                }
            }
            tappedLocation = locationCoordinate
            showAnnotation()
        }
    }
    func showAnnotation() {
        if let tappedLocation = tappedLocation {
            /// Removing existing annotations before adding new ones
            let oldAnnotations = self.mapView?.annotations
            mapView?.removeAnnotations(oldAnnotations ?? [])
            mapView?.addAnnotation(CustomAnnotation(latitude: tappedLocation.latitude, longitude: tappedLocation.longitude))
            mapView?.showAnnotations([CustomAnnotation(latitude: tappedLocation.latitude, longitude: tappedLocation.longitude)], animated: true)
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let customAnnotation = annotation as? CustomAnnotation else {
            return nil
        }

        let annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: "CustomAnnotation")
        annotationView.markerTintColor = .blue
        annotationView.glyphText = "H"
        // Customize annotation view

        return annotationView
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is MKPinAnnotationView)
    }
    private func addExamplePoints() {
        /// Removing existing annotations before adding new ones
        let oldAnnotations = self.mapView?.annotations
        mapView?.removeAnnotations(oldAnnotations ?? [])

        /// Generating and adding new annotations to the map
        let points = generateExamplePoints()
        //mapView?.addAnnotations(points)
        mapView?.showAnnotations(points, animated: true)
    }

    private func generateExamplePoints() -> [CustomAnnotation] {
        var points: [CustomAnnotation] = []
        points = [CustomAnnotation(latitude: 20.31483516799026, longitude: 85.82004622890578),
                  CustomAnnotation(latitude: 20.310220482804002, longitude: 85.81322691889663),
                  CustomAnnotation(latitude: 20.3483516799027, longitude: 85.82014622890578),
                  CustomAnnotation(latitude: 20.31483516799028, longitude: 85.82224622890578)]

        return points
    }
    func fetchLocationDetails(latitude: Double, longitude: Double) {
        // Construct the URL
        let apiKey: String = "c10866f456864d1e93d036262d558175"
        let urlString = "https://api.geoapify.com/v1/geocode/reverse?lat=\(latitude)&lon=\(longitude)&format=json&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        // Create the URLSession
        let session = URLSession(configuration: .default)

        // Create the data task
        let task = session.dataTask(with: url) { data, response, error in
            // Check for errors
            if let error = error {
                print("Error: \(error)")
                return
            }

            // Check for response status code
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response")
                return
            }

            // Check if data is available
            guard let data = data else {
                print("No data received")
                return
            }

            // Parse the JSON response
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonDictionary = json as? [String: Any],
                   let results = jsonDictionary["results"] as? [[String: Any]],
                   let locationDetails = results.first {
                    // Handle the location details
                    print(locationDetails)


                } else {
                    print("Invalid JSON format")
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }

        // Start the data task
        task.resume()
    }
}

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D

    init(latitude: Double, longitude: Double){
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        super.init()
    }
}
