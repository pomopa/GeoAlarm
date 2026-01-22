import UIKit
import MapKit
import FirebaseFirestore

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    private var alarms: [Alarm] = []
    private var selectedCoordinate: CLLocationCoordinate2D?
    private var addAlarmButton: UIButton?
    private var mapTapGesture: UITapGestureRecognizer!
    private var alarmsListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        fetchAlarms()
        
        mapTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleMapTap(_:))
        )
        mapTapGesture.cancelsTouchesInView = false
        mapTapGesture.delegate = self
        mapView.addGestureRecognizer(mapTapGesture)
    }
    
    // Fetch all alarms for the current user
    private func fetchAlarms() {
        alarmsListener = FirestoreHelper.listenToAlarms { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                print("Error fetching alarms:", error.localizedDescription)

            case .success(let alarms):
                self.alarms = alarms

                // Clear existing annotations
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.removeOverlays(self.mapView.overlays)

                self.displayAlarmsOnMap()
            }
        }
    }
 
    private func displayAlarmsOnMap() {
        for alarm in alarms {
            // Add pin annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: alarm.latitude,
                longitude: alarm.longitude
            )
            annotation.title = alarm.locationName
            annotation.subtitle = alarm.isActive ? "Active" : "Inactive"
            mapView.addAnnotation(annotation)
            
            let active = alarm.isActive

            let radiusInMeters: Double
            switch alarm.unit.lowercased() {
            case "km":
                radiusInMeters = alarm.radius * 1000
            case "mi":
                radiusInMeters = alarm.radius * 1609.34
            case "ft":
                radiusInMeters = alarm.radius * 0.3048
            default: // "m"
                radiusInMeters = alarm.radius
            }
            let circle = MKCircle(
                center: annotation.coordinate,
                radius: radiusInMeters
            )
            circle.subtitle = active ? "Active" : "Inactive"
            mapView.addOverlay(circle)
        }
        
        // Zoom to show all alarms
        let activeAlarms = alarms.filter { $0.isActive }
        let alarmsToShow = activeAlarms.isEmpty ? alarms : activeAlarms
        var coordinates = alarmsToShow.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        if coordinates.isEmpty, let userLocation = mapView.userLocation.location?.coordinate {
            let region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapView.setRegion(region, animated: true)
            return
        }
        
        if let userLocation = mapView.userLocation.location?.coordinate {
            coordinates.append(userLocation)
        }
                
        if !coordinates.isEmpty {
            let region = mapRegion(for: coordinates)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Calculate map region to fit all coordinates
    private func mapRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        var spanLat = (maxLat - minLat) * 1.2
        var spanLon = (maxLon - minLon) * 1.2

        // Clamp to MapKit safe limits
        spanLat = max(0.01, min(spanLat, 180))
        spanLon = max(0.01, min(spanLon, 360))

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapToEditAlarm",
           let vc = segue.destination as? EditAlarmViewController,
           let alarm = sender as? Alarm {
            vc.alarm = alarm
        }

        if segue.identifier == "MapToCreateAlarm",
           let vc = segue.destination as? CreateAlarmViewController,
           let coordinate = sender as? CLLocationCoordinate2D {
            vc.initialCoordinate = coordinate
        }
    }
    
    // Add alarm by pressing the map

    @objc private func addAlarmButtonTapped() {
        guard let coordinate = selectedCoordinate else { return }
        performSegue(withIdentifier: "MapToCreateAlarm", sender: coordinate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.addAlarmButton?.removeFromSuperview()
            self.addAlarmButton = nil
        }
    }
    
    private func showAddAlarmButton(at point: CGPoint) {
        addAlarmButton?.removeFromSuperview()

        let buttonSize: CGFloat = 44
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: point.x - buttonSize / 2,
            y: point.y - buttonSize / 2,
            width: buttonSize,
            height: buttonSize
        )

        button.backgroundColor = UIColor(red: 0xDB/255, green: 0x65/255, blue: 0x4D/255, alpha: 1)
        button.tintColor = UIColor(red: 0x1B/255, green: 0x2B/255, blue: 0x42/255, alpha: 1)
        button.layer.cornerRadius = buttonSize / 2
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)

        button.addTarget(
            self,
            action: #selector(addAlarmButtonTapped),
            for: .touchUpInside
        )
        
        mapView.addSubview(button)
        addAlarmButton = button
    }

    
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        if !mapView.selectedAnnotations.isEmpty {
            for annotation in mapView.selectedAnnotations {
                mapView.deselectAnnotation(annotation, animated: true)
            }
            return
        }
        
        selectedCoordinate = coordinate
        showAddAlarmButton(at: point)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        
        while let currentView = view {
            if currentView is MKAnnotationView {
                return false
            }
            view = currentView.superview
        }
            
        if let view = touch.view, view == addAlarmButton {
            return false
        }
            
        return true
    }
}

extension MapViewController: MKMapViewDelegate {
    // Customize the circle overlay appearance
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        guard let circle = overlay as? MKCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let renderer = MKCircleRenderer(circle: circle)

        if circle.subtitle == "Active" {
            renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.2)
            renderer.strokeColor = UIColor.systemGreen
            renderer.lineWidth = 2
        } else {
            renderer.fillColor = .clear
            renderer.strokeColor = .clear
            renderer.lineWidth = 0
        }

        return renderer
    }
    
    // Customize pin appearance
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "AlarmPin"
        let markerView = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView) ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        
        markerView.annotation = annotation
        
        markerView.glyphText = nil
        markerView.glyphImage = UIImage(systemName: "alarm")
        markerView.glyphTintColor = .white
        
        markerView.markerTintColor = annotation.subtitle == "Active"
            ? .systemGreen
            : .systemGray
        
        markerView.canShowCallout = true
        markerView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        return markerView
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let activeAlarms = alarms.filter { $0.isActive }
        guard activeAlarms.isEmpty else { return }

        let coordinate = userLocation.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else { return }
            
        if let alarm = alarms.first(where: {
            $0.latitude == annotation.coordinate.latitude &&
            $0.longitude == annotation.coordinate.longitude
        }) {
            performSegue(withIdentifier: "MapToEditAlarm", sender: alarm)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        addAlarmButton?.removeFromSuperview()
    }
}
