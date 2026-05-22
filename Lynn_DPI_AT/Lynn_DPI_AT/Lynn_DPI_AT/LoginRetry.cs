///////////////////////////////////////////////////////////////////////////////
//
// LoginRetry - Thin orchestrator module.
// Calls Login_Pass.LoginWithAllUsersFromDataSource() which reads Excel
// and loops through all credentials until login succeeds.
//
///////////////////////////////////////////////////////////////////////////////

using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Drawing;
using System.Threading;
using WinForms = System.Windows.Forms;

using Ranorex;
using Ranorex.Core;
using Ranorex.Core.Repository;
using Ranorex.Core.Testing;

namespace Lynn_DPI_AT
{
    [TestModule("a1b2c3d4-e5f6-7890-abcd-ef1234567890", ModuleType.UserCode, 1)]
    public class LoginRetry : ITestModule
    {
        public static Lynn_DPI_ATRepository repo = Lynn_DPI_ATRepository.Instance;

        public LoginRetry()
        {
        }

        void ITestModule.Run()
        {
            Mouse.DefaultMoveTime = 300;
            Keyboard.DefaultKeyPressTime = 100;
            Delay.SpeedFactor = 1.00;

            Report.Log(ReportLevel.Info, "LoginRetry", "Chờ login window...");
            repo.CCILoginWindow.SelfInfo.WaitForExists(30000);

            bool success = Login_Pass.LoginWithAllUsersFromDataSource();

            if (success)
            {
                Report.Log(ReportLevel.Info, "LoginRetry", "Validating main window...");
                Validate.AttributeEqual(repo.CCIMainWindow.CreateOrOpenRecipeInfo,
                    "Text", "Create or open recipe.");
                Delay.Milliseconds(100);

                Report.Screenshot(ReportLevel.Info, "User", "Main window after login",
                    repo.CCIMainWindow.CreateOrOpenRecipe, false, new RecordItemIndex(0));
                Report.Screenshot(ReportLevel.Info, "User", "Full main window",
                    repo.CCIMainWindow.Self, false, new RecordItemIndex(1));
            }
            else
            {
                throw new Ranorex.ValidationException(
                    "Tất cả credentials đều thất bại. Không thể login.");
            }
        }
    }
}
