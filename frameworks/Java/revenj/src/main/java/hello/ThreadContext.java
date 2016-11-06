package hello;

import io.undertow.server.HttpServerExchange;
import org.revenj.extensibility.Container;
import org.revenj.patterns.ServiceLocator;

import java.io.IOException;
import java.util.Deque;

final class ThreadContext {

	private final ServiceLocator locator;
	private final String jdbcUrl;

	ThreadContext(ServiceLocator locator, String jdbcUrl) {
		this.locator = locator;
		this.jdbcUrl = jdbcUrl;
	}

	private final ThreadLocal<Context> threadContext = new ThreadLocal<Context>() {
		@Override
		protected Context initialValue() {
			return new Context(locator.resolve(Container.class), jdbcUrl);
		}
	};

	static final String APP_JSON = "application/json";

	Context get() throws IOException {
		Context ctx = threadContext.get();
		ctx.json.reset();
		return ctx;
	}

	static int parseBoundParam(HttpServerExchange exchange) {
		Deque<String> values = exchange.getQueryParameters().get("queries");
		if (values == null) {
			return 1;
		}
		String textValue = values.peekFirst();
		if (textValue == null) {
			return 1;
		}
		int count = 1;
		try {
			count = Integer.parseInt(textValue);
			if (count > 500) {
				count = 500;
			} else if (count < 1) {
				count = 1;
			}
		} catch (NumberFormatException ignore) {
		}
		return count;
	}
}
