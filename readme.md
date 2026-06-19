*Project: Peblo AI Story Buddy & Quiz Component*

​Building edutainment tools that blend immersive storytelling with AI aligns perfectly with my professional experience engineering backend solutions and AI-driven educational modules, such as the dynamic worksheet generation systems I built at Effling Kids. This project applies those principles to create a joyful, resilient mobile experience.  

*​Framework Choice*
​I chose Flutter combined with the Provider pattern for state management. Flutter allows for the rapid creation of vibrant, custom UI components necessary for a child-friendly application. Provider ensures that the business logic (audio playback states, quiz logic) is cleanly separated from the UI, preventing unnecessary widget rebuilds and maintaining high frame rates.  

*​State Transitions (Audio to Quiz)*
​To manage the transition from the narration to the interactive quiz, I utilized the setCompletionHandler within the flutter_tts package.

​-- When the "Read Me a Story" button is tapped, the _isPlaying state is set to true.
--​ Once the TTS engine fires the completion callback, _isPlaying is set to false, and _showQuiz is set to true.
--​ notifyListeners() is called, prompting the UI to gracefully replace the read button with the quiz component in the widget tree.

 
*​Data-Driven Quiz Rendering*
​The quiz is strictly data-driven and does not hardcode any UI elements. I created a QuizModel class that parses the JSON payload. In the UI, a ListView.builder (or spread operator on mapped elements) iterates over the options array from the model. Whether the backend sends 3, 4, or 5 options, the UI dynamically generates the corresponding number of ElevatedButton widgets automatically.

​*Caching Approach*
​Since the application currently utilizes the native on-device TTS engine (flutter_tts), audio files do not need remote caching. However, if this were scaled to use a remote API like ElevenLabs, my approach would be:  

​Generate a unique hash (MD5) based on the story text string.
​Check the local device directory (using path_provider) for an audio file matching that hash.
​If present, play locally. If not, stream from the API, save the buffer to the local file system asynchronously, and play.

*​Loading and Failure States*
​Resilience is critical for an uninterrupted learning journey.  

-- ​Loading: When TTS is preparing, a _isLoading boolean replaces the play icon with a CircularProgressIndicator.

-- ​Failure: flutter_tts utilizes a setErrorHandler. If an error is caught (e.g., engine failure), it updates a string variable _errorMessage with a child-friendly prompt ("Oops! Buddy lost his voice. Try again!") and restores the initial button state allowing for a graceful retry.

 
*​Performance Profiling & Modest Hardware Optimization*
​The primary demographic relies on mid-range Android devices with ~3GB RAM. To optimize for this:  

-- ​Const Constructors: I heavily utilized const keywords throughout the widget tree to prevent Flutter from re-rendering static UI components (like the Buddy avatar and static styling) during the state changes.
-- ​Animation Efficiency: I used standard Flutter layout transitions and lightweight packages (confetti) rather than heavy Flare/Rive assets to ensure the memory footprint stays low and animations run at 60fps.

 
*​AI Usage & Judgment*

​Assistance: I used Google Gemini to help generate the boilerplate JSON serialization classes and structure the ChangeNotifier state layout.
​Rejection: The AI initially suggested using an explicit AnimationController with complex Tween objects for a fading transition between the audio and the quiz. I rejected this because it unnecessarily complicated the widget tree for a mid-range device. Instead, I opted for a direct boolean state swap, which is less computationally expensive and fulfills the requirement smoothly.
​Troubleshooting: I initially encountered a bug where the TTS would not stop if the user navigated away from the screen. I resolved this by ensuring the dispose() method of the widget explicitly calls _flutterTts.stop() to free up memory resources

