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
        VStack {
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

            // List with search result
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
        .padding()
    }
}

#Preview {
    // Previews the ContentView with the SpotifyManager injected into the environment
    ContentView()
        .environmentObject(SpotifyManager()) // Preview SpotifyManager
}
