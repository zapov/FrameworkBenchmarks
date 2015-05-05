using System;
using Revenj.DomainPatterns;
using Revenj.Extensibility.Autofac;

namespace Revenj.Bench
{
	public class ContainerConfiguration : Module
	{
		protected override void Load(ContainerBuilder builder)
		{
			builder.RegisterInstance(new EmptyModel()).As<IDomainModel>().SingleInstance();
			base.Load(builder);
		}

		class EmptyModel : IDomainModel
		{
			public Type Find(string name) { return null; }
		}
	}
}
