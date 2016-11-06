package hello;

import com.github.sviperll.text.Renderable;
import com.github.sviperll.text.Renderer;
import com.github.sviperll.text.formats.Html;
import dsl.FrameworkBench.Fortune;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;

import java.io.StringWriter;
import java.nio.charset.Charset;
import java.util.*;

final class FortunesHandler implements HttpHandler {

	private static final Comparator<Fortune> COMPARATOR = (o1, o2) -> o1.getMessage().compareTo(o2.getMessage());
	private static final Charset UTF8 = Charset.forName("UTF-8");

	private final ThreadContext context;

	FortunesHandler(ThreadContext context) {
		this.context = context;
	}

	@Override
	public void handleRequest(HttpServerExchange exchange) throws Exception {
		if (exchange.isInIoThread()) {
			exchange.dispatch(this);
			return;
		}

		final List<Fortune> fortunes = context.get().fortunes.search();
		fortunes.add(new Fortune(0, "Additional fortune added at request time."));
		Collections.sort(fortunes, COMPARATOR);

		exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, "text/html; charset=UTF-8");
		StringWriter sw = new StringWriter();
		Renderable<Html> renderable = new hello.FortunesAdapter(new MustacheFortunes(fortunes));
		Renderer renderer = renderable.createRenderer(sw);
		renderer.render();
		exchange.getResponseSender().send(sw.toString(), UTF8);
	}
}
