package hello;

import com.dslplatform.json.JsonWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class QueriesServlet extends HttpServlet {

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		res.setContentType("application/json");
		final int count = Utils.parseBoundParam(req);
		final Context ctx = Utils.getContext();
		final JsonWriter json = ctx.json;
		ctx.loadWorlds(count);
		json.serialize(ctx.worlds, count);
		json.toStream(res.getOutputStream());
	}
}
