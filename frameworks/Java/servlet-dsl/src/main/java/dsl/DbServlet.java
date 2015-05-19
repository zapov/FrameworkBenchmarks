package dsl;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Random;
import java.util.concurrent.ThreadLocalRandom;

import javax.annotation.Resource;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

import com.dslplatform.client.json.JsonWriter;

import dsl.Bench.World;

public class DbServlet extends HttpServlet {
    @Resource(name = "jdbc/data_source")
    private DataSource dataSource;

	@Override
	protected void doGet(final HttpServletRequest req, final HttpServletResponse res) throws ServletException, IOException {
		final Random random = ThreadLocalRandom.current();
		final JsonWriter writer = Utils.getJson();

		try (final Connection conn = dataSource.getConnection()) {
			try (final PreparedStatement statement = conn.prepareStatement("SELECT randomNumber FROM World WHERE id = ?",
					ResultSet.TYPE_FORWARD_ONLY,
					ResultSet.CONCUR_READ_ONLY)) {
				final int id = random.nextInt(10000) + 1;
				statement.setInt(1, id);

				try (final ResultSet results = statement.executeQuery()) {
					results.next();
					final World world = new World(id, results.getInt(1));
					world.serialize(writer, false);
					res.setContentType(Utils.JSON_CONTENT);
					writer.toStream(res.getOutputStream());
				}
			}
		} catch (final SQLException ex) {
			ex.printStackTrace();
			res.sendError(500, ex.getMessage());
		}
	}
}

