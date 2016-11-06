package hello;

import com.dslplatform.json.JsonWriter;
import dsl.FrameworkBench.World;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;

import java.nio.ByteBuffer;

final class QueriesHandler implements HttpHandler {

  private final ThreadContext context;

  QueriesHandler(ThreadContext context) {
    this.context = context;
  }

  @Override
  public void handleRequest(HttpServerExchange exchange) throws Exception {
    if (exchange.isInIoThread()) {
      exchange.dispatch(this);
      return;
    }

    exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, ThreadContext.APP_JSON);
    final int count = ThreadContext.parseBoundParam(exchange);
    final Context ctx = context.get();
    final JsonWriter json = ctx.json;
    final World[] worlds = ctx.loadWorldsSlow(count);
    json.serialize(worlds, count);
    exchange.getResponseSender().send(ByteBuffer.wrap(json.getByteBuffer(), 0, json.size()));
  }
}
