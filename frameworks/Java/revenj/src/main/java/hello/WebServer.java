package hello;

import dsl.Boot;
import io.undertow.*;
import io.undertow.util.Headers;
import org.revenj.patterns.ServiceLocator;
import org.xnio.Options;

import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.Properties;

public final class WebServer {

  public static void main(String[] args) throws Exception {
    new WebServer();
  }

  public WebServer() throws ClassNotFoundException, IOException, SQLException {
    InputStream resource = WebServer.class.getResourceAsStream("/revenj.properties");
    Properties props = new Properties();
    props.load(resource);
    String jdbcUrl = props.getProperty("revenj.jdbcUrl");
    ServiceLocator locator = Boot.configure(jdbcUrl, props);
    ThreadContext ctx = new ThreadContext(locator, jdbcUrl);
    Undertow.builder()
        .addHttpListener(Integer.parseInt(props.getProperty("undertow.port")), props.getProperty("undertow.host"))
        .setBufferSize(1024 * 16)
        .setIoThreads(Runtime.getRuntime().availableProcessors() * 3)
        .setSocketOption(Options.BACKLOG, 10000)
        .setServerOption(UndertowOptions.ALWAYS_SET_KEEP_ALIVE, false)
        .setServerOption(UndertowOptions.ALWAYS_SET_DATE, true)
        .setServerOption(UndertowOptions.ENABLE_CONNECTOR_STATISTICS, false)
        .setServerOption(UndertowOptions.RECORD_REQUEST_START_TIME, false)
        .setHandler(Handlers.header(Handlers.path()
            .addPrefixPath("/json", new JsonHandler(ctx))
            .addPrefixPath("/db", new DbHandler(ctx))
            .addPrefixPath("/queries", new QueriesHandler(ctx))
            .addPrefixPath("/fortunes", new FortunesHandler(ctx))
            .addPrefixPath("/updates", new UpdatesHandler(ctx))
            .addPrefixPath("/plaintext", new PlaintextHandler()),
            Headers.SERVER_STRING, "UTOW"))
        .setWorkerThreads(200)
        .build()
        .start();
  }
}
