class DynamicMusicScanner : StaticEventHandler
{
    Array<string> globalPlaylist; 
    Array<int> playbackHistory;
    int currentTrackIndex;
    int checkTimer;       
    int lastFormatFilter;
    int justSwitchedDelay; 
    string toastTrackName;
    int toastTimer;
    const TOAST_DURATION = 105;
    Array<string> ignoredWads;
    Array<string> ignoredTracks;
    bool needPlaylistRefresh;
    override void OnRegister()
    {
        currentTrackIndex = 0;
        checkTimer = 0;
        lastFormatFilter = -1;
        justSwitchedDelay = 0;
        toastTimer = 0;
        toastTrackName = "";
        needPlaylistRefresh = false;
        LoadIgnoredData();
    }
    void SaveIgnoredData()
    {
        CVar wadCVar = CVar.FindCVar("music_player_ignored_wads");
        if (wadCVar)
        {
            string s = "";
            for (int i = 0; i < ignoredWads.Size(); i++) s = s .. ignoredWads[i] .. "|";
            wadCVar.SetString(s);
        }
        CVar trackCVar = CVar.FindCVar("music_player_ignored_tracks");
        if (trackCVar)
        {
            string s = "";
            for (int i = 0; i < ignoredTracks.Size(); i++) s = s .. ignoredTracks[i] .. "|";
            trackCVar.SetString(s);
        }
    }
    void LoadIgnoredData()
    {
        ignoredWads.Clear();
        CVar wadCVar = CVar.FindCVar("music_player_ignored_wads");
        if (wadCVar)
        {
            string s = wadCVar.GetString();
            while (s.Length() > 0)
            {
                int idx = s.IndexOf("|");
                if (idx == -1) break;
                string item = s.Mid(0, idx);
                if (item != "") ignoredWads.Push(item);
                s = s.Mid(idx + 1);
            }
        }
        ignoredTracks.Clear();
        CVar trackCVar = CVar.FindCVar("music_player_ignored_tracks");
        if (trackCVar)
        {
            string s = trackCVar.GetString();
            while (s.Length() > 0)
            {
                int idx = s.IndexOf("|");
                if (idx == -1) break;
                string item = s.Mid(0, idx);
                if (item != "") ignoredTracks.Push(item);
                s = s.Mid(idx + 1);
            }
        }
    }
    bool IsWadIgnored(string wadName)
    {
        wadName.MakeLower();
        return (ignoredWads.Find(wadName) != ignoredWads.Size());
    }
    bool IsTrackIgnored(string trackName)
    {
        trackName.MakeLower();
        return (ignoredTracks.Find(trackName) != ignoredTracks.Size());
    }
    void ScanLoadedLumps()
    {
        globalPlaylist.Clear();
        LoadIgnoredData();
        CVar formatCVar = CVar.FindCVar("music_player_format");
        int formatFilter = formatCVar ? formatCVar.GetInt() : 0;
        CVar noIwadCVar = CVar.FindCVar("music_player_no_iwad");
        bool noIwadMusic = noIwadCVar ? (noIwadCVar.GetInt() == 1) : false;
        lastFormatFilter = formatFilter;
        for (int i = 0; i < Wads.GetNumLumps(); i++)
        {
            string lumpName = Wads.GetLumpName(i);
            lumpName.MakeUpper();
            string fullPath = Wads.GetLumpFullName(i);
            fullPath.MakeLower();
            int len = fullPath.Length();
            string shortName = lumpName;
            int lastSlash = fullPath.LastIndexOf("/");
            if (lastSlash != -1) shortName = fullPath.Mid(lastSlash + 1);
            shortName.MakeLower();
            if (IsTrackIgnored(shortName)) continue;
            bool isClassicTrack = (lumpName.Mid(0, 2) == "D_" || lumpName.Mid(0, 4) == "MUS_");
            if (isClassicTrack && lumpName.Length() <= 8 && lastSlash == -1)
            {
                if (IsWadIgnored("iwad_tracks")) continue;
                if (noIwadMusic && lumpName.Mid(0, 2) == "D_") continue;
                if (formatFilter == 1) continue; 
                if (globalPlaylist.Find(lumpName) == globalPlaylist.Size()) globalPlaylist.Push(lumpName); 
                continue;
            }
            if (fullPath.Mid(0, 6) == "music/" && len > 4)
            {
                string cleanPath = fullPath.Mid(6);
                int nextSlash = cleanPath.IndexOf("/");
                string modFolder = "root_music";
                if (nextSlash != -1) modFolder = cleanPath.Mid(0, nextSlash);
                if (IsWadIgnored(modFolder)) continue;
                if (shortName.Mid(0, 2) == "o_") continue;
                string ext4 = fullPath.Mid(len - 4);
                string ext5 = fullPath.Mid(len - 5);
                bool isMidi = (ext4 == ".mid" || ext4 == ".mus");
                bool isDigital = (ext4 == ".ogg" || ext4 == ".mp3" || ext5 == ".flac");
                if (formatFilter == 1 && !isMidi) continue;       
                if (formatFilter == 2 && !isDigital) continue;    
                if (isMidi || isDigital)
                {
                    if (globalPlaylist.Find(fullPath) == globalPlaylist.Size()) globalPlaylist.Push(fullPath); 
                }
            }
        }
        if (globalPlaylist.Size() > 0 && currentTrackIndex >= globalPlaylist.Size()) currentTrackIndex = 0;
        Console.Printf("[Music Player] Playlist scanned. Loaded %d tracks.", globalPlaylist.Size());
    }
    override bool InputProcess(InputEvent e)
    {
        if (e.Type == InputEvent.Type_KeyDown)
        {
            int key1, key2;
            [key1, key2] = Bindings.GetKeysForCommand("mp_nexttrack");
            if ((key1 && e.KeyScan == key1) || (key2 && e.KeyScan == key2))
            {
                EventHandler.SendNetworkEvent("msg_mp_next");
                return true;
            }
            [key1, key2] = Bindings.GetKeysForCommand("mp_prevtrack");
            if ((key1 && e.KeyScan == key1) || (key2 && e.KeyScan == key2))
            {
                EventHandler.SendNetworkEvent("msg_mp_prev");
                return true;
            }
            [key1, key2] = Bindings.GetKeysForCommand("mp_ignoretrack");
            if ((key1 && e.KeyScan == key1) || (key2 && e.KeyScan == key2))
            {
                EventHandler.SendNetworkEvent("msg_mp_ignore_current");
                return true;
            }
        }
        return false;
    }
    override void NetworkProcess(ConsoleEvent e)
    {
        if (e.Name == "msg_mp_next") SwitchToNextTrack();
        else if (e.Name == "msg_mp_prev") SwitchToPrevTrack();
        else if (e.Name == "msg_mp_refresh") needPlaylistRefresh = true;
        else if (e.Name == "msg_mp_ignore_current")
        {
            if (globalPlaylist.Size() == 0) return;
            string currentTrack = globalPlaylist[currentTrackIndex];
            currentTrack.MakeLower();
            string trackFileName = currentTrack;
            int lastSlash = trackFileName.LastIndexOf("/");
            if (lastSlash != -1) trackFileName = trackFileName.Mid(lastSlash + 1);
            if (ignoredTracks.Find(trackFileName) == ignoredTracks.Size())
            {
                ignoredTracks.Push(trackFileName);
                SaveIgnoredData();
                Console.Printf("[Music Player] Track added to ignore list: %s", trackFileName);
                needPlaylistRefresh = true;
                SwitchToNextTrack();
            }
        }
        else if (e.Name.Mid(0, 11) == "tgl_mp_wad:")
        {
            string targetWad = e.Name.Mid(11);
            targetWad.MakeLower();
            int idx = ignoredWads.Find(targetWad);
            if (idx == ignoredWads.Size()) ignoredWads.Push(targetWad);
            else ignoredWads.Delete(idx);
            SaveIgnoredData();
            needPlaylistRefresh = true;
        }
        else if (e.Name.Mid(0, 13) == "del_mp_track:")
        {
            string targetTrack = e.Name.Mid(13);
            targetTrack.MakeLower();
            int idx = ignoredTracks.Find(targetTrack);
            if (idx != ignoredTracks.Size())
            {
                ignoredTracks.Delete(idx);
                SaveIgnoredData();
                needPlaylistRefresh = true;
            }
        }
    }
    override void WorldLoaded(WorldEvent e)
    {
        ScanLoadedLumps();
        if (globalPlaylist.Size() == 0) return;
        S_ChangeMusic("", 0, false); 
        SwitchToNextTrack();
    }
    override void UiTick()
    {
        CVar formatCVar = CVar.FindCVar("music_player_format");
        if (formatCVar && formatCVar.GetInt() != lastFormatFilter) EventHandler.SendNetworkEvent("msg_mp_refresh");
    }
    override void WorldTick()
    {
        if (needPlaylistRefresh)
        {
            needPlaylistRefresh = false;
            ScanLoadedLumps();
        }
        if (toastTimer > 0) toastTimer--;
        if (globalPlaylist.Size() == 0) return;
        if (justSwitchedDelay > 0)
        {
            justSwitchedDelay--;
            return;
        }
        checkTimer++;
        if (checkTimer >= 35) 
        {
            checkTimer = 0;
            if (MusPlaying.name == "")
            {
                CVar repeatCVar = CVar.FindCVar("music_player_repeat");
                int isRepeat = repeatCVar ? repeatCVar.GetInt() : 0;
                if (isRepeat == 1) PlayCurrentPlaylistTrack();
                else SwitchToNextTrack();
            }
        }
    }
    void SwitchToNextTrack()
    {
        if (globalPlaylist.Size() == 0) return;
        playbackHistory.Push(currentTrackIndex);
        if (playbackHistory.Size() > 50) playbackHistory.Delete(0);
        CVar shuffleCVar = CVar.FindCVar("music_player_shuffle");
        int isShuffle = shuffleCVar ? shuffleCVar.GetInt() : 0;
        if (isShuffle == 1) currentTrackIndex = Random[MusicRand](0, globalPlaylist.Size() - 1);
        else
        {
            currentTrackIndex++;
            if (currentTrackIndex >= globalPlaylist.Size()) currentTrackIndex = 0;
        }
        PlayCurrentPlaylistTrack();
    }
    void SwitchToPrevTrack()
    {
        if (globalPlaylist.Size() == 0) return;
        if (playbackHistory.Size() > 0)
        {
            int lastHistoryIdx = playbackHistory.Size() - 1;
            currentTrackIndex = playbackHistory[lastHistoryIdx];
            playbackHistory.Delete(lastHistoryIdx);
        }
        else
        {
            currentTrackIndex--;
            if (currentTrackIndex < 0) currentTrackIndex = globalPlaylist.Size() - 1;
        }
        PlayCurrentPlaylistTrack();
    }
    void PlayCurrentPlaylistTrack()
    {
        if (globalPlaylist.Size() == 0) return;
        string currentTrack = globalPlaylist[currentTrackIndex];
        S_ChangeMusic("", 0, false);
        bool isMidiTrack = (currentTrack.IndexOf(".mid") != -1 || currentTrack.IndexOf(".mus") != -1);
        if (isMidiTrack) S_ChangeMusic(currentTrack, 0, true); 
        else S_ChangeMusic(currentTrack, 0, false); 
        justSwitchedDelay = 350; 
        string trackName = currentTrack;
        int lastSlash = trackName.LastIndexOf("/");
        if (lastSlash != -1) trackName = trackName.Mid(lastSlash + 1);
        toastTrackName = trackName;
        toastTimer = TOAST_DURATION;
    }
    override void RenderOverlay(RenderEvent e)
    {
        if (toastTimer <= 0 || toastTrackName == "") return;
        int baseWidth = 800;
        int baseHeight = 600;
        double yOffset = 0;
        if (toastTimer > TOAST_DURATION - 15) yOffset = -50 * (double(toastTimer - (TOAST_DURATION - 15)) / 15.0);
        else if (toastTimer < 15) yOffset = -50 * (1.0 - (double(toastTimer) / 15.0));
        string fullMessage = "Now Playing: " .. toastTrackName;
        Font clearFont = Font.GetFont("SMALLFONT");
        if (clearFont == null) clearFont = SmallFont; 
        int textWidth = clearFont.StringWidth(fullMessage);
        double drawX = (baseWidth / 2.0) - (textWidth / 2.0);
        double drawY = 20 + yOffset;
        Screen.DrawText(clearFont, Font.CR_BLACK, drawX, drawY + 1, fullMessage, DTA_VirtualWidth, baseWidth, DTA_VirtualHeight, baseHeight, DTA_KeepRatio, true);
        Screen.DrawText(clearFont, Font.CR_GOLD, drawX, drawY, fullMessage, DTA_VirtualWidth, baseWidth, DTA_VirtualHeight, baseHeight, DTA_KeepRatio, true);
    }
}
class ListWadsMenu : ListMenu
{
    int selection;
    override void Drawer()
    {
        Super.Drawer();
        Font mFont = Font.GetFont("SMALLFONT");
        if (!mFont) mFont = SmallFont;
        CVar handlerCVar = CVar.FindCVar("music_player_ignored_wads");
        string currentIgnored = handlerCVar ? handlerCVar.GetString() : "";
        Array<string> detectedFolders;
        for (int i = 0; i < Wads.GetNumLumps(); i++)
        {
            string fullPath = Wads.GetLumpFullName(i);
            fullPath.MakeLower();
            if (fullPath.Mid(0, 6) == "music/" && fullPath.Length() > 6)
            {
                string cleanPath = fullPath.Mid(6);
                int nextSlash = cleanPath.IndexOf("/");
                string modFolder = "root_music";
                if (nextSlash != -1) modFolder = cleanPath.Mid(0, nextSlash);
                if (detectedFolders.Find(modFolder) == detectedFolders.Size()) detectedFolders.Push(modFolder);
            }
        }
        if (selection < 0) selection = 0;
        if (detectedFolders.Size() > 0 && selection >= detectedFolders.Size()) selection = detectedFolders.Size() - 1;
        int drawY = 60;
        Screen.DrawText(mFont, Font.CR_GOLD, 80, drawY, "Select Mod Folder (Use Up/Down, Enter to Toggle):", DTA_VirtualWidth, 800, DTA_VirtualHeight, 600, DTA_KeepRatio, true);
        int maxVisible = 25;
        int scrollOffset = 0;
        if (selection >= maxVisible) scrollOffset = selection - maxVisible + 1;
        drawY += 30;
        if (detectedFolders.Size() == 0) Screen.DrawText(mFont, Font.CR_DARKGRAY, 100, drawY, "<No Mod Folders Found>", DTA_VirtualWidth, 800, DTA_VirtualHeight, 600, DTA_KeepRatio, true);
        for (int i = scrollOffset; i < detectedFolders.Size(); i++)
        {
            string folder = detectedFolders[i];
            folder.MakeLower();
            bool isIgnored = (currentIgnored.IndexOf(folder .. "|") != -1);
            string label = folder .. (isIgnored ? " [IGNORED]" : " [ACTIVE]");
            int color = (i == selection) ? Font.CR_GOLD : Font.CR_WHITE;
            Screen.DrawText(mFont, color, 100, drawY, label, DTA_VirtualWidth, 800, DTA_VirtualHeight, 600, DTA_KeepRatio, true);
            drawY += 15;
            if (drawY > 520) break;
        }
    }
    override bool MenuEvent(int key, bool fromMouse)
    {
        if (key == Menu.MKEY_Up) { selection--; return true; }
        if (key == Menu.MKEY_Down) { selection++; return true; }
        if (key == Menu.MKEY_Enter)
        {
            Array<string> detectedFolders;
            for (int i = 0; i < Wads.GetNumLumps(); i++)
            {
                string fullPath = Wads.GetLumpFullName(i);
                fullPath.MakeLower();
                if (fullPath.Mid(0, 6) == "music/" && fullPath.Length() > 6)
                {
                    string cleanPath = fullPath.Mid(6);
                    int nextSlash = cleanPath.IndexOf("/");
                    string modFolder = "root_music";
                    if (nextSlash != -1) modFolder = cleanPath.Mid(0, nextSlash);
                    if (detectedFolders.Find(modFolder) == detectedFolders.Size()) detectedFolders.Push(modFolder);
                }
            }
            if (selection >= 0 && selection < detectedFolders.Size())
            {
                EventHandler.SendNetworkEvent("tgl_mp_wad:" .. detectedFolders[selection]);
            }
            return true;
        }
        if (key == Menu.MKEY_Back) { Close(); return true; }
        return false;
    }
}
class ListTracksMenu : ListMenu
{
    int selection;
    override void Drawer()
    {
        Super.Drawer();
        Font mFont = Font.GetFont("SMALLFONT");
        if (!mFont) mFont = SmallFont;
        CVar handlerCVar = CVar.FindCVar("music_player_ignored_tracks");
        string s = handlerCVar ? handlerCVar.GetString() : "";
        Array<string> activeIgnoredTracks;
        while (s.Length() > 0)
        {
            int idx = s.IndexOf("|");
            if (idx == -1) break;
            string tName = s.Mid(0, idx);
            s = s.Mid(idx + 1);
            if (tName != "") activeIgnoredTracks.Push(tName);
        }
        if (selection < 0) selection = 0;
        if (activeIgnoredTracks.Size() > 0 && selection >= activeIgnoredTracks.Size()) selection = activeIgnoredTracks.Size() - 1;
        int drawY = 80;
        Screen.DrawText(mFont, Font.CR_GOLD, 100, drawY, "Ignored Tracks (Use Up/Down, Enter to Remove):", DTA_VirtualWidth, 800, DTA_VirtualHeight, 600, DTA_KeepRatio, true);
        int maxVisible = 25;
        int scrollOffset = 0;
        if (selection >= maxVisible) scrollOffset = selection - maxVisible + 1;
        drawY += 25;
        for (int i = scrollOffset; i < activeIgnoredTracks.Size(); i++)
        {
            int color = (i == selection) ? Font.CR_GOLD : Font.CR_WHITE;
            Screen.DrawText(mFont, color, 100, drawY, activeIgnoredTracks[i], DTA_VirtualWidth, 800, DTA_VirtualHeight, 600, DTA_KeepRatio, true);
            drawY += 15;
            if (drawY > 520) break;
        }
        if (activeIgnoredTracks.Size() == 0) Screen.DrawText(mFont, Font.CR_DARKGRAY, 100, drawY, "<Empty List>", DTA_VirtualWidth, 800, DTA_VirtualHeight, 600, DTA_KeepRatio, true);
    }
    override bool MenuEvent(int key, bool fromMouse)
    {
        if (key == Menu.MKEY_Up) { selection--; return true; }
        if (key == Menu.MKEY_Down) { selection++; return true; }
        if (key == Menu.MKEY_Enter)
        {
            CVar handlerCVar = CVar.FindCVar("music_player_ignored_tracks");
            string s = handlerCVar ? handlerCVar.GetString() : "";
            Array<string> activeIgnoredTracks;
            while (s.Length() > 0)
            {
                int idx = s.IndexOf("|");
                if (idx == -1) break;
                string tName = s.Mid(0, idx);
                s = s.Mid(idx + 1);
                if (tName != "") activeIgnoredTracks.Push(tName);
            }
            if (selection >= 0 && selection < activeIgnoredTracks.Size())
            {
                EventHandler.SendNetworkEvent("del_mp_track:" .. activeIgnoredTracks[selection]);
            }
            return true;
        }
        if (key == Menu.MKEY_Back) { Close(); return true; }
        return false;
    }
}
