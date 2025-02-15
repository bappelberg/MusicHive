//
//  ContentView.swift
//  MusicHive
//
//  Created by bappelberg on 2025-02-09.
//  This is the view for the main user interface, where the user can interact with the app and search for tracks.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var searchResults: [TrackResult] = []
    @State private var searchQuery: String = ""

    @StateObject private var mapViewModel = MapView()

    var body: some View {
        if spotifyManager.isAuthenticated {
            // Show main views if user is authorized
            TabView {
                // Home View
                NavigationView {
                    VStack {
                        Text("Welcome to MusicHive!")
                            .font(.largeTitle)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Home")
                    .navigationBarItems(leading: ProfileButton())
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }

                // Search View
                NavigationView {
                    VStack {
                        // Text field to input search query
                        TextField("Search for tracks", text: $searchQuery, onCommit: {
                            spotifyManager.searchTracks(query: searchQuery) { results, error in
                                if let results = results {
                                    self.searchResults = results
                                } else if let error = error {
                                    print("Search error: \(error.localizedDescription)")
                                }
                            }
                        })
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                        List(searchResults, id: \.name) { track in
                            HStack {
                                if let imageURL = track.imageURL {
                                    AsyncImage(url: imageURL) { image in
                                        image.resizable()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 50, height: 50)
                                }
                                VStack(alignment: .leading) {
                                    Text(track.name)
                                        .font(.headline)
                                    Text(track.artist)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .navigationTitle("Search")
                    .navigationBarItems(leading: ProfileButton())
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

                // Map View (Updated)
                NavigationView {
                    VStack {
                        Text("Map Placeholder")
                            .font(.largeTitle)
                            .padding()
                        
                        // Add a Map view here
                        MapViewRepresentable(region: $mapViewModel.region, mapViewModel: mapViewModel)
                            .frame(height: 300) // Adjust the size of the map
                        
                        Spacer()
                    }
                    .navigationTitle("Map")
                    .navigationBarItems(leading: ProfileButton())
                }
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            }
        } else {
            // Show authorize view if user is not authorized
            VStack {
                Button(action: {
                    spotifyManager.authorize()
                }) {
                    Text("Authorize with Spotify")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
}


class MapView: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.322665376, longitude: 18.069666388), // Stockholm
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Adjust zoom level
    )
    @Published var userLocation: CLLocationCoordinate2D?
    private var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Ask permissions to use geolocation
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation() // Start location updates when authorized
        } else {
            print("Location permission not granted")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Updated location: \(location.coordinate)") // Log the location for debugging
        userLocation = location.coordinate

        // Update map region based on the new location
        region.center = location.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var mapViewModel: MapView

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Enable location tracking and show the blue dot
        mapView.showsUserLocation = true // This will show the blue dot
        mapView.userTrackingMode = .none // Do not follow
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // If user location is available, update map
        if let userLocation = mapViewModel.userLocation {
            uiView.setRegion(MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ), animated: true)
        } else {
            uiView.setRegion(region, animated: true) // Fallback if user location doesn't exist
        }
    }
}

struct ProfileButton: View {
    var body: some View {
        NavigationLink(destination: ProfileView()) {
            Circle()
                .frame(width: 44, height: 44)
                .foregroundColor(.blue)
                .overlay(
                    Text("P")
                        .foregroundColor(.white)
                        .font(.headline)
                )
        }
    }
}

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile Page")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    // Previews the ContentView with the SpotifyManager injected into the environment
    ContentView()
        .environmentObject(SpotifyManager()) // Preview SpotifyManager
}
