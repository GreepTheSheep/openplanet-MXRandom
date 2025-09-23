enum LogLevel {
    Error,
    Warn,
    Info,
    Debug,
    Trace
}

namespace Log {
    const vec4 WARN_COLOR    = UI::HSV(0.11, 1.0, 1.0);
    const vec4 ERROR_COLOR   = UI::HSV(1.0, 1.0, 1.0);
    const vec4 LOADING_COLOR = UI::HSV(0.25, 1, 0.7);

    void Trace(const string &in message, bool showNotification = false) {
        if (PluginSettings::LoggingLevel >= LogLevel::Trace) {
            trace("[TRACE] " + message);

            if (showNotification) {
                UI::ShowNotification(PLUGIN_NAME, message);
            }
        }
    }

    void Debug(const string &in message, bool showNotification = false) {
        if (PluginSettings::LoggingLevel >= LogLevel::Debug) {
            trace("[DEBUG] " + message);

            if (showNotification) {
                UI::ShowNotification(PLUGIN_NAME, message);
            }
        }
    }

    void Info(const string &in message, bool showNotification = false) {
        if (PluginSettings::LoggingLevel >= LogLevel::Info) {
            print("[INFO] " + message);

            if (showNotification) {
                UI::ShowNotification(PLUGIN_NAME, message);
            }
        }
    }

    void Warn(const string &in message, bool showNotification = false) {
        if (PluginSettings::LoggingLevel >= LogLevel::Warn) {
            warn("[WARN] " + message);

            if (showNotification) {
                UI::ShowNotification(Icons::Kenney::ExclamationCircle + " " + PLUGIN_NAME + " - Warning", message, WARN_COLOR, 5000);
            }
        }
    }

    void Error(const string &in message, bool showNotification = false) {
        if (PluginSettings::LoggingLevel >= LogLevel::Error) {
            error("[ERROR] " + message);

            if (showNotification) {
                UI::ShowNotification(Icons::Kenney::TimesCircle + " " + PLUGIN_NAME + " - Error", message, ERROR_COLOR, 8000);
            }
        }
    }

    void LoadingMapNotification(MX::MapInfo@ map) {
        Info("Loading map: " + map.Name + " (" + map.MapId + ")");

        UI::ShowNotification(Icons::Kenney::ReloadInverse + " Loading map", map.Name + "\nby: " + map.Username, LOADING_COLOR, 5000);
    }
}