using System;
using System.Collections.Generic;
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

	internal static class ThreadLocal
	{
		[ThreadStatic]
		private static Context ThreadContext;
		internal static Context Context
		{
			get
			{
				if (ThreadContext == null)
					ThreadContext = new Context();
				return ThreadContext;
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

		private Context GetContext()
		{
			return ThreadLocal.Context;
		}

		public Stream PlainText()
		{
			var ctx = GetContext();
			var cms = ctx.Stream;
			cms.Write(HelloWorld, 0, HelloWorld.Length);
			cms.Position = 0;
			ThreadContext.Response.ContentType = "text/plain";
			return cms;
		}

		private Stream ReturnJSON(Context ctx, object value)
		{
			var cms = ctx.Stream;
			//using baked in serialization since DSL is compiled with manual-json
			Json.Serialize(value, cms, false);
			cms.Position = 0;
			ThreadContext.Response.ContentType = "application/json";
			return cms;
		}

		public Stream JSON()
		{
			return ReturnJSON(GetContext(), new Message { message = "Hello, World!" });
		}

		public Stream SingleQuery()
		{
			var ctx = GetContext();
			var world = ctx.ExecuteSingle();
			return ReturnJSON(ctx, world);
		}

		public Stream MultipleQueries(string count)
		{
			int repeat;
			int.TryParse(count, out repeat);
			if (repeat < 1) repeat = 1;
			else if (repeat > 500) repeat = 500;
			var ctx = GetContext();
			var worlds = ctx.ExecuteMany(repeat);
			return ReturnJSON(ctx, worlds);
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
			var fortunes = GetContext().GetFortunes();
			fortunes.Add(new Fortune { id = 0, message = "Additional fortune added at request time." });
			fortunes.Sort(StaticFortuneComparer);

			var template = new ASP._Fortunes_cshtml { Model = fortunes };
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
			var ctx = GetContext();
			var worlds = ctx.ExecuteMany(repeat);
			var rnd = ctx.Random;
			for (int i = 0; i < worlds.Length; i++)
				worlds[i].randomNumber = rnd.Next(10000) + 1;
			ctx.Update(worlds);
			return ReturnJSON(ctx, worlds);
		}
	}
}
