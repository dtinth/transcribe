# transcriber

CLI tool for macOS that uses SFSpeechRecognizer to transcribe speech from the microphone. The recognition result will be written to the standard output as JSON string.

![Example screenshot](example.png)

⚠️ 🚧 **WARNING:** 💩 code ahead 🚧 ⚠️

## HELP WANTED

- I am a Swift noob. I don’t know how to turn this code into binary... I click run on Xcode and it kinda works, but if I run the binary from the terminal, it crashes.
- There is no error handling here, sometimes it doesn’t work. I don’t know why.

Some help would be appreciated.

## How to use

Open the Xcode project and click **Run.** Make sure Dictation feature is enabled in your system preferences, easiest way to enable this is by enabling Siri.

## Change the language

Add a `locale` to the source code like this and run:

```diff
-    private let speechRecognizer = SFSpeechRecognizer()
+    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "th"))
```
## Ideas

- Add CLI argument to allow the user to specify the language. Maybe using ArgumentParser? Not sure.
- Turn this into an HTTP speech recognition server that streams out server-sent events, so other apps can integrate with it, I guess?
