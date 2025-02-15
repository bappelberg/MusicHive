//
//  ContentView.swift
//  MusicHive
//
//  Created by bappelberg on 2025-02-09.
// This is the view for the main user interface, where the user can interact with the app and search for tracks.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var searchQuery: String = ""
    @State private var searchResults: [String] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Image(systemName: "globe") // Placeholder icon
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!") // Placeholder greeting
                .padding()

            // Button to authorize with Spotify
            Button(action: {
                spotifyManager.authorize() // Trigger Spotify authorization process
            }) {
                Text("Authorize with Spotify")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            // Text field to input search query
            TextField("Search for tracks", text: $searchQuery, onCommit: {
                searchTracks()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

            // Display loading indicator or error message
            if isLoading {
                ProgressView()
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                // Display search results as a list of track names
                List(searchResults, id: \.self) { track in
                    Text(track)
                }
            }
        }
        .padding()
    }

    private func searchTracks() {
        // Function to trigger track search
        isLoading = true
        errorMessage = nil
        spotifyManager.searchTracks(query: searchQuery) { results, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription // Show error message if any
                } else {
                    searchResults = results ?? []  // Update search results if found
                }
            }
        }
    }
}

#Preview {
    // Previews the ContentView with the SpotifyManager injected into the environment
    ContentView()
        .environmentObject(SpotifyManager()) // Förhandsgranska med SpotifyManager
}
