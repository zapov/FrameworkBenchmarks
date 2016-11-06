package hello;

import com.dslplatform.json.JsonWriter;
import dsl.FrameworkBench.*;
import dsl.FrameworkBench.repositories.*;
import org.revenj.extensibility.Container;
import org.revenj.patterns.*;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import java.util.concurrent.*;

final class Context {

	public final JsonWriter json;
	public final WorldRepository worlds;
	public final FortuneRepository fortunes;
	public final Connection connection;
	private final ThreadLocalRandom random;
	public final RepositoryBulkReader bulkReader;
	private final World[] buffer = new World[512];
	private final Callable[] callables = new Callable[512];

	public Context(Container container, String jdbcUrl) {
		try {
			Container scope = container.createScope();
			this.connection = DriverManager.getConnection(jdbcUrl);
			connection.setAutoCommit(true);
			scope.registerInstance(connection);
			this.json = new JsonWriter();
			this.random = ThreadLocalRandom.current();
			this.worlds = scope.resolve(WorldRepository.class);
			this.fortunes = scope.resolve(FortuneRepository.class);
			this.bulkReader = scope.resolve(RepositoryBulkReader.class);
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	public int getRandom10k() {
		return random.nextInt(10000) + 1;
	}

	/* bulk loading of worlds. use such pattern for production code */
	@SuppressWarnings("unchecked")
	public World[] loadWorldsFast(final int count) throws IOException {
		bulkReader.reset();
		for (int i = 0; i < count; i++) {
			callables[i] = bulkReader.find(World.class, Integer.toString(getRandom10k()));
		}
		bulkReader.execute();
		try {
			for (int i = 0; i < count; i++) {
				buffer[i] = ((Optional<World>) callables[i].call()).get();
			}
		} catch (Exception e) {
			throw new IOException(e);
		}
		return buffer;
	}

	/* multiple roundtrips loading of worlds. don't write such production code */
	@SuppressWarnings("unchecked")
	public World[] loadWorldsSlow(final int count) throws IOException {
		for (int i = 0; i < count; i++) {
			buffer[i] = worlds.find(getRandom10k(), connection).get();
		}
		return buffer;
	}
}
