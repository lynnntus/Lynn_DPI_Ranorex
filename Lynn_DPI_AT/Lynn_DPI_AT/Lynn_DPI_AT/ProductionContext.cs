using Ranorex;

namespace Lynn_DPI_AT
{
    public static class ProductionContext
    {
        public static string LastInspectionQuantity { get; set; }

        public static void Reset()
        {
            LastInspectionQuantity = null;
            Report.Log(ReportLevel.Info, "ProductionContext", "Da reset context.");
        }
    }
}
