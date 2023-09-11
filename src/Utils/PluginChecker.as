// Plugin checker will check for all running plugins on OP
// This will be useful for banning some plugins during RMC (with of course a prompt)
namespace Plugins
{
    array<Meta::Plugin@> GetAllPlugins()
    {
        return Meta::AllPlugins();
    }

    Meta::Plugin@ GetPlugin(const string &in id)
    {
        return Meta::GetPluginFromID(id);
    }

    bool IsPluginExists(const string &in name)
    {
        Meta::Plugin@ plugin = GetPlugin(name);
        if (plugin is null) return false;
        else return true;
    }

    bool IsPluginRunning(const string &in name)
    {
        array<Meta::Plugin@> allPlugins = GetAllPlugins();
        bool pluginExists = IsPluginExists(name);
        if (!pluginExists) return false;
        for (uint i = 0; i < allPlugins.Length; i++)
        {
            Meta::Plugin@ plugin = allPlugins[i];
            if (plugin.ID == name) return plugin.Enabled;
        }
        return false;
    }

    void SetPluginStatus(const string &in name, bool status = true)
    {
        array<Meta::Plugin@> allPlugins = GetAllPlugins();
        for (uint i = 0; i < allPlugins.Length; i++)
        {
            Meta::Plugin@ plugin = allPlugins[i];
            if (plugin.ID == name) {
                if (status) plugin.Enable();
                else plugin.Disable();
            }
        }
    }
}