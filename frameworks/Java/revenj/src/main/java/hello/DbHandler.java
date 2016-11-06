package hello;

import com.dslplatform.json.JsonWriter;
import dsl.FrameworkBench.World;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;

import java.nio.ByteBuffer;
import java.util.Optional;

final class DbHandler implements HttpHandler {

  private final ThreadContext context;

  DbHandler(ThreadContext context) {
    this.context = context;
  }

  @Override
  public void handleRequest(HttpServerExchange exchange) throws Exception {
    if (exchange.isInIoThread()) {
      exchange.dispatch(this);
      return;
    }

    exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, ThreadContext.APP_JSON);
    final Context ctx = context.get();
    final Optional<World> world = ctx.worlds.find(ctx.getRandom10k(), ctx.connection);
    final JsonWriter json = ctx.json;
    world.get().serialize(json, false);
    exchange.getResponseSender().send(ByteBuffer.wrap(json.getByteBuffer(), 0, json.size()));
  }
}
