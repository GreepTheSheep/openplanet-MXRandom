#if TMNEXT && DEPENDENCY_BETTERCHAT
class GamePoll : Poll {
    GamePoll(int optionsCount, int duration = PluginSettings::RMC_PollDuration) {
        super(optionsCount, duration);
    }

    void VotesLoop() override {
        while (!HasEnded) {
            yield();

            array<ChatMessage@> messages = Chat::GetNewMessages();

            for (uint i = 0; i < messages.Length; i++) {
                if (messages[i].ReceivedAt < m_startTime) {
                    continue;
                }

                AddVote(messages[i].Text, messages[i].Username);
            }

            sleep(250);
        }
    }
}
#endif
