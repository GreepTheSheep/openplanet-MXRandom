// Plugin checker will check for all running plugins on OP
// This will be useful for banning some plugins during RMC (with of course a prompt)
namespace Plugins {
    bool IsPluginRunning(const string &in id) {
        Meta::Plugin@ plugin = Meta::GetPluginFromID(id);
        if (plugin is null) {
            return false;
        }

        return plugin.Enabled;
    }

    void SetPluginStatus(const string &in id, bool status = true) {
        Meta::Plugin@ plugin = Meta::GetPluginFromID(id);
        if (plugin is null || plugin.Essential) return;

        plugin.Enabled = status;
    }
}