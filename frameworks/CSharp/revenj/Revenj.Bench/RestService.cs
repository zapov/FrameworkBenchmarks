using System.ComponentModel;
using System.IO;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using FrameworkBench;
using Revenj.Api;
using Revenj.Serialization;

namespace Revenj.Bench
{
	[ServiceContract(Namespace = "https://github.com/ngs-doo/revenj")]
	public interface IRestService
	{
		[OperationContract]
		[WebGet(UriTemplate = "/plaintext")]
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
		[WebGet(UriTemplate = "/updates?queries={queries}")]
		[Description("Database updates")]
		Stream Updates(string queries);
	}

	public class RestService : IRestService
	{
		private static byte[] HelloWorld = Encoding.ASCII.GetBytes("Hello, World!");

		private readonly JsonSerialization Json;

		public RestService(JsonSerialization json)
		{
			this.Json = json;
		}

		public Stream PlainText()
		{
			var cms = ThreadLocal.Stream;
			cms.Write(HelloWorld, 0, HelloWorld.Length);
			cms.SetLength(cms.Position);
			cms.Position = 0;
			ThreadContext.Response.ContentType = "text/plain";
			return cms;
		}

		private Stream ReturnJSON(object value)
		{
			var cms = ThreadLocal.Stream;
			//using baked in serialization since DSL is compiled with manual-json
			Json.Serialize(value, cms, false);
			cms.SetLength(cms.Position);
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
			var id = ThreadLocal.Random.Next(10000) + 1;
			var com = ThreadLocal.Command;
			var world = new World { id = id, randomNumber = com.FindRandomNumber(id) };
			return ReturnJSON(world);
		}

		//it seems it's against the spirit of the bench to use database features
		//to solve problems in an efficient way if such features don't work across databases/frameworks
		//so let's just loop like everyone else
		public Stream MultipleQueries(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var com = ThreadLocal.Command;
			var rnd = ThreadLocal.Random;
			var worlds = new World[repeat];
			for (int i = 0; i < worlds.Length; i++)
			{
				var id = rnd.Next(10000) + 1;
				worlds[i] = new World { id = id, randomNumber = com.FindRandomNumber(id) };
			}
			return ReturnJSON(worlds);
		}

		//it doesn't make sense to allow bulk update, but disallow bulk read
		//but since owners don't allow that, let's loop again
		public Stream Updates(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var com = ThreadLocal.Command;
			var rnd = ThreadLocal.Random;
			var worlds = new World[repeat];
			for (int i = 0; i < worlds.Length; i++)
			{
				var id = rnd.Next(10000) + 1;
				//let's find the random number
				worlds[i] = new World { id = id, randomNumber = com.FindRandomNumber(id) };
				//so that we don't use it :D
				worlds[i].randomNumber = rnd.Next(10000) + 1;
			}
			com.Update(worlds);
			return ReturnJSON(worlds);
		}
	}
}
