using System;
using System.Configuration;
using Revenj.Utility;

namespace Revenj.Bench
{
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
}
