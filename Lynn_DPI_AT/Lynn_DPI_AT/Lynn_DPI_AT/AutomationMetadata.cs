using System;
using Ranorex;
using Ranorex.Core.Reporting;

namespace Lynn_DPI_AT
{
    public static class AutomationMetadata
    {
        public const string ProductName = "DPI OpenFile Automation";
        public const string Maintainer  = "Lynn Nguyen";
        public const string OwnerTag    = "LN-DPI-RX-OpenFile";

        public static void LogToReport()
        {
            Report.Log(ReportLevel.Info, "Metadata",
                string.Format("[Automation] Product={0} | Maintainer={1} | Tag={2}",
                    ProductName, Maintainer, OwnerTag));
        }
    }
}
