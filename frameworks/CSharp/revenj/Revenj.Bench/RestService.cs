using System;
using System.Collections.Generic;
using System.IO;
using System.ServiceModel.Web;
using System.Text;
using System.Threading;
using FrameworkBench;
using Revenj.Api;
using Revenj.DatabasePersistence;
using Revenj.DomainPatterns;
using Revenj.Extensibility;
using Revenj.Http;
using Revenj.Utility;

namespace Revenj.Bench
{
	[Controller("bench")]
	public class RestService
	{
		private static readonly ChunkedMemoryStream HelloWorld = ChunkedMemoryStream.Static();

		static RestService()
		{
			var hwText = Encoding.UTF8.GetBytes("Hello, World!");
			HelloWorld.Write(hwText, 0, hwText.Length);
			HelloWorld.Position = 0;
		}

		private readonly Random Random = new Random(0);
		private readonly ThreadLocal<Context> Context;

		public RestService(IObjectFactory factory, IDatabaseQueryManager queryManager)
		{
			this.Context = new ThreadLocal<Context>(() => new Context(factory, queryManager));
		}

		[WebGet(UriTemplate = "/plaintext")]
		public Stream PlainText(IResponseContext response)
		{
			response.ContentType = "text/plain";
			return HelloWorld;
		}

		[WebGet(UriTemplate = "/json")]
		public Message JSON()
		{
			return new Message { message = "Hello, World!" };
		}

		[WebGet(UriTemplate = "/db")]
		public World SingleQuery()
		{
			var id = Random.Next(10000) + 1;
			var ctx = Context.Value;
			return ctx.WorldRepository.Find(id);
		}

		/* bulk loading of worlds. use such pattern for production code */
		private void LoadWorldsFast(int repeat, Context ctx)
		{
			var reader = ctx.BulkReader;
			var lazyResult = ctx.LazyWorlds;
			var worlds = ctx.Worlds;
			reader.Reset(true);
			for (int i = 0; i < repeat; i++)
			{
				var id = Random.Next(10000) + 1;
				lazyResult[i] = reader.Find<World>(id.ToString());
			}
			reader.Execute();
			for (int i = 0; i < repeat; i++)
				worlds[i] = lazyResult[i].Value;
		}

		/* multiple roundtrips loading of worlds. don't write such production code */
		private void LoadWorldsSlow(int repeat, Context ctx)
		{
			var worlds = ctx.Worlds;
			var repository = ctx.WorldRepository;
			for (int i = 0; i < repeat; i++)
			{
				var id = Random.Next(10000) + 1;
				worlds[i] = repository.Find(id);
			}
		}

		[WebGet(UriTemplate = "/queries/{count}")]
		public ArraySegment<World> MultipleQueries(string count, IResponseContext response)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var ctx = Context.Value;
			LoadWorldsSlow(repeat, ctx);
			return new ArraySegment<World>(ctx.Worlds, 0, repeat);
		}

		private static readonly Comparison<World> ASC = (l, r) => l.id - r.id;

		[WebGet(UriTemplate = "/updates/{count}")]
		public World[] Updates(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var ctx = Context.Value;
			LoadWorldsSlow(repeat, ctx);
			var result = new World[repeat];
			Array.Copy(ctx.Worlds, result, repeat);
			for (int i = 0; i < result.Length; i++)
				result[i].randomNumber = Random.Next(10000) + 1;
			Array.Sort(result, ASC);
			ctx.WorldRepository.Update(result);
			return result;
		}

		private static readonly Comparison<KeyValuePair<int, string>> Comparison = (l, r) => string.Compare(l.Value, r.Value, StringComparison.Ordinal);

		[WebGet(UriTemplate = "/fortunes")]
		public Fortunes Fortunes()
		{
			var ctx = Context.Value;
			var fortunes = ctx.FortuneRepository.Search();
			var list = new List<KeyValuePair<int, string>>(fortunes.Length + 1);
			foreach (var f in fortunes)
				list.Add(new KeyValuePair<int, string>(f.id, f.message));
			list.Add(new KeyValuePair<int, string>(0, "Additional fortune added at request time."));
			list.Sort(Comparison);
			return new Fortunes(list);
		}
	}
}