using System;
using System.Collections.Generic;
using System.Linq;
using Xunit;
using QCFormula;

namespace QCFormulaTests
{
    public class DataMapperTests
    {
        [Fact]
        public void MapDictToFlat_ValidInput_ReturnsExpectedFlatList()
        {
            // Arrange
            var measurementData = new Dictionary<string, object>
            {
                { "test_k", 4 },
                { "test_h", null },
                { "pga", 64.56 },
                { "pgb", new List<object> { 43.87, null, null } }, // Using List<object> as input usually comes like this from JSON
                { "pgd", new List<object> { 67.65, null, 64.356 } },
                { "pgc", 53.4 }
            };

            var parameters = new Dictionary<string, ParameterDefinition>
            {
                { "test_k", new ParameterDefinition { TestId = 38, IsArray = false } },
                { "test_h", new ParameterDefinition { TestId = 41, IsArray = false } },
                { "pga", new ParameterDefinition { TestId = 29, IsArray = false } },
                { "pgb", new ParameterDefinition { TestId = 30, IsArray = true } },
                { "pgd", new ParameterDefinition { TestId = 36, IsArray = true } },
                { "pgc", new ParameterDefinition { TestId = 31, IsArray = false } }
            };

            // Act
            var result = DataMapper.MapDictToFlat(measurementData, parameters);

            // Assert
            Assert.Equal(6, result.Count);

            // Verify specific items
            Assert.Contains(result, x => x.TestId == 38 && x.Idx == 0 && Math.Abs(x.Value - 4) < 0.001m);
            Assert.Contains(result, x => x.TestId == 29 && x.Idx == 0 && Math.Abs(x.Value - 64.56m) < 0.001m);
            Assert.Contains(result, x => x.TestId == 30 && x.Idx == 0 && Math.Abs(x.Value - 43.87m) < 0.001m);
            Assert.Contains(result, x => x.TestId == 36 && x.Idx == 0 && Math.Abs(x.Value - 67.65m) < 0.001m);
            Assert.Contains(result, x => x.TestId == 36 && x.Idx == 2 && Math.Abs(x.Value - 64.356m) < 0.001m);
            Assert.Contains(result, x => x.TestId == 31 && x.Idx == 0 && Math.Abs(x.Value - 53.4m) < 0.001m);

            // test_h should be missing
            Assert.DoesNotContain(result, x => x.TestId == 41);
        }

        [Fact]
        public void MapDictToFlat_Validation_MissingParameterDefinition_ThrowsArgumentException()
        {
            var measurementData = new Dictionary<string, object> { { "unknown", 1 } };
            var parameters = new Dictionary<string, ParameterDefinition>();

            var ex = Assert.Throws<ArgumentException>(() => DataMapper.MapDictToFlat(measurementData, parameters));
            Assert.Contains("not defined in parameters", ex.Message);
        }

        [Fact]
        public void MapDictToFlat_Validation_TypeMismatch_ArrayExpected_Throws()
        {
            var measurementData = new Dictionary<string, object> { { "p1", 123.0 } }; // Scalar given
            var parameters = new Dictionary<string, ParameterDefinition> { { "p1", new ParameterDefinition { TestId = 1, IsArray = true } } }; // Array expected

            var ex = Assert.Throws<ArgumentException>(() => DataMapper.MapDictToFlat(measurementData, parameters));
            Assert.Contains("expected to be an array", ex.Message);
        }

        [Fact]
        public void MapDictToFlat_Validation_TypeMismatch_ScalarExpected_Throws()
        {
            var measurementData = new Dictionary<string, object> { { "p1", new List<object> { 1, 2 } } }; // Array given
            var parameters = new Dictionary<string, ParameterDefinition> { { "p1", new ParameterDefinition { TestId = 1, IsArray = false } } }; // Scalar expected

            var ex = Assert.Throws<ArgumentException>(() => DataMapper.MapDictToFlat(measurementData, parameters));
            Assert.Contains("expected to be a scalar", ex.Message);
        }

        [Fact]
        public void MapFlatToDict_ValidInput_ReconstructsDictionary()
        {
            // Arrange
            var flatParams = new List<MeasurementFlatData>
            {
                new MeasurementFlatData { TestId = 38, Idx = 0, Value = 4 },
                new MeasurementFlatData { TestId = 29, Idx = 0, Value = 64.56m },
                new MeasurementFlatData { TestId = 30, Idx = 0, Value = 43.87m },
                new MeasurementFlatData { TestId = 36, Idx = 0, Value = 67.65m },
                new MeasurementFlatData { TestId = 36, Idx = 2, Value = 64.356m },
                new MeasurementFlatData { TestId = 31, Idx = 0, Value = 53.4m },
            };

             var parameters = new Dictionary<string, ParameterDefinition>
            {
                { "test_k", new ParameterDefinition { TestId = 38, IsArray = false } },
                { "test_h", new ParameterDefinition { TestId = 41, IsArray = false } },
                { "pga", new ParameterDefinition { TestId = 29, IsArray = false } },
                { "pgb", new ParameterDefinition { TestId = 30, IsArray = true } },
                { "pgd", new ParameterDefinition { TestId = 36, IsArray = true } },
                { "pgc", new ParameterDefinition { TestId = 31, IsArray = false } }
            };

            var relatedParameterArrays = new Dictionary<string, List<string>>
            {
                { "arr5", new List<string> { "pgb", "pgd" } }
            };

            // Act
            var result = DataMapper.MapFlatToDict(flatParams, parameters, relatedParameterArrays);

            // Assert
            Assert.Equal(4.0m, (decimal)result["test_k"]);
            Assert.Equal(64.56m, (decimal)result["pga"]);
            Assert.Equal(53.4m, (decimal)result["pgc"]);
            Assert.Null(result["test_h"]);

            var pgb = (List<decimal?>)result["pgb"];
            Assert.Equal(3, pgb.Count); // Max index is 2
            Assert.Equal(43.87m, pgb[0]);
            Assert.Null(pgb[1]);
            Assert.Null(pgb[2]);

            var pgd = (List<decimal?>)result["pgd"];
            Assert.Equal(3, pgd.Count);
            Assert.Equal(67.65m, pgd[0]);
            Assert.Null(pgd[1]);
            Assert.Equal(64.356m, pgd[2]);
        }
        
