namespace DebugView {
    void RenderRunData() {
        if (RMC::currentRun is null) {
            UI::Text("No RMC run available.");
            return;
        }

        RMC@ run = RMC::currentRun;

        if (UI::CollapsingHeader("General")) {
            UI::Text("Mode: " + tostring(run.Mode));

            if (run.RunConfig !is null) {
                UI::Text("Goal medal: " + tostring(run.RunConfig.GoalMedal));
                UI::Text("Category: " + tostring(run.RunConfig.Category));
            }
        }

        if (UI::CollapsingHeader("Status")) {
            UI::Text("Inited: " + run.IsInited);
            UI::Text("Paused: " + run.IsPaused);
            UI::Text("Running: " + run.IsRunning);
            UI::Text("Starting: " + run.IsStarting);
            UI::Text("Switching map: " + run.IsSwitchingMap);
        }

        if (UI::CollapsingHeader("Medals")) {
            UI::Text("Goal medals: " + run.GoalMedalCount);
            UI::Text("Got goal medal: " + run.GotGoalMedal);

            if (run.Mode == RMC::GameMode::Challenge) {
                UI::Text("Below medal count: " + run.BelowMedalCount);
                UI::Text("Got below medal: " + run.GotBelowMedal);
                UI::Text("Free skips used: " + run.FreeSkipsUsed);
            } else if (run.Mode == RMC::GameMode::Survival) {
                UI::Text("Skips: " + run.BelowMedalCount);
            }

            if (run.currentMap !is null) {
                UI::Text("Goal time: " + UI::FormatTime(run.GoalTime, run.currentMap.Type));

                if (run.ModeHasBelowMedal) {
                    UI::Text("Below goal time: " + UI::FormatTime(run.BelowGoalTime, run.currentMap.Type));
                }
            }
        }

        if (UI::CollapsingHeader("Maps")) {
            UI::Text("Current map: " + (run.currentMap is null ? "None" : run.currentMap.toString()));
            UI::Text("Next map: " + (run.nextMap is null ? "None" : run.nextMap.toString()));
            UI::Text("Played maps count: " + run.playedMaps.Length);

            if (run.currentMap !is null) {
                UI::Text("Time spent on current map: " + run.TimeSpentMap + " (" + Time::Format(run.TimeSpentMap) + ")");
                UI::Text("PB on current map: " + run.PBOnMap + "( " + UI::FormatTime(run.PBOnMap, run.currentMap.Type) + ")");
                UI::Text("Map is invalidated: " + run.IsMapInvalidated);
            }
        }

        if (UI::CollapsingHeader("Timer")) {
            UI::Text("Time limit: " + run.TimeLimit + " (" + Time::Format(run.TimeLimit) + ")");
            UI::Text("Time left: " + run.TimeLeft + " (" + Time::Format(run.TimeLeft) + ")");
            UI::Text("Total Time: " + run.TotalTime + " (" + Time::Format(run.TotalTime) + ")");
        }

        if (UI::CollapsingHeader("Other")) {
            UI::Text("ContinueSavedRun: " + run.ContinueSavedRun);
            UI::Text("CancelledRun: " + run.CancelledRun);
            UI::Text("UnpauseOnExit: " + run.UnpauseOnExit);
            UI::Text("UserEndedRun: " + run.UserEndedRun);
            UI::Text("ModeHasBelowMedal: " + run.ModeHasBelowMedal);
            UI::Text("RenderButtons: " + run.RenderButtons);
            UI::Text("IsRunValid: " + run.IsRunValid);
        }
    }

    void RenderRunSettings() {
        if (RMC::currentRun is null) {
            UI::Text("No RMC run available.");
            return;
        }

        if (RMC::currentRun.RunConfig is null) {
            UI::Text("No run settings available");
            return;
        }

        UI::InputTextMultiline("##SettingsJson", Json::Write(RMC::currentRun.RunConfig.ToJson(), true), UI::GetContentRegionAvail(), UI::InputTextFlags::ReadOnly);
    }

    void RenderRunMaps() {
        if (RMC::currentRun is null) {
            UI::Text("No RMC run available");
            return;
        }

        if (RMC::currentRun.playedMaps.IsEmpty()) {
            UI::Text("No played maps");
            return;
        }

        array<MX::MapInfo@> maps = RMC::currentRun.playedMaps;

        if (UI::BeginTable("RunMaps", 4, UI::TableFlags::RowBg)) {
            UI::TableSetupScrollFreeze(0, 1);

            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Played At", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
            UI::TableHeadersRow();

            UI::ListClipper clipper(maps.Length);

            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < Math::Min(clipper.DisplayEnd, maps.Length); i++) {
                    UI::TableNextRow();
                    MX::MapInfo@ map = maps[i];

                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();
                    UI::Text(map.Name);

                    UI::TableNextColumn();
                    UI::Text(map.Username);

                    UI::TableNextColumn();
                    UI::Text(Time::FormatString("%F %T", map.PlayedAt));

                    UI::TableNextColumn();
                    for (uint j = 0; j < map.Tags.Length; j++) {
                        Render::MapTag(map.Tags[j]);
                        UI::SameLine();
                    }
                }
            }

            UI::EndTable();
        }
    }
}
