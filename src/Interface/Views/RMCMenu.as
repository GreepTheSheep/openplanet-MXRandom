namespace RMC
{

    bool autodetectError = false;
    string autodetectStatus = "";

    void RenderRMCMenu()
    {
#if TMNEXT
        if (Permissions::PlayLocalMap()) {
#endif
            if (UI::GreenButton(Icons::ClockO + " Start Random Map Challenge")){
                selectedGameMode = GameMode::Challenge;
                startnew(Start);
            }
            if (UI::GreenButton(Icons::Heart + " Start Random Map Survival")){
                selectedGameMode = GameMode::Survival;
                startnew(Start);
            }
            UI::AlignTextToFramePadding();
            UI::Text("Goal:");
            UI::SameLine();
            UI::SetNextItemWidth(150);
            if (UI::BeginCombo("##GoalMedalObjectiveMode", PluginSettings::RMC_GoalMedal)){
                for (uint i = 0; i < RMC::Medals.Length; i++) {
                    string goalMedal = RMC::Medals[i];

                    if (UI::Selectable(goalMedal, PluginSettings::RMC_GoalMedal == goalMedal)) {
                        PluginSettings::RMC_GoalMedal = goalMedal;
                    }

                    if (PluginSettings::RMC_GoalMedal == goalMedal) {
                        UI::SetItemDefaultFocus();
                    }
                }
                UI::EndCombo();
            }
#if TMNEXT
            if (UI::TreeNode("\\$f50" + Icons::Fire + " \\$zChaos Mode")) {
#if DEPENDENCY_CHAOSMODE
                if (UI::RedButton(Icons::Fire + " Start RMC with Chaos Mode")){
                    selectedGameMode = GameMode::ChallengeChaos;
                    ChaosMode::SetRMCMode(true);
                    startnew(Start);
                }
                if (UI::RedButton(Icons::Fire + " Start RMS with Chaos Mode")){
                    selectedGameMode = GameMode::SurvivalChaos;
                    ChaosMode::SetRMCMode(true);
                    startnew(Start);
                }
#else
                if (UI::RedButton(Icons::Fire + " Chaos Mode")){
                    Renderables::Add(ChaosModeIntroModalDialog());
                }
#endif
                UI::TreePop();
            }
#endif
            if (UI::TreeNode(MX_COLOR_STR + Icons::Trophy + " \\$zObjective Mode")) {
                UI::TextDisabled(Icons::InfoCircle + " Hover for infos");
                UI::SetPreviousTooltip("Set a goal, and get it done as quickly as possible!\nSkips are unlimited but costs you time spending on the map.");
                UI::AlignTextToFramePadding();
                UI::Text("Goal:");
                UI::SameLine();
                UI::SetNextItemWidth(150);
                PluginSettings::RMC_ObjectiveMode_Goal = UI::InputInt("##ObjectiveMedals", PluginSettings::RMC_ObjectiveMode_Goal);
                if (PluginSettings::RMC_ObjectiveMode_Goal < 1)
                    PluginSettings::RMC_ObjectiveMode_Goal = 1;

                if (UI::GreenButton(Icons::Trophy + " Start Random Map Objective")){
                    selectedGameMode = GameMode::Objective;
                    startnew(Start);
                }
                if (UI::Button(Icons::Table + " Objective Mode Standings"))
                    OpenBrowserURL("https://www.speedrun.com/tmce#Flinks_Random_Map_Challenge");
                UI::TreePop();
            }
#if TMNEXT
            if (Permissions::CreateActivity() && UI::TreeNode(MX_COLOR_STR + Icons::Users + " \\$zRandom Map Together")) {
#if !DEPENDENCY_NADEOSERVICES
                UI::Text(Icons::ExclamationTriangle + " NadeoServices dependency not found, your Openplanet installation may be corrupt!");
                UI::SetPreviousTooltip("RMT needs NadeoServices dependency (shipped with Openplanet) in order to send events to a room.");
#endif
#if !DEPENDENCY_MLHOOK
                UI::Text(Icons::ExclamationTriangle + " MLHook dependency not found, please enable or install \"MLHook & Event Inspector\" from the Plugin Manager.");
                UI::SetPreviousTooltip("RMT needs MLHook and MLFeed dependencies (by XertroV) in order to catch correctly the best times of other players on a room");
#endif
#if !DEPENDENCY_MLFEEDRACEDATA
                UI::Text(Icons::ExclamationTriangle + " MLFeed dependency not found, please enable or install \"MLFeed: Race Data\" from the Plugin Manager.");
                UI::SetPreviousTooltip("RMT needs MLHook and MLFeed dependencies (by XertroV) in order to catch correctly the best times of other players on a room");
#endif
#if !DEPENDENCY_BETTERCHAT
                UI::Text(Icons::ExclamationCircle + " Better Chat plugin not found.");
                UI::SetPreviousTooltip("RMT can use Better Chat plugin (by Miss) in order to send events to other people in game chat. This is optional.");
#endif
#if !DEPENDENCY_BETTERROOMMANAGER
                UI::Text(Icons::ExclamationCircle + " Better Room Manager plugin not found.");
                UI::SetPreviousTooltip("RMT can use Better Room Manager plugin (by XertroV) in order to autodetect Club and Room ID. This is optional.");
#endif
                UI::TextDisabled(Icons::InfoCircle + " Click for help");
                if (UI::IsItemClicked()) {
                    Renderables::Add(RMTHelpModalDialog());
                }
#if DEPENDENCY_NADEOSERVICES && DEPENDENCY_MLHOOK && DEPENDENCY_MLFEEDRACEDATA
#if DEPENDENCY_BETTERROOMMANAGER
                if (BRM::IsInAServer(GetApp())) {
                    UI::BeginDisabled(MXNadeoServicesGlobal::isCheckingRoom);
                    if (UI::Button("Auto-detect Club and Room ID")) {
                        startnew(BRMStartAutoDetectRoomRMT);
                    }
                    UI::EndDisabled();
                    if (autodetectStatus != "" || autodetectStatus == "Done") UI::Text(autodetectStatus);
                    if (autodetectError) UI::Text(MXNadeoServicesGlobal::roomCheckError);
                    if (autodetectStatus == "Done") {
                        autodetectStatus = "";
                        startnew(MXNadeoServicesGlobal::CheckNadeoRoomAsync);
                    }
                }
#endif

                UI::AlignTextToFramePadding();
                UI::Text("Club ID:");
                UI::SameLine();
                UI::SetNextItemWidth(156);
                PluginSettings::RMC_Together_ClubId = Text::ParseInt(UI::InputText("##RMTSetClubID", tostring(PluginSettings::RMC_Together_ClubId), false, UI::InputTextFlags::CharsDecimal));

                UI::AlignTextToFramePadding();
                UI::Text("Room ID:");
                UI::SameLine();
                UI::SetNextItemWidth(150);
                PluginSettings::RMC_Together_RoomId = Text::ParseInt(UI::InputText("##RMTSetRoomID", tostring(PluginSettings::RMC_Together_RoomId), false, UI::InputTextFlags::CharsDecimal));

                bool RMT_isServerOK = false;

                if (PluginSettings::RMC_Together_ClubId > 0 && PluginSettings::RMC_Together_RoomId > 0) {
                    UI::BeginDisabled(MXNadeoServicesGlobal::isCheckingRoom);
                    if (UI::Button("Check Room")) {
                        startnew(MXNadeoServicesGlobal::CheckNadeoRoomAsync);
                    }
                    UI::EndDisabled();
                    if (MXNadeoServicesGlobal::isCheckingRoom) {
                        int HourGlassValue = Time::Stamp % 3;
                        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                        UI::TextDisabled(Hourglass + " Checking...");
                    }
                    if (MXNadeoServicesGlobal::foundRoom !is null) {
                        RMT_isServerOK = true;
                        UI::Text("Room found:");
                        UI::Text("'"+ColoredString(MXNadeoServicesGlobal::foundRoom.name)+"', in club '"+ColoredString(MXNadeoServicesGlobal::foundRoom.clubName)+"'");
                    }
                }
                if (RMT_isServerOK && !TM::IsInServer()) {
                    UI::BeginDisabled();
                    UI::GreyButton(Icons::Users + " Start Random Map Together");
                    UI::Text("\\$a50" + Icons::ExclamationTriangle + " \\$zPlease join the room before continuing");
                    UI::EndDisabled();
                }
                if (RMT_isServerOK && TM::IsInServer() && UI::GreenButton(Icons::Users + " Start Random Map Together")){
                    selectedGameMode = GameMode::Together;
                    startnew(CoroutineFunc(Together.StartRMT));
                }
#endif
                UI::TreePop();
            }
#endif
#if TMNEXT
        } else {
            UI::Text(Icons::TimesCircle + " You have not the permissions to play local maps");
        }
#endif
        UI::Separator();
        if (UI::Button(Icons::Table + " Standings")) {
            OpenBrowserURL("https://docs.google.com/spreadsheets/d/1Byoa0ZIakuhK02n3a5FcTNYIhJksX25tqU455Lg-vkI/edit?usp=sharing");
        }
        UI::SameLine();
        if (UI::PurpleButton(Icons::Cog)) {
            Renderables::Add(RMCSettingsModalDialog());
        }
        UI::SameLine();
        if (UI::IsOverlayShown() && UI::OrangeButton(Icons::Backward + " Go back")) {
            window.isInRMCMode = false;
        }

        if (
            RMC::GoalMedalCount > 0 ||
            Challenge.BelowMedalCount > 0 ||
            Survival.Skips > 0 ||
            Survival.SurvivedTime > 0
        ) {
            if (!UI::IsOverlayShown()) UI::Dummy(vec2(0, 10));
            UI::Separator();
            UI::Text("Last run stats:");
            vec2 pos_orig = UI::GetCursorPos();
            if (selectedGameMode == GameMode::Challenge) {
                Challenge.RenderGoalMedal();
                UI::SetCursorPos(vec2(UI::GetCursorPos().x+50, UI::GetCursorPos().y));
                Challenge.RenderBelowGoalMedal();
            }
            else if (selectedGameMode == GameMode::Survival) {
                Survival.RenderGoalMedal();
                UI::SetCursorPos(vec2(UI::GetCursorPos().x+50, UI::GetCursorPos().y));
                Survival.RenderBelowGoalMedal();
                UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+60));
                UI::Text("Survived time: " + RMC::FormatTimer(Survival.SurvivedTime));
            }
            else if (selectedGameMode == GameMode::Objective) {
                Objective.RenderGoalMedal();
                UI::SetCursorPos(vec2(UI::GetCursorPos().x+50, UI::GetCursorPos().y));
                Objective.RenderBelowGoalMedal();
                UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+60));
                UI::Text("Total time:");
                UI::SameLine();
                UI::PushFont(Objective.TimerFont);
                UI::Text(RMC::FormatTimer(Objective.RunTime));
                UI::PopFont();
            }