        [Fact]
        public void MapFlatToDict_NoDataForArray_ReturnsNullIfStrictOrEmpty()
        {
            var flatParams = new List<MeasurementFlatData>
            {
                 new MeasurementFlatData { TestId = 30, Idx = 1, Value = 43.87m }, // pgb has data at index 1
            };

             var parameters = new Dictionary<string, ParameterDefinition>
            {
                { "pgb", new ParameterDefinition { TestId = 30, IsArray = true } },
                { "pgd", new ParameterDefinition { TestId = 36, IsArray = true } },
            };

            var relatedParameterArrays = new Dictionary<string, List<string>>
            {
                { "arr5", new List<string> { "pgb", "pgd" } }
            };

            var result = DataMapper.MapFlatToDict(flatParams, parameters, relatedParameterArrays);
            
            // pgb should be [null, 43.87]
            var pgb = (List<decimal?>)result["pgb"];
            Assert.Equal(2, pgb.Count);
            Assert.Null(pgb[0]);
            Assert.Equal(43.87m, pgb[1]);

            // pgd should be [null, null] because it's related to pgb
            var pgd = (List<decimal?>)result["pgd"];
            Assert.Equal(2, pgd.Count);
            Assert.Null(pgd[0]);
            Assert.Null(pgd[1]);
        }

        [Fact]
        public void MapFlatToDict_MixedScalarAndArrays_EmptyArraysForMissingData()
        {
            // Arrange
            var flatParams = new List<MeasurementFlatData>
            {
                new MeasurementFlatData { TestId = 41, Idx = 0, Value = 0 }
            };

            var parameters = new Dictionary<string, ParameterDefinition>
            {
                { "test_h", new ParameterDefinition { TestId = 41, IsArray = false } },
                { "test_k", new ParameterDefinition { TestId = 38, IsArray = false } },
                { "pga", new ParameterDefinition { TestId = 29, IsArray = false } },
                { "pgb", new ParameterDefinition { TestId = 30, IsArray = true } },
                { "pgd", new ParameterDefinition { TestId = 36, IsArray = true } },
                { "pge", new ParameterDefinition { TestId = 39, IsArray = true } },
                { "pgf", new ParameterDefinition { TestId = 40, IsArray = true } }
            };

            var relatedParameterArrays = new Dictionary<string, List<string>>
            {
                { "arr5", new List<string> { "pgb", "pgd", "pge", "pgf" } }
            };

            // Act
            var result = DataMapper.MapFlatToDict(flatParams, parameters, relatedParameterArrays);

            // Assert
            Assert.Equal(0.0m, (decimal)result["test_h"]);
            Assert.Null(result["test_k"]);
            Assert.Null(result["pga"]);

            Assert.IsType<List<decimal?>>(result["pgb"]);
            Assert.Empty((List<decimal?>)result["pgb"]);

            Assert.IsType<List<decimal?>>(result["pgd"]);
            Assert.Empty((List<decimal?>)result["pgd"]);

            Assert.IsType<List<decimal?>>(result["pge"]);
            Assert.Empty((List<decimal?>)result["pge"]);

            Assert.IsType<List<decimal?>>(result["pgf"]);
            Assert.Empty((List<decimal?>)result["pgf"]);
        }

        [Fact]
        public void MapFlatToDict_Validation_InvalidTestId_Throws()
        {
            var flatParams = new List<MeasurementFlatData>
            {
                new MeasurementFlatData { TestId = 999, Idx = 0, Value = 1 } // 999 not in parameters
            };
            var parameters = new Dictionary<string, ParameterDefinition>();

            var ex = Assert.Throws<ArgumentException>(() => DataMapper.MapFlatToDict(flatParams, parameters, null));
            Assert.Contains("TestId '999' found in flat parameters is not defined", ex.Message);
        }

        [Fact]
        public void MapFlatToDict_Validation_RelatedParamMissing_Throws()
        {
            var flatParams = new List<MeasurementFlatData>();
            var parameters = new Dictionary<string, ParameterDefinition>();
            var related = new Dictionary<string, List<string>> { { "g", new List<string> { "missing" } } };

            var ex = Assert.Throws<ArgumentException>(() => DataMapper.MapFlatToDict(flatParams, parameters, related));
            Assert.Contains("Related array parameter 'missing' is not defined", ex.Message);
        }

        [Fact]
        public void MapFlatToDict_Validation_RelatedParamNotArray_Throws()
        {
             var flatParams = new List<MeasurementFlatData>();
             var parameters = new Dictionary<string, ParameterDefinition> { { "p1", new ParameterDefinition { TestId = 1, IsArray = false } } };
             var related = new Dictionary<string, List<string>> { { "g", new List<string> { "p1" } } };

             var ex = Assert.Throws<ArgumentException>(() => DataMapper.MapFlatToDict(flatParams, parameters, related));
             Assert.Contains("must be defined as an array", ex.Message);
        }
    }
}