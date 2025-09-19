namespace RMC {
    bool autodetectError = false;
    string autodetectStatus = "";

    [Setting hidden]
    GameMode selectedGameMode = GameMode::Challenge;

    void RenderRMCMenu() {
#if TMNEXT
        if (Permissions::PlayLocalMap()) {
#endif

#if SIG_SCHOOL
        UI::Text("\\$fa0" + Icons::University + " \\$zSchool mode is enabled.");
        if (!Meta::IsSchoolModeWhitelisted()) UI::TextWrapped("\\$f00" + Icons::TimesCircleO + " \\$zThe results will not be uploaded to the leaderboard.");
        else UI::TextWrapped("\\$0f0" + Icons::CheckCircle + " \\$zSession whitelisted, results will be uploaded to the leaderboard.");
#endif

            UI::SetItemText("Mode:", 200);
            if (UI::BeginCombo("##GamemodeSelect", tostring(selectedGameMode).Replace("_", " "))) {
#if TMNEXT
                for (uint i = 0; i <= GameMode::Together; i++) {
#else
                for (uint i = 0; i <= GameMode::Objective; i++) {
#endif
                    UI::PushID("GamemodeButton" + i);

                    if (UI::Selectable(tostring(GameMode(i)).Replace("_", " "), selectedGameMode == GameMode(i))) {
                        selectedGameMode = GameMode(i);
                    }

                    UI::PopID();
                }

                UI::EndCombo();
            }

            UI::SetItemText("Medal:", 200);
            if (UI::BeginCombo("##GoalMedal", tostring(PluginSettings::RMC_Medal))) {
                for (uint i = 0; i < Medals::Last; i++) {
                    if (UI::Selectable(tostring(Medals(i)), PluginSettings::RMC_Medal == Medals(i))) {
                        PluginSettings::RMC_Medal = Medals(i);
                    }

                    if (PluginSettings::RMC_Medal == Medals(i)) {
                        UI::SetItemDefaultFocus();
                    }
                }

                UI::EndCombo();
            }

            switch (selectedGameMode) {
                case GameMode::Challenge:
                    if (UI::GreenButton(Icons::ClockO + " Start Random Map Challenge")) {
                        @currentRun = RMC();
                        startnew(CoroutineFunc(currentRun.Start));
                    }
                    break;
                case GameMode::Survival:
                    if (UI::GreenButton(Icons::Heart + " Start Random Map Survival")) {
                        @currentRun = RMS();
                        startnew(CoroutineFunc(currentRun.Start));
                    }
                    break;
                case GameMode::Objective:
                    UI::SetItemText("Goal:", 200);
                    PluginSettings::RMC_ObjectiveMode_Goal = Math::Max(1, UI::InputInt("##ObjectiveMedals", PluginSettings::RMC_ObjectiveMode_Goal));

                    if (UI::GreenButton(Icons::Trophy + " Start Random Map Objective")) {
                        @currentRun = RMObjective();
                        startnew(CoroutineFunc(currentRun.Start));
                    }
                    break;
#if TMNEXT
                case GameMode::Together:
                    if (!Permissions::CreateActivity()) {
                        UI::Text("Missing permission to create club activities");
                    } else {
#if !DEPENDENCY_NADEOSERVICES
                        UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zNadeoServices dependency not found.");
                        UI::SetPreviousTooltip("RMT needs the NadeoServices dependency (shipped with Openplanet) in order to send events to a room.\n\nYour Openplanet installation may be corrupted.");
#endif
#if !DEPENDENCY_MLHOOK
                        UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zMLHook dependency not found.");
                        UI::SetPreviousTooltip("RMT needs MLHook and MLFeed dependencies (by XertroV) in order to catch correctly the best times of other players in a room.\n\nPlease enable or install \"MLHook & Event Inspector\" from the Plugin Manager.");
#endif
#if !DEPENDENCY_MLFEEDRACEDATA
                        UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zMLFeed dependency not found.");
                        UI::SetPreviousTooltip("RMT needs MLHook and MLFeed dependencies (by XertroV) in order to catch correctly the best times of other players in a room.\n\nPlease enable or install \"MLFeed: Race Data\" from the Plugin Manager.");
#endif
#if !DEPENDENCY_BETTERCHAT
                        UI::Text(Icons::ExclamationCircle + " Better Chat plugin not found.");
                        UI::SetPreviousTooltip("RMT can use Better Chat plugin (by Miss) in order to send events to other people in game chat. This is optional.");
#endif
#if !DEPENDENCY_BETTERROOMMANAGER
                        UI::Text(Icons::ExclamationCircle + " Better Room Manager plugin not found.");
                        UI::SetPreviousTooltip("RMT can use Better Room Manager plugin (by XertroV) in order to autodetect Club and Room ID. This is optional.");
#endif
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

                    UI::SetItemText("Club ID:", 200);
                    PluginSettings::RMC_Together_ClubId = Text::ParseInt(UI::InputText("##RMTSetClubID", tostring(PluginSettings::RMC_Together_ClubId), false, UI::InputTextFlags::CharsDecimal));

                    UI::SetItemText("Room ID:", 200);
                    PluginSettings::RMC_Together_RoomId = Text::ParseInt(UI::InputText("##RMTSetRoomID", tostring(PluginSettings::RMC_Together_RoomId), false, UI::InputTextFlags::CharsDecimal));

                    if (PluginSettings::RMC_Together_ClubId > 0 && PluginSettings::RMC_Together_RoomId > 0) {
                        UI::BeginDisabled(MXNadeoServicesGlobal::isCheckingRoom);

                        if (UI::Button(Icons::Search + " Check room")) {
                            startnew(MXNadeoServicesGlobal::CheckNadeoRoomAsync);
                        }

                        UI::EndDisabled();

                        UI::SameLine();

                        if (UI::GreyButton(Icons::QuestionCircle + " Help")) {
                            Renderables::Add(RMTHelpModalDialog());
                        }

                        if (MXNadeoServicesGlobal::isCheckingRoom) {
                            UI::TextDisabled(Icons::AnimatedHourglass + " Checking...");
                        }

                        if (MXNadeoServicesGlobal::foundRoom !is null) {
                            UI::Text("Room found:");
                            UI::Text("'" + Text::OpenplanetFormatCodes(MXNadeoServicesGlobal::foundRoom.name) + "', in club '" + Text::OpenplanetFormatCodes(MXNadeoServicesGlobal::foundRoom.clubName) + "'");
                        }
                    }

                    if (MXNadeoServicesGlobal::foundRoom !is null) {
                        bool inServer = TM::IsInServer();

                        UI::BeginDisabled(!inServer || PluginSettings::MapType != MapTypes::Race);

                        if (UI::GreenButton(Icons::Users + " Start Random Map Together")) {
                            @currentRun = RMT();
                            startnew(CoroutineFunc(currentRun.Start));
                        }

                        UI::EndDisabled();

                        if (PluginSettings::MapType != MapTypes::Race) {
                            UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zInvalid map type " + tostring(PluginSettings::MapType) + " selected");
                            UI::SetPreviousTooltip("RMT only works with the \"Race\" map type.\n\nPlease change the setting before continuing.");
                        }

                        if (!inServer) {
                            if (MXNadeoServicesGlobal::IsJoiningRoom) {
                                UI::Text(Icons::AnimatedHourglass + " Joining room...");
                            } else {
                                UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zJoin the room before continuing.");
#if DEPENDENCY_BETTERROOMMANAGER
                                if (UI::GreenButton(Icons::SignIn + " Join room")) {
                                    startnew(MXNadeoServicesGlobal::JoinRMTRoom);
                                }
#endif
                            }
                        }
                    }
#else
                if (UI::GreyButton(Icons::QuestionCircle + " Help")) {
                    Renderables::Add(RMTHelpModalDialog());
                }
#endif
                break;
#endif
                default:
                    Log::Warn("Unknown gamemode " + tostring(selectedGameMode) + "selected. Resetting to Challenge game mode.");
                    selectedGameMode = GameMode::Challenge;
                    break;
            }
#if TMNEXT
        } else {
            UI::Text(Icons::TimesCircle + " You don't have the permissions to play local maps");
        }
#endif
        UI::Separator();
#if TMNEXT
        if (UI::Button(Icons::Table)) {
            OpenBrowserURL(PluginSettings::RMC_Leaderboard_Url);
        }
        UI::SetPreviousTooltip("Leaderboard standings");

        UI::SameLine();
#endif

        if (UI::PurpleButton(Icons::Cog)) {
            Meta::OpenSettings();
        }
        UI::SetPreviousTooltip("Settings");

        UI::SameLine();

        if (UI::GreyButton(Icons::Book)) {
            Renderables::Add(RMCRulesModalDialog());
        }
        UI::SetPreviousTooltip("Rules");

        UI::SameLine();

        if (UI::OrangeButton(Icons::Backward + " Go back")) {
            if (!UI::IsOverlayShown()) {
                UI::ShowOverlay();
            }

            window.isInRMCMode = false;
        }

        if (
            currentRun.GoalMedalCount > 0 ||
            currentRun.BelowMedalCount > 0 ||
            currentRun.TotalTime > 0
        ) {
            UI::Separator();
            UI::Text("Last run stats:");

            currentRun.RenderGoalMedal();
            currentRun.RenderBelowGoalMedal();

            if (currentRun.GameMode == GameMode::Survival) {
                UI::AlignTextToFramePadding();
                UI::Text("Survived time: " + RMC::FormatTimer(currentRun.TotalTime));
            } else if (currentRun.GameMode == GameMode::Objective) {
                UI::AlignTextToFramePadding();
                UI::Text("Total time: " + RMC::FormatTimer(currentRun.TotalTime));
#if TMNEXT
            } else if (currentRun.GameMode == GameMode::Together) {
                RMT@ run = cast<RMT>(currentRun);
                run.RenderScores();
#endif
            }
        }
    }

    void RenderRMCTimer() {
        currentRun.Render();
    }

    void RenderBaseInfo() {
        UI::PushFont(Fonts::Header);
        UI::Text("Random Map Challenge / Survival");
        UI::PopFont();

        UI::TextWrapped("In the Random Map Challenge, you have to grab the maximum number of author medals in 1 hour.");
        UI::TextWrapped("In the Random Map Survival, you have to grab the maximum number of author medals before the timer reaches 0. You gain 3 minutes per medal won, you can skip but you lose 1 minute of your time limit");

        if (UI::GreenButton(Icons::ExternalLink + " More information")) {
            OpenBrowserURL("https://flinkblog.de/RMC/");
        }
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