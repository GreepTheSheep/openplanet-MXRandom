const vec2 VOTE_COUNT_SIZE = vec2(THUMBNAIL_SIZE.x, 40);
const vec2 VOTE_PREVIEW_SIZE = vec2(150, 40);

class PollPicksModalDialog : PicksModalDialog {
    Poll@ m_picksPoll;
    bool m_tied;
    bool m_closing;

    PollPicksModalDialog(array<MX::MapInfo@> maps, Poll@ poll) {
        super(maps);
        m_size.y = 450;

        @m_picksPoll = poll;
        @RMC::currentPoll = this;

        startnew(CoroutineFunc(MainLoop));
    }

    bool CanPickMap() override {
        return false;
    }

    bool CanClose() override {
        return m_picksPoll.HasStarted;
    }

    bool get_HasStarted() override {
        return m_picksPoll.HasStarted;
    }

    vec2 get_VoteCountSize()   { return VOTE_COUNT_SIZE * UI::GetScale(); }
    vec2 get_VotePreviewSize() { return VOTE_PREVIEW_SIZE * UI::GetScale(); }

    void RenderMapGrid() override {
        PicksModalDialog::RenderMapGrid();

        UI::PushStyleVar(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(0, LineSpacing / 2));
        RenderVoteCounts(VoteCountSize);
        UI::PopStyleVar();
    }

    void MainLoop() {
        while (!m_picksPoll.HasEnded) {
            yield();
        }

        if (m_picksPoll.HasTied()) {
            m_tied = true;
            PickRandomWinner();
            sleep(1000); // wait 1 sec so it doesn't instantly show the "Map has been picked" text after switching the random winner
        } else {
            @picked = options[m_picksPoll.Winner];
        }

        m_closing = true;
        sleep(3000); // wait 3 secs so the text can be read before closing the dialog
        HasPicked = true;
    }

    void RenderVoteCounts(vec2 cardSize) {
        UI::TableNextRow();

        auto dl = UI::GetWindowDrawList();

        for (uint i = 0; i < options.Length; i++) {
            UI::TableNextColumn();

            vec2 pos = UI::GetCursorScreenPos();
            UI::Dummy(cardSize);
            m_picksPoll.VotesTooltip(i);

            dl.AddRectFilled(vec4(pos, cardSize), BG_GREY);

            uint voteCount = m_picksPoll.OptionVoteCount(i);
            string voteText = Icons::Users + " " + voteCount + " " + Pluralize("vote", voteCount);
            vec2 voteSize = UI::MeasureString(voteText, null, TextSize, WrapSize);

            vec2 textCardPos = (cardSize - voteSize) / 2;
            vec2 textPosition = pos + textCardPos;

            dl.AddText(textPosition, TEXT_GREY, voteText, null, TextSize, WrapSize);
        }
    }

    void RenderBottomText() {
        if (m_closing) {
            if (m_tied) {
                UI::CenteredText(Icons::Map + " Map " + (options.Find(picked) + 1) + " has been picked randomly");
            } else {
                float winningPercentage = float(m_picksPoll.OptionVoteCount(m_picksPoll.Winner)) / float(m_picksPoll.VoteCount()) * 100;
                UI::CenteredText(Icons::Map + " Map " + (m_picksPoll.Winner + 1) + " has won with " + Text::Format("%.1f", winningPercentage) + "% of the votes");
            }
        } else if (m_tied) {
            UI::CenteredText(Icons::AnimatedHourglass + " Poll is tied! Picking a random map...");
        }
    }

    void RenderFooter() override {
        if (!m_picksPoll.HasStarted) {
            if (UI::CenteredButton("Start Poll", 0.33f)) {
                m_picksPoll.Start();
            }
        } else if (!m_picksPoll.HasEnded) {
            DrawProgressBar();
            UI::CenteredText(tostring(m_picksPoll.TimeLeft / 1000) + " " + Pluralize("second", m_picksPoll.TimeLeft / 1000) + " left");
        } else {
            RenderBottomText();
        }
    }

    void DrawProgressBar() {
        float progress = float(m_picksPoll.TimeLeft) / m_picksPoll.Duration;

        UI::PushStyleColor(UI::Col::PlotHistogram, LINE_GREEN); // from the Imgui source code
        UI::ProgressBar(progress, vec2(-1, 5));
        UI::PopStyleColor();
    }

    void PickRandomWinner() {
        array<int> tiedOptions = m_picksPoll.GetTiedOptions();
        int winner = tiedOptions[Math::Rand(0, tiedOptions.Length)];

        if (!PluginSettings::RMC_FastRandomizer) {
            int maxSteps = (((50 + tiedOptions.Length - 1) / tiedOptions.Length) * tiedOptions.Length) + tiedOptions.Find(winner);
            uint start = Time::Now;
            int lastStep = 0;
            int currentPicked = tiedOptions[0];

            while (Time::Now < start + (10 * 1000)) {
                yield();

                // User might have enabled it while we already started the animation
                if (PluginSettings::RMC_FastRandomizer) {
                    break;
                }

                float left = float(Time::Now - start) / (10 * 1000);

                float eased = 1. - (1. - left) * (1. - left);

                int step = int(eased * maxSteps);

                if (step != lastStep) {
                    lastStep = step;

                    if (tiedOptions.Find(currentPicked) >= int(tiedOptions.Length - 1)) {
                        currentPicked = 0;
                    } else {
                        currentPicked = tiedOptions[tiedOptions.Find(currentPicked) + 1];
                    }

                    @picked = options[currentPicked];
                }
            }
        }

        @picked = options[winner];
    }

    void RenderPreview() {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).y;
        int previewWidth = int((VOTE_PREVIEW_SIZE.x * m_picksPoll.OptionsCount)) + 50;

        UI::PushStyleColor(UI::Col::WindowBg, vec4(.1, .1, .1, 1));

        UI::SetNextWindowPos(int(Display::GetWidth() / UI::GetScale() / 2), 0, UI::Cond::Always, .5);
        UI::SetNextWindowSize(previewWidth, 110, UI::Cond::Always);

        UI::Begin("PoolPreview", UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoResize | UI::WindowFlags::NoMove | UI::WindowFlags::NoScrollbar);

        UI::PushFontSize(20);
        vec2 openButton = UI::MeasureButton("Open");
        UI::PopFontSize();

        if (!m_picksPoll.HasEnded) {
            DrawProgressBar();

            if (UI::BeginTable("MapGrid", m_picksPoll.OptionsCount, UI::TableFlags::SizingStretchSame)) {
                RenderVoteCounts(VotePreviewSize);
                UI::EndTable();
            }
        } else {
            UI::PushFontSize(20);

            vec2 textDimensions = UI::MeasureString(Icons::Map + " Text");
            vec2 region = UI::GetContentRegionAvail();

            UI::VPadding(int((region.y - textDimensions.y - openButton.y - (itemSpacing * 2)) / 2));

            RenderBottomText();

            UI::PopFontSize();
        }


        vec2 region = UI::GetContentRegionAvail();

        UI::VPadding(int(region.y - openButton.y - itemSpacing));

        UI::PushFontSize(20);

        if (UI::CenteredButton("Open")) {
            Open();
            Renderables::Add(this);
        }

        UI::PopFontSize();

        UI::End();
        UI::PopStyleColor();
    }
}
