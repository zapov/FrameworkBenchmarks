package hello;

import com.dslplatform.json.JsonWriter;
import dsl.FrameworkBench.World;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

final class UpdatesHandler implements HttpHandler {

  private final ThreadContext context;

  UpdatesHandler(ThreadContext context) {
    this.context = context;
  }

  private static final Comparator<World> ASC = (l, r) -> l.getId() - r.getId();

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
    final ArrayList<World> changed = new ArrayList<>(count);
    for (int i = 0; i < count; i++) {
      changed.add(worlds[i].setRandomNumber(ctx.getRandom10k()));
    }
    Collections.sort(changed, ASC);
    ctx.worlds.update(changed);
    json.serialize(worlds, count);
    exchange.getResponseSender().send(ByteBuffer.wrap(json.getByteBuffer(), 0, json.size()));
  }
}
