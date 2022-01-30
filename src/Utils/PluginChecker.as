// Plugin checker will check for all running plugins on OP
// This will be useful for linking up with the ManiaExchange menu plugin
// Or for banning some plugins during RMC (with of course a prompt)
namespace Plugins
{
    array<Meta::Plugin@> GetAllPlugins()
    {
        return Meta::AllPlugins();
    }

    Meta::Plugin@ GetPlugin(string id)
    {
        return Meta::GetPluginFromID(id);
    }

    bool IsPluginExists(string name)
    {
        Meta::Plugin@ plugin = GetPlugin(name);
        if (plugin is null) return false;
        else return true;
    }

    bool IsPluginRunning(string name)
    {
        array<Meta::Plugin@> allPlugins = GetAllPlugins();
        bool pluginExists = IsPluginExists(name);
        if (!pluginExists) return false;
        for (uint i = 0; i < allPlugins.Length; i++)
        {
            Meta::Plugin@ plugin = allPlugins[i];
            if (plugin.get_ID() == name) return plugin.get_Enabled();
        }
        return false;
    }

    void SetPluginStatus(string name, bool status = true)
    {
        array<Meta::Plugin@> allPlugins = GetAllPlugins();
        for (uint i = 0; i < allPlugins.Length; i++)
        {
            Meta::Plugin@ plugin = allPlugins[i];
            if (plugin.get_ID() == name) {
                if (status) plugin.Enable();
                else plugin.Disable();
            }
        }
    }
}