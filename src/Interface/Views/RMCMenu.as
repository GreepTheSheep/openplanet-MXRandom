namespace RMC {
    void RenderMenu() {
#if TMNEXT
        if (!Permissions::PlayLocalMap()) {
            UI::TextWrapped(Icons::TimesCircle + " You don't have the permissions to play local maps");
            return;
        }
#endif

#if SIG_SCHOOL
        UI::Text("\\$fa0" + Icons::University + " \\$zSchool mode is enabled.");
        if (!Meta::IsSchoolModeWhitelisted()) UI::TextWrapped("\\$f00" + Icons::TimesCircleO + " \\$zRuns won't be submitted.");
        else UI::TextWrapped("\\$0f0" + Icons::CheckCircle + " \\$zSession whitelisted.");
#endif

        RenderCombos();

        RenderGameModeMenu();

        RenderButtons();

        RenderRunStats();
    }

    void RenderCurrentRun() {
        currentRun.Render();
    }

    void RenderCombos() {
        UI::SetItemText("Mode:", -1);
        if (UI::BeginCombo("##GamemodeSelect", tostring(PluginSettings::SelectedGameMode).Replace("_", " "))) {
#if TMNEXT
                for (uint i = 0; i <= GameMode::Together; i++) {
#else
                for (uint i = 0; i <= GameMode::Objective; i++) {
#endif
                UI::PushID("GamemodeButton" + i);

                if (UI::Selectable(tostring(GameMode(i)).Replace("_", " "), PluginSettings::SelectedGameMode == GameMode(i))) {
                    PluginSettings::SelectedGameMode = GameMode(i);
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        UI::SetItemText("Medal:", -1);
        if (UI::BeginCombo("##GoalMedal", tostring(PluginSettings::GoalMedal))) {
            for (uint i = 0; i < Medals::Last; i++) {
                if (UI::Selectable(tostring(Medals(i)), PluginSettings::GoalMedal == Medals(i))) {
                    PluginSettings::GoalMedal = Medals(i);
                }

                if (PluginSettings::GoalMedal == Medals(i)) {
                    UI::SetItemDefaultFocus();
                }
            }

            UI::EndCombo();
        }

        UI::SetItemText("Category:", -1);
        if (UI::BeginCombo("##CategorySelect", tostring(PluginSettings::SelectedCategory).Replace("_", " "))) {

            for (uint i = 0; i <= Category::Custom; i++) {
                UI::PushID("CategoryButton" + i);

                if (UI::Selectable(tostring(Category(i)).Replace("_", " "), PluginSettings::SelectedCategory == Category(i))) {
                    PluginSettings::SelectedCategory = Category(i);
                }

                UI::SetItemTooltip(CategoryDescriptions[i]);

                UI::PopID();
            }

            UI::EndCombo();
        }
    }

    void RenderGameModeMenu() {
        switch (PluginSettings::SelectedGameMode) {
            case GameMode::Challenge:
                if (UI::GreenButton(Icons::ClockO + " Start RMC")) {
                    @currentRun = RMC();
                    startnew(CoroutineFunc(currentRun.Start));
                }

                UI::SameLine();

                if (UI::FlexButton(Icons::Sliders + " Options")) {
                    Renderables::Add(RunSettingsModalDialog());
                }
                break;
            case GameMode::Survival:
                if (UI::GreenButton(Icons::Heart + " Start RMS")) {
                    @currentRun = RMS();
                    startnew(CoroutineFunc(currentRun.Start));
                }
                UI::SameLine();
                if (UI::FlexButton(Icons::Sliders + " Options")) {
                    Renderables::Add(RunSettingsModalDialog());
                }
                break;
            case GameMode::Objective:
                UI::SetItemText("Goal:", -1);
                PluginSettings::RMO_Goal = Math::Max(1, UI::InputInt("##ObjectiveMedals", PluginSettings::RMO_Goal));

                if (UI::GreenButton(Icons::Trophy + " Start RMO")) {
                    @currentRun = RMObjective();
                    startnew(CoroutineFunc(currentRun.Start));
                }
                UI::SameLine();
                if (UI::FlexButton(Icons::Sliders + " Options")) {
                    Renderables::Add(RunSettingsModalDialog());
                }
                break;
#if TMNEXT
            case GameMode::Together:
                if (!Permissions::CreateActivity()) {
                    UI::Text("Missing permission to create club activities");
                } else {
#if !DEPENDENCY_NADEOSERVICES
                    UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zNadeoServices dependency not found.");
                    UI::SetItemTooltip("RMT needs the NadeoServices dependency (shipped with Openplanet) in order to send events to a room.\n\nYour Openplanet installation may be corrupted.");
#endif
#if !DEPENDENCY_MLFEEDRACEDATA
                    UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zMLFeed dependency not found.");
                    UI::SetItemTooltip("RMT needs the MLFeed dependency (by XertroV) in order to catch correctly the best times of other players in a room.\n\nPlease enable or install \"MLFeed: Race Data\" from the Plugin Manager.");
#endif
#if !DEPENDENCY_BETTERCHAT
                    UI::Text(Icons::ExclamationCircle + " Better Chat plugin not found.");
                    UI::SetItemTooltip("RMT can use Better Chat plugin (by Miss) in order to send events to other people in game chat. This is optional.");
#endif
#if !DEPENDENCY_BETTERROOMMANAGER
                    UI::Text(Icons::ExclamationCircle + " Better Room Manager plugin not found.");
                    UI::SetItemTooltip("RMT can use Better Room Manager plugin (by XertroV) in order to autodetect Club and Room ID. This is optional.");
#endif
                }

#if DEPENDENCY_NADEOSERVICES && DEPENDENCY_MLFEEDRACEDATA
#if DEPENDENCY_BETTERROOMMANAGER
                if (BRM::IsInAServer(GetApp())) {
                    UI::BeginDisabled(MXNadeoServicesGlobal::isCheckingRoom);

                    if (UI::Button("Auto-detect Club and Room ID")) {
                        startnew(CoroutineFunc(MXNadeoServicesGlobal::AutoDetectRoom));
                    }

                    UI::EndDisabled();
                }
#endif

                    UI::SetItemText("Club ID:", -1);
                    PluginSettings::RMC_Together_ClubId = Text::ParseInt(UI::InputText("##RMTSetClubID", tostring(PluginSettings::RMC_Together_ClubId), UI::InputTextFlags::CharsDecimal));

                    UI::SetItemText("Room ID:", -1);
                    PluginSettings::RMC_Together_RoomId = Text::ParseInt(UI::InputText("##RMTSetRoomID", tostring(PluginSettings::RMC_Together_RoomId), UI::InputTextFlags::CharsDecimal));

                UI::BeginDisabled(PluginSettings::RMC_Together_ClubId == 0 || PluginSettings::RMC_Together_RoomId == 0 || MXNadeoServicesGlobal::isCheckingRoom);

                if (UI::Button(Icons::Search + " Check room")) {
                    startnew(MXNadeoServicesGlobal::CheckNadeoRoomAsync);
                }

                UI::EndDisabled();

                UI::SameLine();

                if (UI::GreyButton(Icons::QuestionCircle + " Help", vec2(-1, 0))) {
                    Renderables::Add(RMTHelpModalDialog());
                }

                if (MXNadeoServicesGlobal::isCheckingRoom) {
                    UI::TextDisabled(Icons::AnimatedHourglass + " Checking...");
                }

                if (MXNadeoServicesGlobal::foundRoom !is null) {
                    UI::Text("Club: " + Text::OpenplanetFormatCodes(MXNadeoServicesGlobal::foundRoom.clubName));
                    UI::Text("Room: " + Text::OpenplanetFormatCodes(MXNadeoServicesGlobal::foundRoom.name));
    
                    bool inServer = TM::IsInServer();

                    UI::BeginDisabled(!inServer || PluginSettings::MapType != MapTypes::Race);

                    if (UI::GreenButton(Icons::Users + " Start RMT")) {
                        @currentRun = RMT();
                        startnew(CoroutineFunc(currentRun.Start));
                    }

                    UI::EndDisabled();

                    UI::SameLine();

                    if (UI::FlexButton(Icons::Sliders + " Options")) {
                        Renderables::Add(RunSettingsModalDialog());
                    }

                    if (PluginSettings::MapType != MapTypes::Race) {
                        UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zInvalid map type " + tostring(PluginSettings::MapType) + " selected");
                        UI::SetItemTooltip("RMT only works with the \"Race\" map type.\n\nPlease change the setting before continuing.");
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
                Log::Warn("Unknown gamemode " + tostring(PluginSettings::SelectedGameMode) + "selected. Resetting to Challenge game mode.");
                PluginSettings::SelectedGameMode = GameMode::Challenge;
                break;
        }
    }

    void RenderButtons() {
        UI::Separator();

        if (UI::OrangeButton(Icons::WindowMaximize + " Menu")) {
            if (!UI::IsOverlayShown()) {
                UI::ShowOverlay();
            }

            mainMenu.Open();
        }

        UI::SameLine();

#if TMNEXT
        if (UI::Button(Icons::Table)) {
            OpenBrowserURL(PluginSettings::RMC_Leaderboard_Url);
        }
        UI::SetItemTooltip("Leaderboard standings");

        UI::SameLine();
#endif

        if (UI::GreyButton(Icons::Book)) {
            Renderables::Add(RMCRulesModalDialog());
        }
        UI::SetItemTooltip("Rules");

        UI::SameLine();

        if (UI::PurpleButton(Icons::Cog)) {
            if (!UI::IsOverlayShown()) {
                UI::ShowOverlay();
            }

            Meta::OpenSettings();
        }
        UI::SetItemTooltip("Settings");
    }

    void RenderRunStats() {

        if (
            currentRun.GoalMedalCount > 0 ||
            currentRun.BelowMedalCount > 0 ||
            currentRun.TotalTime > 0
        ) {
            UI::Separator();
            UI::Text("Last run stats:");

            currentRun.RenderGoalMedal();
            currentRun.RenderBelowGoalMedal();

            if (currentRun.Mode == GameMode::Survival) {
                UI::AlignTextToFramePadding();
                UI::Text("Survived time: " + RMC::FormatTimer(currentRun.TotalTime));
            } else if (currentRun.Mode == GameMode::Objective) {
                UI::AlignTextToFramePadding();
                UI::Text("Total time: " + RMC::FormatTimer(currentRun.TotalTime));
#if TMNEXT
            } else if (currentRun.Mode == GameMode::Together) {
                RMT@ run = cast<RMT>(currentRun);
                run.RenderScores();
#endif
            }
        }
    }
}