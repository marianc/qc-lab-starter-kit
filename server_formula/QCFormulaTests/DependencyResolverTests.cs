using System;
using System.Collections.Generic;
using Xunit;
using QCFormula;

namespace QCFormulaTests
{
    public class DependencyResolverTests
    {
        [Fact]
        public void TestReorderParameters_NoDependencies()
        {
            var parameters = new List<string> { "p1", "p2", "p3" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string>() },
                { "p3", new List<string>() }
            };
            var ordered = Formula.ReorderParametersByDependencies(parameters, dependencies);
            Assert.Equal(new List<string> { "p1", "p2", "p3" }, ordered);
        }

        [Fact]
        public void TestReorderParameters_SimpleDependency()
        {
            var parameters = new List<string> { "p1", "p2" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string> { "p1" } }
            };
            var ordered = Formula.ReorderParametersByDependencies(parameters, dependencies);
            Assert.Equal(new List<string> { "p1", "p2" }, ordered);
        }

        [Fact]
        public void TestReorderParameters_ComplexDependencies()
        {
            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string>() },
                { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() },
                { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() },
                { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3" } },
                { "p12", new List<string>() }
            };
            var ordered = Formula.ReorderParametersByDependencies(parameters, dependencies);
            Assert.Equal(new List<string> { "p1", "p2", "p3", "p8", "p11", "p6", "p4", "p7", "p9", "p10", "p12", "p5" }, ordered);
        }

        [Fact]
        public void TestReorderParameters_CyclicDependencies()
        {
            var parameters = new List<string> { "p1", "p2", "p3" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string> { "p2" } },
                { "p2", new List<string> { "p3" } },
                { "p3", new List<string> { "p1" } }
            };
            var exception = Assert.Throws<Exception>(() => Formula.ReorderParametersByDependencies(parameters, dependencies));
            Assert.Contains("Cyclic dependency detected.", exception.Message);
        }

        [Fact]
        public void TestReorderParameters_UnknownDependencies()
        {
            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string>() },
                { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() },
                { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() },
                { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3", "p17" } },
                { "p12", new List<string>() }
            };
            var exception = Assert.Throws<Exception>(() => Formula.ReorderParametersByDependencies(parameters, dependencies));
            Assert.Contains("Unknown dependency 'p17' for parameter 'p11'.", exception.Message);
        }

        [Fact]
        public void TestGetUnusedParameters()
        {
            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string>() },
                { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() },
                { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() },
                { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3" } },
                { "p12", new List<string>() }
            };
            var output = new List<string> { "p4", "p9", "p10" };
            
            var unused = Formula.GetUnusedParametersFromDependencies(parameters, dependencies, output);
            unused.Sort(); // Sort for comparison
            
            Assert.Equal(new List<string> { "p12", "p5", "p7", "p8" }, unused);
        }

        [Fact]
        public void TestGetUnusedParameters_UnknownDependency()
        {
            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string>() },
                { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() },
                { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() },
                { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3", "p17" } },
                { "p12", new List<string>() }
            };
            var output = new List<string> { "p4", "p9", "p10" };

            var exception = Assert.Throws<Exception>(() => Formula.GetUnusedParametersFromDependencies(parameters, dependencies, output));
            Assert.Contains("Unknown dependency 'p17' for parameter 'p11'.", exception.Message);
        }

        [Fact]
        public void TestGetUnusedParameters_InvalidOutputParameter()
        {
            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string>() },
                { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() },
                { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() },
                { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3" } },
                { "p12", new List<string>() }
            };
            var output = new List<string> { "p4", "p9", "p13" };

            var exception = Assert.Throws<Exception>(() => Formula.GetUnusedParametersFromDependencies(parameters, dependencies, output));
            Assert.Contains("Output parameter 'p13' not found in parameters list.", exception.Message);
        }

        [Fact]
        public void TestGetUnusedParameters_CyclicDependencies()
        {
            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() },
                { "p2", new List<string>() },
                { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() },
                { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() },
                { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3", "p5" } }, // Cycle p5 -> p4 -> p11 -> p5
                { "p12", new List<string>() }
            };
            var output = new List<string> { "p5", "p9", "p10" };

            var exception = Assert.Throws<Exception>(() => Formula.GetUnusedParametersFromDependencies(parameters, dependencies, output));
            Assert.Contains("Cyclic dependency detected.", exception.Message);
        }
    }
}
