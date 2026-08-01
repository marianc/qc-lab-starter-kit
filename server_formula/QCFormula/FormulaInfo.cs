using System.Collections.Generic;

namespace QCFormula
{
    public class FormulaInfo
    {
        public string Formula { get; set; }
        public List<string> Dependencies { get; set; }
        public FormulaReturnType ReturnType { get; set; }
    }
}