#if TMNEXT
            else if (selectedGameMode == GameMode::Together) {
                pos_orig = UI::GetCursorPos();
                Together.RenderGoalMedal();
                UI::SetCursorPos(vec2(pos_orig.x+100, pos_orig.y));
                Together.RenderBelowGoalMedal();
                UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+60));
                Together.RenderScores();
            }
#endif
        }
    }

    void RenderRMCTimer()
    {
        if (selectedGameMode == GameMode::Challenge || selectedGameMode == GameMode::ChallengeChaos) Challenge.Render();
        else if (selectedGameMode == GameMode::Survival || selectedGameMode == GameMode::SurvivalChaos) Survival.Render();
        else if (selectedGameMode == GameMode::Objective) Objective.Render();
        else if (selectedGameMode == GameMode::Together) Together.Render();
    }

    void RenderBaseInfos()
    {
        UI::PushFont(g_fontHeader);
        UI::Text("Random Map Challenge / Survival");
        UI::PopFont();
        UI::TextWrapped("In the Random Map Challenge, you have to grab the maximum number of author medals in 1 hour.");
        UI::TextWrapped("In the Random Map Survival, you have to grab the maximum number of author medals before the timer reaches 0. You gain 3 minutes per medal won, you can skip but you lose 1 minute of your time limit");
        if (UI::GreenButton(Icons::ExternalLink + " More informations")) OpenBrowserURL("https://flinkblog.de/RMC/");
    }

