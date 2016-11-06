using System;
using FrameworkBench;
using Revenj.DatabasePersistence;
using Revenj.DatabasePersistence.Postgres;
using Revenj.DomainPatterns;
using Revenj.Extensibility;
using Revenj.Utility;

namespace Revenj.Bench
{
	internal class Context
	{
		public readonly ChunkedMemoryStream Stream;
		public readonly IPersistableRepository<World> WorldRepository;
		public readonly IQueryableRepository<Fortune> FortuneRepository;
		public readonly IRepositoryBulkReader BulkReader;
		public readonly Lazy<World>[] LazyWorlds = new Lazy<World>[512];
		public readonly World[] Worlds = new World[512];

		public Context(IObjectFactory factory, IDatabaseQueryManager manager)
		{
			Stream = ChunkedMemoryStream.Static();
			var scope = factory.CreateScope(null);
			scope.RegisterInterfaces(manager.StartQuery(false));
			WorldRepository = scope.Resolve<IPersistableRepository<World>>();
			FortuneRepository = scope.Resolve<IQueryableRepository<Fortune>>();
			BulkReader = scope.BulkRead(ChunkedMemoryStream.Static());
		}
	}
}
