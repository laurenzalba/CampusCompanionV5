# Campus Companion - MAD2 Laboratory Exercise 5

This Xcode project extends the earlier Campus Companion app with REST API requests, Codable JSON decoding, Core Data persistence, and a Refresh bar button.

## Included work

- `AnnouncementDTO.swift`: network DTO for the original `title`, `date`, `category` fields and Exercise 5 Part 3's optional `location` and `priorityLevel` values.
- `CampusCompanion/announcements.json`: the exact five-announcement JSON supplied with the task. It is added to the app's Copy Bundle Resources phase and used to seed the local Core Data store on first launch.
- Refresh button: sends an asynchronous `URLSession` GET request to the endpoint specified in the handout; the response is checked in error -> HTTP status -> data order, printed to the console, decoded using `JSONDecoder`, persisted to Core Data, and displayed on the main thread.
- Resilient fallback: the URL in the handout returned HTTP 404 when checked during project preparation. If the course endpoint is unavailable or its payload cannot be decoded, the app loads the bundled JSON, persists those five records, and displays a truthful `Sample JSON Loaded` alert rather than pretending a server request succeeded.
- Core Data remains programmatic in `AppDelegate.swift`. This intentionally avoids Xcode's failing `.xcdatamodeld` source-generation step seen in earlier versions.
- Existing features retained: welcome screen, UserDefaults preferences and reset, announcement details, add announcement, and swipe-to-delete.
- Exercise 5 Part 3 support: `location` and `priorityLevel` are stored on the managed object and shown in announcement rows and detail view. The supplied three-key JSON decodes safely; missing fields receive `Campus` and `Normal` defaults.

## Open and run

1. Extract the ZIP into a new folder. The project folder includes a top-level `announcements.json` for easy editing and a matching `CampusCompanion/announcements.json` copy that is bundled into the app.
2. Open `CampusCompanion.xcodeproj` in Xcode.
3. Select an iPhone Simulator and press Cmd+B, then Cmd+R.
4. Navigate to Campus Announcements. Use the Back button on the left to return to the welcome screen; Refresh and Add are on the right side of the navigation bar. Tap Refresh to fetch the remote endpoint, or load the bundled JSON fallback if the endpoint is unavailable.
5. If the remote course URL has been fixed and returns a 2xx JSON array, the app will show `Server Reached`. Until then, it shows `Sample JSON Loaded` and uses the included five-record JSON.

## Notes on verification

The ZIP, project property list, Storyboard XML, JSON syntax, Xcode build references, action connection names, and Swift syntax were checked in the creation environment. The JSON is present both at the project root and as a Copy Bundle Resources target resource. The Refresh button is installed on the right so the navigation controller can show its automatic Back button on the left. An actual iOS Simulator build cannot be run outside macOS/Xcode, so please build and run it in Xcode on your Mac. If an error remains, share the complete expanded error detail.
