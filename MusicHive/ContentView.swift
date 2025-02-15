//
//  ContentView.swift
//  MusicHive
//
//  Created by bappelberg on 2025-02-09.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .padding()

            Button(action: {
                spotifyManager.authorize() // Starta Spotify-auktoriseringen
            }) {
                Text("Authorize with Spotify")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(SpotifyManager()) // Förhandsgranska med SpotifyManager
}
