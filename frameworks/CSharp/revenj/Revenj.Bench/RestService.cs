using System;
using System.ComponentModel;
using System.Configuration;
using System.IO;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using FrameworkBench;
using Revenj.Api;
using Revenj.Serialization;
using Revenj.Utility;

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

	internal static class ThreadLocal
	{
		[ThreadStatic]
		private static ChunkedMemoryStream ThreadStream;
		internal static ChunkedMemoryStream Stream
		{
			get
			{
				if (ThreadStream == null)
					ThreadStream = new ChunkedMemoryStream();
				ThreadStream.Position = 0;
				return ThreadStream;
			}
		}
		[ThreadStatic]
		private static Random ThreadRandom;
		internal static Random Random
		{
			get
			{
				if (ThreadRandom == null)
					ThreadRandom = new Random(0);
				return ThreadRandom;
			}
		}
		private static readonly string ConnectionString = ConfigurationManager.AppSettings["ConnectionString"];
		[ThreadStatic]
		private static DAL ThreadCommand;
		internal static DAL Command
		{
			get
			{
				if (ThreadCommand == null)
					ThreadCommand = new DAL(ConnectionString);
				return ThreadCommand;
			}
		}
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
			cms.Position = 0;
			ThreadContext.Response.ContentType = "text/plain";
			return cms;
		}

		private Stream ReturnJSON(object value)
		{
			var cms = ThreadLocal.Stream;
			//using baked in serialization since DSL is compiled with manual-json
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
			var id = ThreadLocal.Random.Next(10000) + 1;
			var com = ThreadLocal.Command;
			var world = new World { id = id, randomNumber = com.FindRandomNumber(id) };
			return ReturnJSON(world);
		}

		public Stream MultipleQueries(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var com = ThreadLocal.Command;
			var rnd = ThreadLocal.Random;
			//let's not use the correct way to solve such problems, but instead "punish" the driver
			//var worlds = com.ExecuteMany(repeat, rnd);
			var worlds = new World[repeat];
			for (int i = 0; i < worlds.Length; i++)
			{
				var id = rnd.Next(10000) + 1;
				worlds[i] = new World { id = id, randomNumber = com.FindRandomNumber(id) };
			}
			return ReturnJSON(worlds);
		}

		public Stream Updates(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var com = ThreadLocal.Command;
			var rnd = ThreadLocal.Random;
			//let's not use the correct way to solve such problems, but instead "punish" the driver
			//var worlds = com.ExecuteMany(repeat, rnd);
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
