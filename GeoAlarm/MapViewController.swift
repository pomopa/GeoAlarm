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
            annotation.subtitle = "Radius: \(alarm.radius) \(alarm.unit)"
            mapView.addAnnotation(annotation)
            
            let active = alarm.isActive
            // need to review - km vs m,  missing mi...
            let radiusInMeters = alarm.unit == "km" ? alarm.radius * 1000 : alarm.radius
            let circle = MKCircle(
                center: annotation.coordinate,
                radius: radiusInMeters
            )
            circle.subtitle = active ? "Active" : "Inactive"
            mapView.addOverlay(circle)
        }
        
        // Zoom to show all alarms
        if !alarms.isEmpty {
            let coordinates = alarms.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
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
        
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            print(circle.subtitle)
            if circle.subtitle == "Active" {
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.green
            } else {
                renderer.fillColor = UIColor.black.withAlphaComponent(0.01)
                renderer.strokeColor = UIColor.red
            }
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // Customize pin appearance
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        let identifier = "AlarmPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.markerTintColor = .systemRed
            
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}