#if DEPENDENCY_BETTERROOMMANAGER
    void BRMStartAutoDetectRoomRMT() {
        MXNadeoServicesGlobal::isCheckingRoom = true;
        autodetectError = false;
        autodetectStatus = "Detecting... ";
        auto cs = BRM::GetCurrentServerInfo(GetApp());
        if (cs is null) {
            MXNadeoServicesGlobal::roomCheckError = "Couldn't get current server info";
            autodetectError = true;
            return;
        }
        if (cs.clubId <= 0) {
            MXNadeoServicesGlobal::roomCheckError = "Could not detect club ID for this server (" + cs.name + " / " + cs.login + ")";
            autodetectError = true;
            return;
        }

        autodetectStatus = "Found Club ID: " + cs.clubId;

        auto myClubs = BRM::GetMyClubs();
        const Json::Value@ foundClub = null;

        for (uint i = 0; i < myClubs.Length; i++) {
            if (cs.clubId == int(myClubs[i]['id'])) {
                @foundClub = myClubs[i];
                break;
            }
        }

        if (foundClub is null) {
            MXNadeoServicesGlobal::roomCheckError = "Club not found in your list of clubs (refresh from Better Room Manager if you joined the club recently).";
            autodetectError = true;
            return;
        }

        if (!bool(foundClub['isAnyAdmin'])) {
            MXNadeoServicesGlobal::roomCheckError = "Club was found but your role isn't enough to edit rooms (refresh from Better Room Manager if this changed recently).";
            autodetectError = true;
            return;
        }

        autodetectStatus = "Checking for matching rooms...";

        if (cs.roomId <= 0) {
            MXNadeoServicesGlobal::roomCheckError = "Room not found in club";
            autodetectError = true;
            return;
        }

        PluginSettings::RMC_Together_ClubId = cs.clubId;
        PluginSettings::RMC_Together_RoomId = cs.roomId;

        autodetectStatus = "Done";
        MXNadeoServicesGlobal::isCheckingRoom = false;
    }
#endif
}