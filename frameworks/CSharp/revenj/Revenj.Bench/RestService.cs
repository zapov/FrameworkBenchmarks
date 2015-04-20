using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using FrameworkBench;
using Revenj.Api;
using Revenj.DomainPatterns;
using Revenj.Extensibility;
using Revenj.Processing;
using Revenj.Serialization;
using Revenj.Utility;

namespace Revenj.Bench
{
	[ServiceContract(Namespace = "https://github.com/ngs-doo/revenj")]
	public interface IRestService
	{
		[OperationContract]
		[WebGet(UriTemplate = "/text")]
		[Description("Plain text response")]
		Stream PlainText();

		[OperationContract]
		[WebGet(UriTemplate = "/json")]
		[Description("JSON response")]
		Stream JSON();

		[OperationContract]
		[WebGet(UriTemplate = "/db")]
		[Description("Single database query")]
		Stream SingleQuery();

		[OperationContract]
		[WebGet(UriTemplate = "/queries/{count}")]
		[Description("Multiple database queries")]
		Stream MultipleQueries(string count);

		[OperationContract]
		[WebGet(UriTemplate = "/fortunes")]
		[Description("Server side templates")]
		Stream Fortunes();

		[OperationContract]
		[WebGet(UriTemplate = "/updates?queries={queries}")]
		[Description("Database updates")]
		Stream Updates(string queries);
	}

	public class RestService : IRestService
	{
		private static byte[] HelloWorld = Encoding.UTF8.GetBytes("Hello, World!");
		private static Random Random = new Random(0);

		private readonly IScopePool ScopePool;
		private readonly JsonSerialization Json;

		public RestService(IScopePool scopePool, JsonSerialization json)
		{
			this.ScopePool = scopePool;
			this.Json = json;
		}

		public Stream PlainText()
		{
			var cms = ChunkedMemoryStream.Create();
			cms.Write(HelloWorld, 0, HelloWorld.Length);
			cms.Position = 0;
			ThreadContext.Response.ContentType = "text/plain";
			return cms;
		}

		private Stream ReturnJSON(object value)
		{
			var cms = ChunkedMemoryStream.Create();
			//using baked in serialization since DSL is compiled with manual-json
			//world objects will have an extra field: URI
			Json.Serialize(value, cms, false);
			cms.Position = 0;
			ThreadContext.Response.ContentType = "application/json";
			return cms;
		}

		public Stream JSON()
		{
			return ReturnJSON(new Message { message = "Hello, World!" });
		}

		public Stream SingleQuery()
		{
			var id = Random.Next(1, 10000);
			var scope = ScopePool.Take(true);
			var repository = scope.Factory.Resolve<IRepository<World>>();
			var world = repository.Find(id.ToString());
			ScopePool.Release(scope, true);
			return ReturnJSON(world);
		}

		public Stream MultipleQueries(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var scope = ScopePool.Take(true);
			var locator = scope.Factory.Resolve<IServiceLocator>();
			var repository = scope.Factory.Resolve<IRepository<World>>();
			var result = PopulateWorlds(repeat, locator, repository);
			ScopePool.Release(scope, true);
			return ReturnJSON(result);
		}

		//maybe not in the spirit of test, but following requirements of the test
		private static World[] PopulateWorlds(int repeat, IServiceLocator locator, IRepository<World> repository)
		{
			var result = new World[repeat];
			switch (repeat)
			{
				case 1:
					var id1 = Random.Next(1, 10000);
					result[0] = repository.Find(id1.ToString());
					break;
				case 5:
					var q5 = new Queries5
					{
						id1 = Random.Next(1, 10000),
						id2 = Random.Next(1, 10000),
						id3 = Random.Next(1, 10000),
						id4 = Random.Next(1, 10000),
						id5 = Random.Next(1, 10000),
					};
					//execute 5 queries looking up ids on the server
					var r5 = q5.Populate(locator);
					result[0] = r5.world1;
					result[1] = r5.world2;
					result[2] = r5.world3;
					result[3] = r5.world4;
					result[4] = r5.world5;
					break;
				case 10:
					//execute 10 queries looking up ids on the server
					RunQueries10(locator, result, 0);
					break;
				case 15:
					//execute 15 queries looking up ids on the server
					RunQueries15(locator, result);
					break;
				case 20:
					//execute 2x10 queries looking up ids on the server
					RunQueries10(locator, result, 0);
					RunQueries10(locator, result, 10);
					break;
				default:
					int i = 0;
					for (; i < result.Length - 9; i += 10)
					{
						//execute 10 queries looking up ids on the server
						RunQueries10(locator, result, i);
					}
					//execute remaining queries
					for (; i < result.Length; i++)
					{
						var id = Random.Next(1, 10000);
						result[i] = repository.Find(id.ToString());
					}
					break;
			}
			return result;
		}

