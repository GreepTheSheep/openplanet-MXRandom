namespace Icons {
    string get_AnimatedHourglass() {
        int index = Time::Stamp % 3;

        switch (index) {
            case 0:
                return Icons::HourglassStart;
            case 1:
                return Icons::HourglassHalf;
            default:
                return Icons::HourglassEnd;
        }
    }
}
