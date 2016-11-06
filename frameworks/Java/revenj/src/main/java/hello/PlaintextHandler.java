package hello;

import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;

final class PlaintextHandler implements HttpHandler {
  private static final ByteBuffer buffer = ByteBuffer.wrap("Hello, World!".getBytes(Charset.forName("UTF-8")));

  @Override
  public void handleRequest(HttpServerExchange exchange) throws Exception {
    exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, "text/plain");
    exchange.getResponseSender().send(buffer.duplicate());
  }
}
