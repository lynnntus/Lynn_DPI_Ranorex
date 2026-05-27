///////////////////////////////////////////////////////////////////////////////
//
// LoginRetry - Credential retry module.
// Iterates CSV rows via data binding. Stops after first successful login.
// Sets Login_Pass.Instance credentials for downstream modules.
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

        private static bool credentialFound = false;

        [TestVariable("b2c3d4e5-f6a7-8901-bcde-f12345678901")]
        public string UserName { get; set; }

        [TestVariable("c3d4e5f6-a7b8-9012-cdef-123456789012")]
        public string Password { get; set; }

        public LoginRetry()
        {
            UserName = "";
            Password = "";
        }

        void ITestModule.Run()
        {
            Mouse.DefaultMoveTime = 300;
            Keyboard.DefaultKeyPressTime = 100;
            Delay.SpeedFactor = 1.00;

            if (credentialFound)
            {
                Report.Log(ReportLevel.Info, "LoginRetry",
                    string.Format("Valid credential da tim thay truoc do. Skip CSV row '{0}'.", UserName));
                return;
            }

            Report.Log(ReportLevel.Info, "LoginRetry",
                string.Format("Thu login voi user '{0}'...", UserName));

            repo.CCILoginWindow.SelfInfo.WaitForExists(Login_Pass.LOGIN_WINDOW_TIMEOUT_MS);

            Report.Screenshot(ReportLevel.Info, "LoginRetry",
                string.Format("Trang thai UI truoc khi login voi user '{0}'.", UserName),
                repo.CCILoginWindow.Self, false);

            bool success = Login_Pass.TryLoginWithUser(UserName, Password);

            if (success)
            {
                Report.Log(ReportLevel.Success, "LoginRetry",
                    string.Format("Login thanh cong voi user '{0}'.", UserName));

                Login_Pass.Instance.UserName = UserName;
                Login_Pass.Instance.Password = Password;

                credentialFound = true;
            }
            else
            {
                Report.Log(ReportLevel.Warn, "LoginRetry",
                    string.Format("Login that bai voi user '{0}'. Neu khong co row nao thanh cong, default credentials se duoc dung.", UserName));

                Report.Screenshot(ReportLevel.Warn, "LoginRetry",
                    string.Format("Login that bai voi user '{0}'. Screenshot de debug.", UserName),
                    repo.CCILoginWindow.Self, false);

                Login_Pass.ClearLoginFields();
            }
        }
    }
}
