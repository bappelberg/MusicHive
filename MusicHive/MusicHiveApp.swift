//
//  MusicHiveApp.swift
//  MusicHive
//
//  Created by bappelberg on 2025-02-09.
//

import SwiftUI
import SpotifyiOS

@main
struct MusicHiveApp: App {
    @StateObject private var spotifyManager = SpotifyManager() // Manages the Spotify connection and authentication

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    spotifyManager.handleOpenURL(url) // Handle the URL received from the Spotify SDK
                }
                .environmentObject(spotifyManager) // Pass SpotifyManager to views as an environment object
        }
    }
}

class SpotifyManager: NSObject, ObservableObject, SPTAppRemoteDelegate {
    var appRemote: SPTAppRemote!
    var accessToken: String?

    override init() {
        super.init()

        // Get Client ID from Info.plist (Create a Config.xcconfig file and add your client id, then
        // open MusicHive.xcodeproj in XCode>Project>Info>Expand Debug>Press on the first Row in column
        // "Based on Configuration File" and set it to Config.xcconfig)
        // Finally in Info.plist, add a Key SPOTIFY_CLIENT_ID with the value of $(SPOTIFY_CLIENT_ID)
        let clientID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String ?? ""

        let configuration = SPTConfiguration(
            clientID: clientID,
            redirectURL: URL(string: "musichive://callback")! // Set up the redirect URL
        )

        appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
    }

    func authorize() {
        // Request authorization and start playing a specific track upon successful connection
        self.appRemote.authorizeAndPlayURI("spotify:track:69bp2EbF7Q2rqc5N3ylezZ") { spotifyInstalled in
            if !spotifyInstalled {
                print("Spotify is not installed on the device. Redirecting to App Store...")
                self.openSpotifyInAppStore() // Redirect to App Store if Spotify is not installed
            } else {
                print("Spotify is installed. Opening the app for authorization...")
            }
        }
    }

    func handleOpenURL(_ url: URL) {
        // Handle the authentication callback URL and extract the access token
        let parameters = appRemote.authorizationParameters(from: url)
        if let token = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = token
            self.accessToken = token
            print("Access token received: \(token)")
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            // Print the error description if authentication fails
            print("Authentication error: \(errorDescription)")
        }
    }

    // MARK: - SPTAppRemoteDelegate

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        // Called when the connection to Spotify is successfully established
        print("Connection to Spotify established.")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        // Handle connection failure
        if let error = error {
            print("Connection failed: \(error.localizedDescription)")
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        // Handle disconnection from Spotify
        if let error = error {
            print("Disconnected: \(error.localizedDescription)")
        }
    }

    func openSpotifyInAppStore() {
        // Redirects the user to the Spotify app page in the App Store
        let spotifyAppStoreURL = URL(string: "https://apps.apple.com/se/app/spotify-musik-och-poddar/id324684580")!
        UIApplication.shared.open(spotifyAppStoreURL, options: [:], completionHandler: nil)
    }
}
