import UIKit
import MapKit
import FirebaseFirestore
import FirebaseAuth

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    private var alarms: [Alarm] = []
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        fetchAlarms()
    }
    
    // Fetch all alarms for the current user
    private func fetchAlarms() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        
        db.collection("users")
            .document(userId)
            .collection("alarms")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching alarms: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No alarms found")
                    return
                }
                
                // Clear existing annotations
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.removeOverlays(self.mapView.overlays)
                
                // Parse alarms and add to map
                self.alarms = documents.compactMap { doc in
                    Alarm(id: doc.documentID, data: doc.data())
                }
                
                self.displayAlarmsOnMap()
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
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
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
        
        return markerView
    }
}
