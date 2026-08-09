### Dynamic Music Player.

If you are tired of listening to the same map tracks or manually changing music via console commands, this mod automates everything by building a dynamic, real-time playlist directly from your loaded files.

Whether you are running classic WADs or heavy PK3 megamods, this scanner crawls through your loaded lumps and puts together a fully interactive playback system.

But the best feature here is that you can add your own music files to playlist without any modding experience!

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

## How to use:

Just add "MusicPlayer.pk3" after any mod that has music in it or at the end of your mod load order. 
Everything that loads after MusicPlayer won't be added to music playlist.

## Want to add your music?

You don't need to make any .wad/.pk3 files to add your music!
Just load any folder that has /music/ inside and mod will add every playable file (.midi, .ogg, .mp3, .flac) that is inside (It also searches subfolders inside!)

# In case you use ZDL or similar launcher here is an example of my loadorder

1. MonsterFallDamageZ.pk3
2. bullet-time-x.pk3
3. lexicon-beta-build-133.pk3
4. lexicon-slaughter-v1.0.pk3
5. lexicon-miscdata-beta-build-133.pk3
6. DoomMetalVol5_44100.wad
7. VLT_PBR_POM - RC2GZ.pk3
8. BrutalDoomPlatinum-4.1dev.pk3
9. flashlight_plus_plus_v9_1.pk3
10. smpb-v1.2.pk3
11. lights.pk3
12. jp_smoothwater.pk3
13. NiceWallBlood.pk3
14. D:/Discography/ <--- this is where i put all my custom music. It has folder /music/ inside with different subfolders where all my custom .mp3 files located.
15. /MusicPlayer.pk3

Tested on GZDoom 4.10.0/4.14.1 and on UZDoom 4.14.3/5.0.0 and it works fine.
