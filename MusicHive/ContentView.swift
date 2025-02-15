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
import Foundation

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var searchResults: [TrackResult] = []
    @State private var searchQuery: String = ""
    @State private var selectedTrack: TrackResult? // Track which musictrack that has been selected

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
                            Button(action: {
                                selectedTrack = track
                            }) {
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
                        Text("Map")
                            .font(.largeTitle)
                            .padding()
                        // Add a Map view here
                        MapViewRepresentable(region: $mapViewModel.region, mapViewModel: mapViewModel, selectedTrack: $selectedTrack)
                            .frame(height: 300)
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




class MapView: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.322665376, longitude: 18.069666388),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var annotations: [MKPointAnnotation] = []
    
    private var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        region.center = location.coordinate
    }
}


struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @ObservedObject var mapViewModel: MapView
    @Binding var selectedTrack: TrackResult?

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            let mapView = gesture.view as! MKMapView
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            guard let track = parent.selectedTrack else { return }

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = track.name
            annotation.subtitle = track.artist
            
            DispatchQueue.main.async {
                self.parent.mapViewModel.annotations.append(annotation)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(mapViewModel.annotations)
        uiView.setRegion(region, animated: true)
    }
}
