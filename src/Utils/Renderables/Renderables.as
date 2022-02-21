interface IRenderable
{
	void Render();
	bool ShouldDisappear();
}

namespace Renderables
{
	array<IRenderable@> g_renderables;

	void Add(IRenderable@ rend)
	{
		g_renderables.InsertLast(rend);
	}

	void Render()
	{
		for (int i = int(g_renderables.Length) - 1; i >= 0; i--) {
			auto rend = g_renderables[i];
			rend.Render();
			if (rend.ShouldDisappear()) {
				g_renderables.RemoveAt(i);
			}
		}
	}
}