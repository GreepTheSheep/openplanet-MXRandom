void RenderMenu()
{
    if(UI::BeginMenu(MX_COLOR_STR+Icons::Random+" \\$z"+SHORT_MX+" Randomizer" + (MX::APIDown ? " \\$f00"+Icons::Server : ""))){
        if (MX::APIDown) {
            if (!MX::APIRefreshing) {
                UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$z"+MX_NAME + " is not responding. It might be down.");
                if (UI::Button("Retry")) {
                    startnew(MX::FetchMapTags);
                }
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::TextDisabled(Hourglass + " Loading...");
            }
        } else {
            if (UI::MenuItem(Icons::Play + " Quick map")) {
                startnew(MX::LoadRandomMap);
            }
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::Text("This will load and play instantly a random map from "+MX_NAME+".");
                UI::EndTooltip();
            }

            if(UI::MenuItem(MX_COLOR_STR+Icons::Random+" \\$zRandomizer Menu", "", window.isOpened)) {
                window.isOpened = !window.isOpened;
            }
            UI::Separator();
            if(UI::MenuItem(MX_COLOR_STR+Icons::Random+" \\$zRandom Map Challenge", "", window.isInRMCMode)) {
                if (window.isInRMCMode) window.isInRMCMode = false;
                else
                {
                    if (!window.isOpened) window.isOpened = true;
                    window.isInRMCMode = true;
                }
            }
        }
        UI::EndMenu();
    }
}

void Main()
{
    // MX::FetchMapTags();
}

void RenderInterface()
{
    Dialogs::RenderInterface();
}

void Render()
{
    window.Render();
}