package hello;

import com.dslplatform.json.JsonWriter;
import dsl.FrameworkBench.Message;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;

import java.nio.ByteBuffer;

final class JsonHandler implements HttpHandler {

  private final ThreadContext context;

  JsonHandler(ThreadContext context) {
    this.context = context;
  }

  @Override
  public void handleRequest(HttpServerExchange exchange) throws Exception {
    exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, "application/json");
    final Message msg = new Message("Hello, World!");
    final JsonWriter writer = context.get().json;
    msg.serialize(writer, false);
    exchange.getResponseSender().send(ByteBuffer.wrap(writer.getByteBuffer(), 0, writer.size()));
  }
}
