# 🤖 Peblo AI Story Buddy & Interactive Quiz Engine

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Groq](https://img.shields.io/badge/Groq_API-F36F21?style=for-the-badge&logo=ai&logoColor=white)

An immersive, gamified mobile component built for **Peblo's Developer Intern Challenge**. This application blends text-to-speech (TTS) narration with a dynamic, LLM-generated interactive quiz to create a joyful learning journey for children.

Having previously engineered automated academic modules and dynamic worksheet generation engines, I approached this challenge with a focus on resilient state management, lightweight rendering, and a frictionless user experience—especially for mid-range Android devices.

---

## ✨ Core Features

* **Generative AI Storytelling:** Integrates the live **Groq API (`llama3-8b-8192`)** to instantly generate kid-friendly, 2-sentence stories alongside contextual multiple-choice questions.
* **Native TTS Narration:** Utilizes device-native text-to-speech (`flutter_tts`) at a slowed, kid-appropriate speech rate (`0.4`).
* **Data-Driven UI:** The quiz component is 100% dynamic. It parses strictly formatted JSON to render the exact number of options provided by the AI (whether 3, 4, or 5) without any hardcoded layout dependencies.
* **Joyful Micro-Interactions:** * 🎉 **Success State:** Triggers an explosive confetti animation on the correct answer.
    * 📳 **Feedback State:** Implements a custom mathematical sine-wave shake animation to gently indicate an incorrect answer.
* **Resilient Error Handling:** Graceful fallbacks for network latency, missing API keys, or TTS engine failures.

---

## 🛠️ Technical Implementation & Assessment Notes

This section covers the specific architecture decisions requested in the challenge prompt.

### 1. Framework & State Management
I chose **Flutter** paired with the **Provider** pattern. Flutter is ideal for rapidly building the vibrant, custom UI required for children's apps. Provider ensures that the business logic (audio playback, AI network calls, quiz validation) is strictly separated from the UI layer. This prevents unnecessary widget rebuilds, keeping the app fluid and memory-efficient.

### 2. Audio-to-Quiz State Transition
To manage the transition from narration to the interactive quiz smoothly, I utilized the `setCompletionHandler` within the `flutter_tts` package:
1. When "Read Me a Story" is tapped, the `_isPlaying` state becomes `true`.
2. Once the TTS engine fires the completion callback, `_isPlaying` toggles to `false`, and `_showQuiz` toggles to `true`.
3. Calling `notifyListeners()` prompts the UI to cleanly replace the read button with the dynamic Quiz component in the widget tree.

### 3. Data-Driven Quiz Rendering
The quiz heavily relies on the `QuizModel` class, which deserializes the JSON payload from the Groq API. In the UI, a spread operator `...widget.quizData.options.map(...)` iterates over the options array. This guarantees the UI will dynamically generate the correct number of `ElevatedButton` widgets based on the backend response, ensuring a decoupled, data-driven architecture.

### 4. Caching Approach
Currently, the app uses device-native TTS, which doesn't require audio caching. However, if scaling to a remote API like ElevenLabs, my approach would be:
* Generate a unique MD5 hash of the story text string.
* Check the local device directory (`path_provider`) for an audio file matching that hash.
* If present, play locally. If absent, stream from the API, save the buffer to the local filesystem asynchronously, and execute playback.

### 5. Loading & Failure States
* **Loading:** While the Groq API fetches or TTS prepares, `_isLoading` swaps the UI controls for a `CircularProgressIndicator`.
* **Failure:** The `setErrorHandler` on the TTS engine and `try/catch` blocks on the HTTP requests update an `_errorMessage` string. This displays a friendly prompt ("Oops! Buddy lost his voice") and restores the button state for a retry, preventing application hangs.

### 6. Performance Optimization for Modest Devices (~3GB RAM)
To ensure 60fps performance on target demographic hardware:
* **Const Constructors:** Heavily utilized `const` keywords to prevent Flutter from rebuilding static assets (like the AI Buddy avatar) during state changes.
* **Math-Based Animations:** Instead of using heavy `.rive` or `.gif` assets for the "wrong answer" shake, I built a custom `AnimationController` using a sinusoidal translation (`sin(_shakeAnimation.value * pi) * 10`). This requires a fraction of the memory footprint.

### 7. AI Usage & Judgment
* **Assistance:** I used LLM assistance to generate boilerplate JSON serialization classes and help structure the initial `ChangeNotifier` layout.
* **Rejection:** The AI initially suggested using an explicit `AnimationController` with complex `Tween` fading transitions to swap the audio button for the quiz. I rejected this to prioritize mid-range device performance, opting instead for a direct boolean state swap which is computationally cheaper and equally effective.
* **Resolution:** I encountered an issue where the Groq API would sometimes return conversational text alongside the JSON. I resolved this by enforcing strict system prompts (`"response_format": {"type": "json_object"}`) to guarantee a parsable payload.

---

## 🚀 How to Run Locally

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/your-username/peblo-ai-buddy.git](https://github.com/your-username/peblo-ai-buddy.git)
   cd peblo-ai-buddy
   
2.**Install Dependencies:**
   ```bash
      flutter pub get
   ```
3.**Configure API Key:**
   ```bash
      static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
   ```
4.**Run the App:**
   ```bash
    flutter run
  ```

Built by Shivesh Nath Tiwari for the Peblo Developer Challenge.


