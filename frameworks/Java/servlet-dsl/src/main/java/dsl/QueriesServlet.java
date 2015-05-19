package dsl;

import com.dslplatform.client.json.JsonWriter;
import dsl.Bench.World;

import javax.annotation.Resource;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Random;
import java.util.concurrent.ThreadLocalRandom;

public class QueriesServlet extends HttpServlet {
	@Resource(name = "jdbc/data_source")
	private DataSource dataSource;

	@Override
	protected void doGet(final HttpServletRequest req, final HttpServletResponse res) throws ServletException, IOException {
		int count = 1;
		try {
			count = Integer.parseInt(req.getParameter("queries"));
			if (count > 500) {
				count = 500;
			} else if (count < 1) {
				count = 1;
			}
		} catch (final NumberFormatException ignore) {
		}

		final World[] worlds = new World[count];
		final Random random = ThreadLocalRandom.current();

		try (final Connection conn = dataSource.getConnection()) {
			try (final PreparedStatement statement = conn.prepareStatement("SELECT randomNumber FROM World WHERE id = ?",
					ResultSet.TYPE_FORWARD_ONLY,
					ResultSet.CONCUR_READ_ONLY)) {
				//This loop doesn't make sense in real world.
				//You would aggregate those multiple queries (even totally different ones) into a single DB call.
				for (int i = 0; i < count; i++) {
					final int id = random.nextInt(10000) + 1;
					statement.setInt(1, id);
					try (final ResultSet results = statement.executeQuery()) {
						results.next();
						worlds[i] = new World(id, results.getInt(1));
					}
				}
			}
		} catch (final SQLException ex) {
			ex.printStackTrace();
		}

		final JsonWriter writer = Utils.getJson();
		writer.serialize(worlds);
		res.setContentType(Utils.JSON_CONTENT);
		writer.toStream(res.getOutputStream());
	}
}

