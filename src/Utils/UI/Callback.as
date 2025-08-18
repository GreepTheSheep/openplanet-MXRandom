namespace UI {
    // Callback for map, mappack, and user IDs
    void MXIdCallback(UI::InputTextCallbackData@ data) {
        if (data.EventFlag == UI::InputTextFlags::CallbackAlways) {
            if (data.TextLength > 6) {
                data.DeleteChars(6, data.TextLength - 6);
            }
        } else if (data.EventFlag == UI::InputTextFlags::CallbackCharFilter) {
            if (data.EventChar < 48 || data.EventChar > 57) {
                // character is not a number
                data.EventChar = 0;
            }
        }
    }

    bool added_char;

    // Callback to follow ISO 8601 formatting
    void DateCallback(UI::InputTextCallbackData@ data) {
        if (data.EventFlag == UI::InputTextFlags::CallbackAlways) {
            if (data.TextLength > 10) {
                data.DeleteChars(10, data.TextLength - 10);
            }

            if (added_char) {
                if (data.TextLength == 4 || data.TextLength == 7) {
                    // add "-" after YYYY or MM
                    data.InsertChars(data.TextLength, "-");
                } else {
                    // the user might have pasted a date instead
                    if (data.TextLength >= 5 && data.Text.SubStr(4, 1) != "-") {
                        data.InsertChars(4, "-");
                    }
                    if (data.TextLength >= 8 && data.Text.SubStr(7, 1) != "-") {
                        data.InsertChars(7, "-");
                    }
                }

                added_char = false;
            }
        } else if (data.EventFlag == UI::InputTextFlags::CallbackCharFilter) {
            if (data.EventChar < 48 || data.EventChar > 57) {
                // character is not a number
                data.EventChar = 0;
            } else {
                added_char = true;
            }
        }
    }
}
