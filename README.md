### Dynamic Music Scanner.

If you are tired of listening to the same map tracks or manually changing music via console commands, this mod automates everything by building a dynamic, real-time playlist directly from your loaded files.

Whether you are running classic WADs or heavy PK3 megamods, this scanner crawls through your loaded lumps and puts together a fully interactive playback system.

## Key Features:

*  **Smart Lump Scanning:** Automatically detects and filters classic tracks (starting with `D_`) and any external audio files located in the `music/` directory.
*  **Format Filtering via CVars:** Features a file format filter in options menu so you can choose exactly what you want to hear:
    - Play everything (MIDI and Digital)
    - MIDI-only mode
    - Digital-only mode (.ogg, .mp3, .flac)
*  **Shuffle & Repeat:** Options menu support (`music_player_shuffle` and `music_player_repeat`) to randomize your tracks or keep your favorite jam on loop.
*  **Playback History:** Remembers up to your last 50 played tracks so you can comfortably skip backward without getting lost.
*  **Keybind Integration:** Fully bindable commands (`mp_nexttrack` and `mp_prevtrack`) via your controls menu for seamless skipping mid-firefight.
*  **Smooth "Toast" HUD Notifications:** Completely customized text-rendering system. Whenever a track changes, a "Now Playing: [Track Name]" notification smoothly drops down from the top-center of your screen and fades away after 3 seconds. Completely unhooked from standard console printing for maximum immersion.

## How it works:

It runs on a robust `StaticEventHandler` that safely processes input events on the UI layer, and renders the HUD notifications perfectly centered on any display resolution—without relying on version-dependent ZScript UI flags.

## Console Variables & Commands:
* `music_player_format` (0 = All, 1 = MIDI, 2 = Digital)
* `music_player_shuffle` (0 = Linear, 1 = Shuffled)
* `music_player_repeat` (0 = Next Track on End, 1 = Loop Current Track)
* Bind `mp_nexttrack` / `mp_prevtrack` in your standard controls menu.
