//
//  MusicHiveApp.swift
//  MusicHive
//
//  Created by bappelberg on 2025-02-09.
// This is the entry point for the SwiftUI app. It creates the main window and sets up the initial view and dependencies.
//

import SwiftUI
import SpotifyiOS

@main
struct MusicHiveApp: App {
    // Creating a SpotifyManager object that will handle all Spotify related functionality like authentication.
    @StateObject private var spotifyManager = SpotifyManager()

    var body: some Scene {
        WindowGroup {
            // The main content view that will be displayed in the app.
            ContentView()
                .onOpenURL { url in
                    // Handle the URL that is received after authentication (callback URL)
                    spotifyManager.handleOpenURL(url)
                }
                .environmentObject(spotifyManager) // Pass SpotifyManager to views as an environment object
        }
    }
}

class SpotifyManager: NSObject, ObservableObject, SPTAppRemoteDelegate {
    // AppRemote object to communicate with Spotify's app via Spotify iOS SDK
    var appRemote: SPTAppRemote!
    // Access token used to authenticate and authorize requests to Spotify's Web API
    var accessToken: String?

    override init() {
        super.init()

        // Fetch client ID from Info.plist or default to an empty string
        let clientID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String ?? ""
        // Define the redirect URL used by the Spotify authentication flow
        let redirectURL = URL(string: "musichive://callback")!
        // Create a configuration object for the Spotify SDK
        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)

        // Initialize the Spotify app remote with configuration and set log level for debugging
        appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self

        // Log the client ID and redirect URL for debugging purposes
        print("SpotifyManager initialized with client ID: \(clientID) and redirect URL: \(redirectURL)")
    }

    func authorize() {
        // Starts the authorization process and attempts to play a track
        print("Attempting to authorize Spotify...")
        self.appRemote.authorizeAndPlayURI("spotify:track:69bp2EbF7Q2rqc5N3ylezZ") { spotifyInstalled in
            // If Spotify is not installed, redirect to App Store
            if !spotifyInstalled {
                print("Spotify is not installed on the device. Redirecting to App Store...")
                self.openSpotifyInAppStore()
            } else {
                // If Spotify is installed, proceed with the authorization
                print("Spotify is installed. Opening the app for authorization...")
            }
        }
    }

    // This method is called when the Spotify app sends the authorization callback URL
    func handleOpenURL(_ url: URL) {
        // Log the received URL
        print("Received URL for callback: \(url.absoluteString)")

        // Extract the authorization parameters (e.g., access token) from the callback URL
        let parameters = appRemote.authorizationParameters(from: url)
        if let token = parameters?[SPTAppRemoteAccessTokenKey] {
            // Store the access token for future use
            appRemote.connectionParameters.accessToken = token
            self.accessToken = token
            print("Access token received: \(token)")
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            // Handle error if authentication fails
            print("Authentication error: \(errorDescription)")
        } else {
            // Handle unknown callback parameters
            print("Unknown callback parameters received: \(parameters ?? [:])")
        }
    }

    // MARK: - SPTAppRemoteDelegate

    // Called when the connection to Spotify is successfully established
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Connection to Spotify established successfully.")
    }

    // Called when the connection to Spotify fails
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        if let error = error {
            print("Failed to establish connection with error: \(error.localizedDescription)")
        } else {
            print("Failed to establish connection with an unknown error.")
        }
    }

    // Called when the connection to Spotify is disconnected
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        if let error = error {
            print("Disconnected from Spotify with error: \(error.localizedDescription)")
        } else {
            print("Disconnected from Spotify without error.")
        }
    }

    // Opens the Spotify App Store page if Spotify is not installed
    func openSpotifyInAppStore() {
        print("Redirecting to the App Store to install Spotify...")
        let spotifyAppStoreURL = URL(string: "https://apps.apple.com/se/app/spotify-musik-och-poddar/id324684580")!
        UIApplication.shared.open(spotifyAppStoreURL, options: [:]) { success in
            if success {
                print("Successfully opened App Store link.")
            } else {
                print("Failed to open App Store link.")
            }
        }
    }
}

// Extension to add Spotify search functionality
extension SpotifyManager {
    func searchTracks(query: String, completion: @escaping ([String]?, Error?) -> Void) {
        // Log the search query
        print("Searching for tracks with query: \(query)")

        // Ensure that access token is available for the search request
        guard let accessToken = self.accessToken else {
            let error = NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Access token is missing"])
            print("Error: Access token is missing.")
            completion(nil, error)
            return
        }

        // Log the access token used for the request (for debugging purposes)
        print("Access token used for request: \(accessToken)")

        // Build the API URL to search for tracks based on the provided query
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=10"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            let error = NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            print("Error: Invalid URL for search.")
            completion(nil, error)
            return
        }

        // Prepare the HTTP request with the necessary headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Log the full URL for the network request (for debugging purposes)
        print("Making network request to: \(url.absoluteString)")

        // Make the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors in the network request
            if let error = error {
                print("Network request failed with error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }

            // Ensure that data is received from the request
            guard let data = data else {
                let error = NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from request"])
                print("Error: No data received from request.")
                completion(nil, error)
                return
            }

            do {
                // Attempt to parse the JSON response from Spotify's API
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Received JSON response: \(json)")

                    // Check if tracks are found in the response and extract their names
                    if let tracks = json["tracks"] as? [String: Any],
                       let items = tracks["items"] as? [[String: Any]] {
                        let trackNames = items.compactMap { $0["name"] as? String }
                        print("Found tracks: \(trackNames)")
                        completion(trackNames, nil)
                    } else {
                        print("Error: Unexpected JSON structure or no tracks found.")
                        completion(nil, NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected JSON structure or no tracks found."]))
                    }
                } else {
                    print("Error: Failed to parse JSON response.")
                    completion(nil, NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response."]))
                }
            } catch {
                print("Error: Failed to parse JSON with error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
        task.resume()
    }
}
