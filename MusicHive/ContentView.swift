//
//  ContentView.swift
//  MusicHive
//
//  Created by bappelberg on 2025-02-09.
//  This is the view for the main user interface, where the user can interact with the app and search for tracks.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var searchResults: [TrackResult] = []
    @State private var searchQuery: String = ""

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

                // Map View (Placeholder)
                NavigationView {
                    VStack {
                        Text("Map Placeholder")
                            .font(.largeTitle)
                            .padding()
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

#Preview {
    // Previews the ContentView with the SpotifyManager injected into the environment
    ContentView()
        .environmentObject(SpotifyManager()) // Preview SpotifyManager
}
