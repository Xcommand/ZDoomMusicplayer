class DynamicMusicScanner : StaticEventHandler
{
    Array<string> globalPlaylist; 
    Array<int> playbackHistory;
    int currentTrackIndex;
    
    int checkTimer;       
    int lastFormatFilter;
    int justSwitchedDelay; 

    // Переменные для работы всплывающего "тоста"
    string toastTrackName;
    int toastTimer;
    const TOAST_DURATION = 105; // 3 секунды показа (при 35 FPS)

    override void OnRegister()
    {
        currentTrackIndex = 0;
        checkTimer = 0;
        lastFormatFilter = -1;
        justSwitchedDelay = 0;
        toastTimer = 0;
        toastTrackName = "";
    }

    void ScanLoadedLumps()
    {
        globalPlaylist.Clear();
        
        CVar formatCVar = CVar.FindCVar("music_player_format");
        int formatFilter = 0;
        if (formatCVar != null)
        {
            formatFilter = formatCVar.GetInt();
        }

        lastFormatFilter = formatFilter;

        for (int i = 0; i < Wads.GetNumLumps(); i++)
        {
            string lumpName = Wads.GetLumpName(i);
            lumpName.MakeUpper();

            string fullPath = Wads.GetLumpFullName(i);
            fullPath.MakeLower();
            int len = fullPath.Length();

            // 1. КАТЕГОРИЯ: КЛАССИЧЕСКИЕ ТРЕКИ И ЗАМЕНЫ ИЗ WAD (Начинаются на D_)
            if (lumpName.Mid(0, 2) == "D_" && lumpName.Length() <= 8 && fullPath.IndexOf("/") == -1)
            {
                if (formatFilter == 1) continue; 

                if (globalPlaylist.Find(lumpName) == globalPlaylist.Size())
                {
                    globalPlaylist.Push(lumpName); 
                }
                continue;
            }

            // 2. КАТЕГОРИЯ: СЛУЧАЙНЫЕ ТРЕКИ ИЗ ЛЮБЫХ PK3 МОДОВ
            if (fullPath.Mid(0, 6) == "music/" && len > 4)
            {
                string shortName = fullPath;
                int lastSlash = shortName.LastIndexOf("/");
                if (lastSlash != -1)
                {
                    shortName = shortName.Mid(lastSlash + 1);
                }
                shortName.MakeLower();

                if (shortName.Mid(0, 2) == "o_")
                {
                    continue;
                }

                string ext4 = fullPath.Mid(len - 4);
                string ext5 = fullPath.Mid(len - 5);

                bool isMidi = (ext4 == ".mid");
                bool isDigital = (ext4 == ".ogg" || ext4 == ".mp3" || ext5 == ".flac");

                if (formatFilter == 1 && !isMidi) continue;       
                if (formatFilter == 2 && !isDigital) continue;    

                if (isMidi || isDigital)
                {
                    if (globalPlaylist.Find(fullPath) == globalPlaylist.Size())
                    {
                        globalPlaylist.Push(fullPath); 
                    }
                }
            }
        }

        if (globalPlaylist.Size() > 0 && currentTrackIndex >= globalPlaylist.Size())
        {
            currentTrackIndex = 0;
        }
    }

    void CheckAndRefreshPlaylist()
    {
        CVar formatCVar = CVar.FindCVar("music_player_format");
        if (formatCVar != null)
        {
            int currentFilter = formatCVar.GetInt();
            if (currentFilter != lastFormatFilter)
            {
                ScanLoadedLumps();
            }
        }
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
        }
        return false;
    }

    override void NetworkProcess(ConsoleEvent e)
    {
        if (e.Name == "msg_mp_next")
        {
            SwitchToNextTrack();
        }
        else if (e.Name == "msg_mp_prev")
        {
            SwitchToPrevTrack();
        }
    }

    override void WorldLoaded(WorldEvent e)
    {
        ScanLoadedLumps();

        if (globalPlaylist.Size() == 0) return;

        S_ChangeMusic("", 0, false); 
        PlayCurrentPlaylistTrack();
    }

    override void WorldTick()
    {
        // Уменьшаем таймер "тоста" каждый тик независимо от задержки переключения плеера
        if (toastTimer > 0)
        {
            toastTimer--;
        }

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
                CheckAndRefreshPlaylist();

                CVar repeatCVar = CVar.FindCVar("music_player_repeat");
                int isRepeat = 0;
                if (repeatCVar != null)
                {
                    isRepeat = repeatCVar.GetInt();
                }

                if (isRepeat == 1)
                {
                    PlayCurrentPlaylistTrack();
                }
                else
                {
                    SwitchToNextTrack();
                }
            }
        }
    }

    void SwitchToNextTrack()
    {
        CheckAndRefreshPlaylist();

        if (globalPlaylist.Size() == 0) return;

        playbackHistory.Push(currentTrackIndex);
        if (playbackHistory.Size() > 50)
        {
            playbackHistory.Delete(0);
        }

        CVar shuffleCVar = CVar.FindCVar("music_player_shuffle");
        int isShuffle = 0;
        if (shuffleCVar != null)
        {
            isShuffle = shuffleCVar.GetInt();
        }

        if (isShuffle == 1)
        {
            currentTrackIndex = Random[MusicRand](0, globalPlaylist.Size() - 1);
        }
        else
        {
            currentTrackIndex++;
            if (currentTrackIndex >= globalPlaylist.Size())
            {
                currentTrackIndex = 0;
            }
        }
        PlayCurrentPlaylistTrack();
    }

    void SwitchToPrevTrack()
    {
        CheckAndRefreshPlaylist();

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
            if (currentTrackIndex < 0)
            {
                currentTrackIndex = globalPlaylist.Size() - 1;
            }
        }
        PlayCurrentPlaylistTrack();
    }

    void PlayCurrentPlaylistTrack()
    {
        if (globalPlaylist.Size() == 0) return;

        string currentTrack = globalPlaylist[currentTrackIndex];

        S_ChangeMusic("", 0, false);

        bool isMidiTrack = false;
        if (currentTrack.IndexOf(".mid") != -1)
        {
            isMidiTrack = true;
        }

        if (isMidiTrack)
        {
            S_ChangeMusic(currentTrack, 0, true); 
        }
        else
        {
            S_ChangeMusic(currentTrack, 0, false); 
        }
        
        justSwitchedDelay = 350; 
        
        string trackName = currentTrack;
        int lastSlash = trackName.LastIndexOf("/");
        if (lastSlash != -1) 
        {
            trackName = trackName.Mid(lastSlash + 1);
        }
        
        // Передаем очищенное имя трека в систему уведомления и запускаем таймер
        toastTrackName = trackName;
        toastTimer = TOAST_DURATION;

        // СТАНДАРТНЫЙ ТЕКСТ ПО ЦЕНТРУ ЭКРАНА ОТКЛЮЧЕН:
        // Строка Console.MidPrint удалена, чтобы работал только красивый тост сверху
    }

    // Финальная очищенная отрисовка тоста без использования флагов выравнивания
    override void RenderOverlay(RenderEvent e)
    {
        if (toastTimer <= 0 || toastTrackName == "") return;

        // Базовое виртуальное разрешение UI
        int baseWidth = 800;
        int baseHeight = 600;

        // Расчет плавного выпадания и скрытия (по 15 тиков на анимацию)
        double yOffset = 0;
        if (toastTimer > TOAST_DURATION - 15) 
        {
            // Плавное выпадание сверху вниз
            yOffset = -50 * (double(toastTimer - (TOAST_DURATION - 15)) / 15.0);
        }
        else if (toastTimer < 15) 
        {
            // Плавный уход обратно вверх
            yOffset = -50 * (1.0 - (double(toastTimer) / 15.0));
        }

        // Формируем итоговый текст для отображения
        string fullMessage = "Now Playing: " .. toastTrackName;

        // Безопасное получение стандартного крупного шрифта Doom
        Font clearFont = Font.GetFont("BIGFONT");
        if (clearFont == null) 
        {
            clearFont = BigFont; 
        }

        // Математическое центрирование: вычисляем левую координату от центра экрана
        int textWidth = clearFont.StringWidth(fullMessage);
        double drawX = (baseWidth / 2.0) - (textWidth / 2.0);
        double drawY = 25 + yOffset;
        
        // Рисуем черную тень текста со смещением (для читаемости на любом фоне)
        Screen.DrawText(clearFont, Font.CR_BLACK, drawX, drawY + 1, fullMessage, 
            DTA_VirtualWidth, baseWidth, 
            DTA_VirtualHeight, baseHeight, 
            DTA_KeepRatio, true);
            
        // Рисуем сам текст золотым цветом
        Screen.DrawText(clearFont, Font.CR_GOLD, drawX, drawY, fullMessage, 
            DTA_VirtualWidth, baseWidth, 
            DTA_VirtualHeight, baseHeight, 
            DTA_KeepRatio, true);
    }

}