		private static void RunQueries10(IServiceLocator locator, World[] result, int start)
		{
			var id = new Id10
			{
				id1 = Random.Next(1, 10000),
				id2 = Random.Next(1, 10000),
				id3 = Random.Next(1, 10000),
				id4 = Random.Next(1, 10000),
				id5 = Random.Next(1, 10000),
				id6 = Random.Next(1, 10000),
				id7 = Random.Next(1, 10000),
				id8 = Random.Next(1, 10000),
				id9 = Random.Next(1, 10000),
				id10 = Random.Next(1, 10000),
			};
			var q = new Queries10 { id = id };
			var r = q.Populate(locator);
			result[start + 0] = r.world1;
			result[start + 1] = r.world2;
			result[start + 2] = r.world3;
			result[start + 3] = r.world4;
			result[start + 4] = r.world5;
			result[start + 5] = r.world6;
			result[start + 6] = r.world7;
			result[start + 7] = r.world8;
			result[start + 8] = r.world9;
			result[start + 9] = r.world10;
		}

		private static void RunQueries15(IServiceLocator locator, World[] result)
		{
			var id = new Id15
			{
				id1 = Random.Next(1, 10000),
				id2 = Random.Next(1, 10000),
				id3 = Random.Next(1, 10000),
				id4 = Random.Next(1, 10000),
				id5 = Random.Next(1, 10000),
				id6 = Random.Next(1, 10000),
				id7 = Random.Next(1, 10000),
				id8 = Random.Next(1, 10000),
				id9 = Random.Next(1, 10000),
				id10 = Random.Next(1, 10000),
				id11 = Random.Next(1, 10000),
				id12 = Random.Next(1, 10000),
				id13 = Random.Next(1, 10000),
				id14 = Random.Next(1, 10000),
				id15 = Random.Next(1, 10000),
			};
			var q = new Queries15 { id = id };
			var r = q.Populate(locator);
			result[0] = r.world1;
			result[1] = r.world2;
			result[2] = r.world3;
			result[3] = r.world4;
			result[4] = r.world5;
			result[5] = r.world6;
			result[6] = r.world7;
			result[7] = r.world8;
			result[8] = r.world9;
			result[9] = r.world10;
			result[10] = r.world11;
			result[11] = r.world12;
			result[12] = r.world13;
			result[13] = r.world14;
			result[14] = r.world15;
		}

		private static FortuneComparer StaticFortuneComparer = new FortuneComparer();
		class FortuneComparer : IComparer<Fortune>
		{
			public int Compare(Fortune x, Fortune y)
			{
				return x.message.CompareTo(y.message);
			}
		}

		public Stream Fortunes()
		{
			var scope = ScopePool.Take(true);
			var repository = scope.Factory.Resolve<IQueryableRepository<Fortune>>();
			var fortunes = repository.Search();
			ScopePool.Release(scope, true);
			var model = new List<Fortune>(fortunes);
			model.Add(new Fortune { id = 0, message = "Additional fortune added at request time." });
			model.Sort(StaticFortuneComparer);

			var template = new ASP._Fortunes_cshtml { Model = model };
			var text = template.TransformText();
			ThreadContext.Response.ContentType = "text/html; charset=\"utf-8\"";
			return new MemoryStream(Encoding.UTF8.GetBytes(text));
		}

		public Stream Updates(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var scope = ScopePool.Take(true);
			var locator = scope.Factory.Resolve<IServiceLocator>();
			var repository = scope.Factory.Resolve<IPersistableRepository<World>>();
			var changed = new Dictionary<int, World>(repeat);
			var result = PopulateWorlds(repeat, locator, repository);
			for (int i = 0; i < result.Length; i++)
			{
				var world = result[i];
				world.randomNumber = Random.Next(1, 10000);
				//same object can be looked up by random function
				//revenj will complain in such case about wrong expected update count
				changed[world.id] = world;
			}
			//there are no transactions involved and bulk update seems to be allowed
			repository.Update(changed.Values);
			ScopePool.Release(scope, true);
			return ReturnJSON(result);
		}
	}
}
