#if DEPENDENCY_TWITCHBASE
uint g_twitchId = 0;

class TwitchPoll : Poll {
    TwitchPoll(int optionsCount, int duration = PluginSettings::RMC_PollDuration) {
        super(optionsCount, duration);
    }

    void VotesLoop() override {
        while (!HasEnded) {
            yield();

            if (g_twitchId == 0) {
                g_twitchId = Twitch::Register(Twitch::MessageType::ChatMessage);
            }

            array<Twitch::Message@> newMessages = Twitch::Fetch(g_twitchId);

            for (uint i = 0; i < newMessages.Length; i++) {
                if (newMessages[i].m_receivedAt < m_startTime) {
                    continue;
                }

                // Ignore replies
                if (newMessages[i].m_tags.Exists("reply-parent-msg-id")) {
                    continue;
                }

                string badges = "";

                // Ignore bots, even if not all of them use the badge
                if (newMessages[i].m_tags.Get("badges", badges) && badges.Contains("bot-badge")) {
                    continue;
                }

                string sub = "";

                if (PluginSettings::RMC_TwitchSubsOnly && !badges.Contains("broadcaster") && newMessages[i].m_tags.Get("subscriber", sub) && sub == "0") {
                    continue;
                }

                AddVote(newMessages[i].m_text, newMessages[i].m_username);
            }

            sleep(250);
        }
    }
}
#endif
