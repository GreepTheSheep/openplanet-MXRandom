class ModalDialog : IRenderable {
	string m_id;
	bool m_firstRender = false;
	bool m_visible = true;

	vec2 m_size = vec2(100, 100);
    int m_flags = UI::WindowFlags::NoSavedSettings | UI::WindowFlags::NoResize | UI::WindowFlags::NoMove;

	ModalDialog(const string &in id)
	{
		m_id = id;
	}

	void Render()
	{
		if (!m_firstRender) {
			UI::OpenPopup(m_id);
		}

		UI::SetNextWindowSize(int(m_size.x), int(m_size.y));

		bool isOpen = false;

		if (CanClose()) {
			isOpen = UI::BeginPopupModal(m_id, m_visible, m_flags);
		} else {
			isOpen = UI::BeginPopupModal(m_id, m_flags);
		}

		if (isOpen) {
			RenderDialog();
			UI::EndPopup();
		}
	}

	bool CanClose()
	{
		return true;
	}

	bool ShouldDisappear()
	{
		return !m_visible;
	}

	void Close()
	{
		m_visible = false;
		UI::CloseCurrentPopup();
	}

	void RenderDialog()
	{
	}
}