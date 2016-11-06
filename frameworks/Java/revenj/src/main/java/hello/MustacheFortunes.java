package hello;

import com.github.sviperll.staticmustache.GenerateRenderableAdapter;
import dsl.FrameworkBench.Fortune;

import java.util.List;

@GenerateRenderableAdapter(
	template = "fortunes.mustache",
	adapterName = "FortunesAdapter",
	charset = "UTF-8")
public class MustacheFortunes {
	public final List<Fortune> items;

	public MustacheFortunes(List<Fortune> items) {
		this.items = items;
	}
}
