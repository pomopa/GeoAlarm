//
//  LocationSearchService.swift
//  GeoAlarm
//
//  Created by Pol Monne Parera on 8/1/26.
//
import MapKit

final class LocationSearchService {

    func resolve(
        completion: MKLocalSearchCompletion,
        completionHandler: @escaping (CLLocationCoordinate2D?) -> Void
    ) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            guard
                error == nil,
                let coordinate = response?
                    .mapItems
                    .first?
                    .location
                    .coordinate
            else {
                completionHandler(nil)
                return
            }

            completionHandler(coordinate)
        }
    }
}
