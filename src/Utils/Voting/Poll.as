class Poll {
    array<array<string>> m_votes;
    uint64 m_startTime;
    uint m_duration;
    dictionary m_voters;
    bool m_started;

    Poll(int optionsCount, uint duration = PluginSettings::RMC_PollDuration) {
        m_votes.Resize(optionsCount);
        m_duration = duration;
    }

    void VotesLoop() { }

    void Start() {
        m_started = true;
        m_startTime = Time::Now;
        startnew(CoroutineFunc(VotesLoop));
        Log::Trace("[Poll::Start] Starting poll...");
        Log::Debug("[Poll::Start] Options: " + m_votes.Length + ". Duration: " + m_duration + "s.");
    }

    bool get_HasEnded() {
        return m_started && Time::Now >= m_startTime + Duration;
    }

    uint get_TimeLeft() {
        return Math::Max(0, m_startTime + Duration - Time::Now);
    }

    bool get_HasStarted() {
        return m_started;
    }

    uint get_Duration() {
        return m_duration * 1000;
    }

    uint get_StartedAt() {
        return m_startTime;
    }

    uint get_OptionsCount() {
        return m_votes.Length;
    }

    uint VoteCount() {
        return m_voters.GetSize();
    }

    uint OptionVoteCount(uint index) {
        if (index >= m_votes.Length) {
            return 0;
        }

        return m_votes[index].Length;
    }

    int get_Winner() {
        if (!HasStarted || !HasEnded) {
            return -1;
        }

        if (m_voters.IsEmpty()) {
            return -1;
        }

        int index = -1;
        uint winnerCount = 0;

        for (uint i = 0; i < m_votes.Length; i++) {
            if (m_votes[i].Length > winnerCount) {
                index = i;
                winnerCount = m_votes[i].Length;
            }
        }

        return index;
    }

    void VotesTooltip(uint index) {
        if (index >= m_votes.Length) {
            return;
        }

        if (UI::IsItemHovered(UI::HoveredFlags::DelayShort)) {
            UI::BeginTooltip();

            if (m_votes[index].IsEmpty()) {
                UI::Text("None");
            } else {
                for (int i = 0; i < Math::Min(m_votes[index].Length, 5); i++) {
                    UI::Text(m_votes[index][i]);
                }

                if (m_votes[index].Length > 5) {
                    UI::Text("and " + (m_votes[index].Length - 5) + " more");
                }
            }

            UI::EndTooltip();
        }
    }

    bool HasTied() {
        if (m_votes.Length < 2 || m_voters.GetSize() == 1) {
            return false;
        }

        if (m_voters.IsEmpty()) {
            return true;
        }

        array<int> optionsCounts;

        for (uint i = 0; i < m_votes.Length; i++) {
            optionsCounts.InsertLast(m_votes[i].Length);
        }

        optionsCounts.SortDesc();

        return optionsCounts[0] == optionsCounts[1];
    }

    array<int> GetTiedOptions() {
        array<int> indexes;
        uint highestCount = 0;

        for (uint i = 0; i < m_votes.Length; i++) {
            if (m_votes[i].Length > highestCount) {
                indexes.RemoveRange(0, indexes.Length);
                indexes.InsertLast(i);
                highestCount = m_votes[i].Length;
            } else if (m_votes[i].Length == highestCount) {
                indexes.InsertLast(i);
            }
        }

        return indexes;
    }

    void AddVote(string _message, const string &in user) {

        _message = _message.Trim();

        if (_message == "" || _message.Length > 1 || user == "") {
            return;
        }

        uint vote = 0;

        if (!Text::TryParseUInt(_message, vote) || vote < 1 || vote > m_votes.Length) {
            return;
        }

        Log::Trace("[Poll::AddVote] Adding vote to poll");
        Log::Debug("[Poll::AddVote] Message " + _message + ". User: " + user);

        int64 oldVote = -1;

        // If already voted, remove their old vote
        if (m_voters.Get(user, oldVote)) {
            if (oldVote < 1 || oldVote > int(m_votes.Length)) {
                Log::Warn("Invalid old poll vote " + oldVote + " for user \"" + user + "\". Ignoring...");
            } else {
                int index = m_votes[oldVote - 1].Find(user);

                if (index > -1) {
                    m_votes[oldVote - 1].RemoveAt(index);
                }
            }
        }

        m_votes[vote - 1].InsertLast(user);
        m_voters.Set(user, vote);

        if (m_votes[vote - 1].Length > 1) {
            m_votes[vote - 1].Sort(function(a, b) {
                return a.ToLower() < b.ToLower();
            });
        }
    }
}
