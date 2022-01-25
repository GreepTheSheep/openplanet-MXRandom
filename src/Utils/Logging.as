namespace Log
{
    void Log(string&in message, bool showNotification = false)
    {
        print(message);
        if (showNotification)
        {
            UI::ShowNotification(message);
        }
    }

    void Trace(string&in message, bool showNotification = false)
    {
        trace(message);
        if (showNotification)
        {
            UI::ShowNotification(message);
        }
    }

    void Warn(string&in message, bool showNotification = false)
    {
        warn(message);
        if (showNotification)
        {
            UI::ShowNotification(message);
        }
    }

    void Error(string&in message, bool showNotification = false)
    {
        error(message);
        if (showNotification)
        {
            UI::ShowNotification(message);
        }
    }
}