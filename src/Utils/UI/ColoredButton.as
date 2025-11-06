namespace UI {
    bool RedButton(const string &in text, vec2 size = vec2()) {
        return ButtonColored(text, 0.0f, 0.6f, 0.6f, size);
    }

    bool GreenButton(const string &in text, vec2 size = vec2()) {
        return ButtonColored(text, 0.33f, 0.6f, 0.6f, size);
    }

    bool OrangeButton(const string &in text, vec2 size = vec2()) {
        return ButtonColored(text, 0.155f, 0.6f, 0.6f, size);
    }

    bool CyanButton(const string &in text, vec2 size = vec2()) {
        return ButtonColored(text, 0.5f, 0.6f, 0.6f, size);
    }

    bool PurpleButton(const string &in text, vec2 size = vec2()) {
        return ButtonColored(text, 0.8f, 0.6f, 0.6f, size);
    }

    bool RoseButton(const string &in text, vec2 size = vec2()) {
        return ButtonColored(text, 0.9f, 0.6f, 0.6f, size);
    }

    bool GreyButton(const string &in text, vec2 size = vec2()) {
        return ButtonColored(text, 0.0f, 0.0f, 0.4f, size);
    }
}