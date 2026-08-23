#if TMNEXT && DEPENDENCY_BETTERCHAT
class ChatMessage {
    string Text;
    string Login;
    string Username;
    uint64 ReceivedAt;

    ChatMessage(NGameScriptChat_SEntry@ message) {
        Text = message.Text;
        Login = message.SenderLogin;
        Username = message.SenderDisplayName;
        ReceivedAt = Time::Now;
    }
}

namespace Chat {
    MessageListener@ g_messagesListener;
    array<ChatMessage@> g_messages;
    array<ChatMessage@> g_newMessages;

    class MessageListener : BetterChat::IChatMessageListener {
        void OnChatMessage(NGameScriptChat_SEntry@ entry) {
            try {
                if (entry is null || entry.ChatScope != EChatScope::ToEveryone || entry.IsSystemMessage) {
                    return;
                }

                ChatMessage@ newMessage = ChatMessage(entry);

                if (newMessage.Text == "" || newMessage.Login == "" || newMessage.Username == "") {
                    return;
                }

                g_messages.InsertLast(newMessage);
                g_newMessages.InsertLast(newMessage);
            } catch {
                Log::Error("An error occurred while parsing chat messages: " + getExceptionInfo());
            }
        }
    }

    array<ChatMessage@> GetNewMessages() {
        array<ChatMessage@> new = g_newMessages;
        g_newMessages.RemoveRange(0, g_newMessages.Length);

        return new;
    }

    array<ChatMessage@> GetAllMessages() {
        return g_messages;
    }

    void RegisterChatListener() {
        if (g_messagesListener is null) {
            @g_messagesListener = MessageListener();
        }

        BetterChat::RegisterListener(g_messagesListener);
    }

    void UnregisterChatListener() {
        if (g_messagesListener !is null) {
            BetterChat::UnregisterListener(g_messagesListener);
        }
    }
}
#endif
