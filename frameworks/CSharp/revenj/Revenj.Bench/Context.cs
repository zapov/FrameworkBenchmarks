using System;
using System.Collections.Generic;
using System.Configuration;
using System.Text;
using FrameworkBench;
using Revenj.DatabasePersistence.Postgres.Converters;
using Revenj.DatabasePersistence.Postgres.Npgsql;
using Revenj.Utility;

namespace Revenj.Bench
{
	//since Revenj "ORM" is not allowed, let's write RAW SQL queries similar to what Revenj would do
	internal class Context
	{
		private static byte[] ExecuteCommand = Encoding.ASCII.GetBytes("EXECUTE ");

		private readonly NpgsqlCommand Command;
		private readonly NpgsqlConnection Connection;
		internal readonly ChunkedMemoryStream Stream;
		private readonly char[] CharBuffer = new char[11];
		private readonly byte[] ByteBuffer = new byte[11];
		private readonly bool[] PreparedQueries = new bool[500];
		internal readonly Random Random = new Random();

		internal Context()
		{
			Connection = new NpgsqlConnection(ConfigurationManager.AppSettings["ConnectionString"]);
			Connection.Open();
			Stream = new ChunkedMemoryStream();
			Command = new NpgsqlCommand(Stream);
			Command.Connection = Connection;
			var com = new NpgsqlCommand("PREPARE w AS SELECT randomNumber FROM World WHERE id=$1", Connection);
			com.ExecuteNonQuery();
			com = new NpgsqlCommand("PREPARE u AS UPDATE World as w SET randomNumber = s.randomNumber FROM unnest($1::World[]) s WHERE w.id = s.id", Connection);
			com.ExecuteNonQuery();
			com = new NpgsqlCommand("PREPARE f AS SELECT f FROM Fortune f", Connection);
			com.ExecuteNonQuery();
		}

		private void WriteInt(ChunkedMemoryStream cms, int value)
		{
			var cb = CharBuffer;
			var bb = ByteBuffer;
			int len = IntConverter.Serialize(value, cb, 0);
			for (int i = cb.Length - len; i < cb.Length; i++)
				bb[i] = (byte)cb[i];
			cms.Write(bb, bb.Length - len, len);
		}

		private void WriteString(ChunkedMemoryStream cms, string value)
		{
			for (int i = 0; i < value.Length; i++)
				cms.WriteByte((byte)value[i]);
		}

		private void CheckQuery(int repeat)
		{
			if (PreparedQueries[repeat - 1])
				return;
			var subqueries = new List<string>(repeat);
			for (int j = 0; j < repeat; j++)
				subqueries.Add("(SELECT randomNumber FROM World WHERE id=$" + (j + 1) + ")");
			var com = new NpgsqlCommand("PREPARE q" + repeat + " AS SELECT ROW(" + string.Join(",", subqueries) + ")", Connection);
			com.ExecuteNonQuery();
			PreparedQueries[repeat - 1] = true;
		}

		private ChunkedMemoryStream PrepareExecute(string name)
		{
			var cms = Stream;
			cms.Position = 0;
			cms.Write(ExecuteCommand, 0, ExecuteCommand.Length);
			WriteString(cms, name);
			cms.WriteByte((byte)'(');
			return cms;
		}

		public World ExecuteSingle()
		{
			var id = Random.Next(10000) + 1;
			var cms = PrepareExecute("w");
			WriteInt(cms, id);
			cms.WriteByte((byte)')');
			cms.SetLength(cms.Position);
			var rnd = (int)Command.ExecuteScalar();
			return new World { id = id, randomNumber = rnd };
		}

		public World[] ExecuteMany(int repeat)
		{
			var result = new World[repeat];
			CheckQuery(repeat);
			var cms = PrepareExecute("q" + repeat);
			var rnd = Random;
			int id = rnd.Next(10000) + 1;
			WriteInt(cms, id);
			result[0] = new World { id = id };
			for (int i = 1; i < result.Length; i++)
			{
				cms.WriteByte((byte)',');
				id = rnd.Next(10000) + 1;
				WriteInt(cms, id);
				result[i] = new World { id = id };
			}
			cms.WriteByte((byte)')');
			cms.SetLength(cms.Position);
			var record = (string)Command.ExecuteScalar();
			var reader = cms.UseBufferedReader(record);
			reader.Read();
			for (int i = 0; i < result.Length; i++)
			{
				result[i].randomNumber = IntConverter.Parse(reader);
				reader.Read();
			}
			return result;
		}

		public List<Fortune> GetFortunes()
		{
			var cms = PrepareExecute("f");
			cms.SetLength(cms.Position - 1);
			var fortunes = new List<Fortune>(14);
			var dr = Command.ExecuteReader();
			while (dr.Read())
			{
				var reader = cms.UseBufferedReader(dr.GetString(0));
				reader.Read();
				var fortune = new Fortune { id = IntConverter.Parse(reader) };
				reader.Read();
				fortune.message = StringConverter.Parse(reader, 0);
				fortunes.Add(fortune);
			}
			dr.Close();
			return fortunes;
		}

		public void Update(World[] worlds)
		{
			var cms = PrepareExecute("u");
			WriteString(cms, "ARRAY[(");
			var w = worlds[0];
			WriteInt(cms, w.id);
			cms.WriteByte((byte)',');
			WriteInt(cms, w.randomNumber);
			for (int i = 1; i < worlds.Length; i++)
			{
				w = worlds[i];
				WriteString(cms, "),(");
				WriteInt(cms, w.id);
				cms.WriteByte((byte)',');
				WriteInt(cms, w.randomNumber);
			}
			WriteString(cms, ")]::World[])");
			cms.SetLength(cms.Position);
			Command.ExecuteNonQuery();
		}

		~Context()
		{
			try { Connection.Close(); }
			catch { }
		}
	}
}
