using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using Microsoft.Win32;

namespace Zecole.TitanfallKorean
{
    internal static class Program
    {
        [STAThread]
        private static int Main(string[] args)
        {
            if (args.Length == 2 && args[0] == "--verify-package")
            {
                try { ExtractPayload(args[1]); return 0; }
                catch (Exception ex) { File.WriteAllText(args[1] + ".error.txt", ex.ToString()); return 1; }
            }
            if(args.Length==3 && args[0]=="--worker" && args[1]=="Install") {
                try {if(!IsAdministrator())return 1;InstallerForm.RunInstaller("Install",args[2]);return 0;}catch{return 1;}
            }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            var form = new InstallerForm();
            if (args.Length == 3 && args[0] == "--apply" && (args[1] == "Install" || args[1] == "Restore"))
                form.Shown += async delegate { await form.Apply(args[1], args[2]); };
            if(args.Length==2 && args[0]=="--play")form.Shown+=async delegate{await form.PlayLatest(args[1]);};
            Application.Run(form);
            return 0;
        }

        internal static void ExtractPayload(string destination)
        {
            if (Directory.Exists(destination)) throw new IOException("临时文件夹已存在。");
            Directory.CreateDirectory(destination);
            string root = Path.GetFullPath(destination).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
            using (var zip = new ZipArchive(stream, ZipArchiveMode.Read))
            {
                foreach (var entry in zip.Entries)
                {
                    string path = Path.GetFullPath(Path.Combine(root, entry.FullName.Replace('/', Path.DirectorySeparatorChar)));
                    if (!path.StartsWith(root, StringComparison.OrdinalIgnoreCase)) throw new IOException("安装包包含无效的文件路径。");
                    if (entry.Name.Length == 0) { Directory.CreateDirectory(path); continue; }
                    Directory.CreateDirectory(Path.GetDirectoryName(path));
                    entry.ExtractToFile(path, false);
                }
            }
            var hashes = new JavaScriptSerializer().Deserialize<Dictionary<string, string>>(File.ReadAllText(Path.Combine(root, "package-hashes.json")));
            using (var sha = SHA256.Create())
            {
                foreach (var pair in hashes)
                {
                    string path = Path.GetFullPath(Path.Combine(root, pair.Key.Replace('/', Path.DirectorySeparatorChar)));
                    if (!path.StartsWith(root, StringComparison.OrdinalIgnoreCase)) throw new IOException("校验路径无效。");
                    using (var input = File.OpenRead(path))
                    {
                        string actual = BitConverter.ToString(sha.ComputeHash(input)).Replace("-", "");
                        if (!actual.Equals(pair.Value, StringComparison.OrdinalIgnoreCase)) throw new IOException("安装文件校验失败：" + pair.Key);
                    }
                }
            }
        }

        internal static bool IsGame(string path)
        {
            return !String.IsNullOrWhiteSpace(path) && File.Exists(Path.Combine(path, "Titanfall2.exe"));
        }

        internal static List<string> FindGames()
        {
            var candidates = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            Action<string> add = delegate(string path) {
                try { if (IsGame(path)) candidates.Add(Path.GetFullPath(path).TrimEnd('\\')); } catch { }
            };
            add(AppDomain.CurrentDomain.BaseDirectory);
            foreach (RegistryView view in new[] { RegistryView.Registry64, RegistryView.Registry32 })
            foreach (RegistryHive hive in new[] { RegistryHive.LocalMachine, RegistryHive.CurrentUser })
            {
                try
                {
                    using (var reg = RegistryKey.OpenBaseKey(hive, view))
                    {
                        using (var game = reg.OpenSubKey(@"SOFTWARE\Respawn\Titanfall2"))
                            if (game != null) add(game.GetValue("Install Dir") as string);
                        using (var uninstall = reg.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"))
                        {
                            if (uninstall != null) foreach (string name in uninstall.GetSubKeyNames())
                            using (var item = uninstall.OpenSubKey(name))
                            {
                                if (item == null) continue;
                                string title = item.GetValue("DisplayName") as string;
                                if (title != null && title.IndexOf("Titanfall", StringComparison.OrdinalIgnoreCase) >= 0)
                                    add(item.GetValue("InstallLocation") as string);
                            }
                        }
                        using (var steam = reg.OpenSubKey(@"SOFTWARE\Valve\Steam"))
                        {
                            if (steam == null) continue;
                            string path = (steam.GetValue("SteamPath") ?? steam.GetValue("InstallPath")) as string;
                            AddSteamLibrary(path, add);
                            if (String.IsNullOrWhiteSpace(path)) continue;
                            string libraries = Path.Combine(path, @"steamapps\libraryfolders.vdf");
                            if (File.Exists(libraries)) foreach (Match m in Regex.Matches(File.ReadAllText(libraries), "\"path\"\\s+\"([^\"]+)\""))
                                AddSteamLibrary(m.Groups[1].Value.Replace(@"\\", @"\"), add);
                        }
                    }
                }
                catch { }
            }
            foreach (DriveInfo drive in DriveInfo.GetDrives())
            {
                if (drive.DriveType != DriveType.Fixed || !drive.IsReady) continue;
                foreach (string relative in new[] { @"Program Files\EA Games\Titanfall2", @"Program Files (x86)\Origin Games\Titanfall2", @"EA Games\Titanfall2", @"SteamLibrary\steamapps\common\Titanfall2", @"Program Files (x86)\Steam\steamapps\common\Titanfall2" })
                    add(Path.Combine(drive.RootDirectory.FullName, relative));
            }
            return new List<string>(candidates);
        }

        private static void AddSteamLibrary(string library, Action<string> add)
        {
            if (String.IsNullOrWhiteSpace(library)) return;
            add(Path.Combine(library, @"steamapps\common\Titanfall2"));
            string manifest = Path.Combine(library, @"steamapps\appmanifest_1237970.acf");
            if (!File.Exists(manifest)) return;
            Match m = Regex.Match(File.ReadAllText(manifest), "\"installdir\"\\s+\"([^\"]+)\"");
            if (m.Success) add(Path.Combine(library, "steamapps", "common", m.Groups[1].Value));
        }

        internal static bool IsAdministrator()
        {
            using (var id = WindowsIdentity.GetCurrent()) return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
        }

        internal static string Quote(string value)
        {
            if (value.Contains("\"") || value.Contains("\r") || value.Contains("\n")) throw new ArgumentException("路径无效。");
            return "\"" + value.TrimEnd('\\') + "\"";
        }
    }

    internal sealed class InstallerForm : Form
    {
        private readonly Label pathBox = new Label();
        private readonly ToolTip pathTip = new ToolTip();
        private readonly Button browse = new Button();
        private readonly Button install = new Button();
        private readonly Button restore = new Button();
        private readonly Label status = new Label();
        private readonly TextBox messages = new TextBox();
        private readonly ProgressBar progress = new ProgressBar();
        private readonly Label updateStatus = new Label();
        private readonly Button checkUpdate = new Button();
        private readonly LinkLabel downloadUpdate = new LinkLabel();
        private bool busy;

        private readonly Label vrStatus = new Label();
        private readonly Label patchStatus = new Label();
        private readonly Label vrBadge = new Label();
        private readonly Label patchBadge = new Label();
        private readonly Button update = new Button();
        private readonly Button launch = new Button();
        private readonly Button vrInstaller = new Button();
        private UpdateResult latest;
        private string latestVr;
        private bool checking;
        private static readonly Color Ink = Color.FromArgb(229,235,244);
        private static readonly Color Muted = Color.FromArgb(154,173,194);
        private static readonly Color Card = Color.FromArgb(29,37,48);
        private static readonly Color Accent = Color.FromArgb(74,169,225);
        private Label TextLabel(string text,int x,int y,int width,int height,float size,Color color) {
            var c=new Label {Text=text,Left=x,Top=y,Width=width,Height=height,ForeColor=color,BackColor=Color.Transparent,Font=new Font("Microsoft YaHei UI",size)};
            if(y>=143 && y<464)c.BackColor=Card;Controls.Add(c);return c;
        }
        private void ButtonStyle(Button b,string text,int x,int y,int w,bool primary) {
            b.Text=text;b.SetBounds(x,y,w,38);b.FlatStyle=FlatStyle.Flat;b.FlatAppearance.BorderSize=1;
            b.FlatAppearance.BorderColor=primary?Accent:Color.FromArgb(58,72,89);b.BackColor=primary?Accent:Card;b.ForeColor=primary?Color.FromArgb(13,26,38):Ink;b.Cursor=Cursors.Hand;Controls.Add(b);
        }
        private readonly List<Panel> cards = new List<Panel>();
        private void CardAt(int y,int height) {
            var panel=new Panel{Left=24,Top=y,Width=752,Height=height,BackColor=Card};
            cards.Add(panel);Controls.Add(panel);
        }
        private void AttachCardContents() {
            // Card content must be children, not overlapping sibling windows.
            // DrawToBitmap can paint siblings in a different order from live HWNDs.
            var controls=new List<Control>();foreach(Control c in Controls)controls.Add(c);
            foreach(var card in cards)foreach(var c in controls) {
                if(c is Panel || !card.Bounds.Contains(c.Bounds))continue;
                var location=new Point(c.Left-card.Left,c.Top-card.Top);
                card.Controls.Add(c);c.Location=location;
            }
        }
        internal InstallerForm()
        {
            Text="Zecole · 泰坦陨落2 VR";Font=new Font("Microsoft YaHei UI",10F);BackColor=Color.FromArgb(16,21,28);ForeColor=Ink;
            AutoScaleMode=AutoScaleMode.Dpi;ClientSize=new Size(800,750);FormBorderStyle=FormBorderStyle.FixedDialog;MaximizeBox=false;StartPosition=FormStartPosition.CenterScreen;
            TextLabel("ZECOLE",26,19,190,27,14,Accent);
            TextLabel("VR 简体中文补丁  /  v"+Assembly.GetExecutingAssembly().GetName().Version.ToString(3),510,25,267,23,10,Muted);
            var hero=new Panel{Left=24,Top=66,Width=752,Height=255};
            using(var stream=Assembly.GetExecutingAssembly().GetManifestResourceStream("hero.jpg"))if(stream!=null)hero.BackgroundImage=new Bitmap(stream);
            hero.BackgroundImageLayout=ImageLayout.Stretch;Controls.Add(hero);
            var caption=new Label{Text="TITANFALL 2  /  VR",Dock=DockStyle.Bottom,Height=43,BackColor=Color.FromArgb(24,32,42),ForeColor=Ink,Font=new Font("Segoe UI",17,FontStyle.Bold),Padding=new Padding(15,5,0,0)};hero.Controls.Add(caption);
            CardAt(334,77);
            TextLabel("VR 模组",40,341,170,23,10,Ink);
            TextLabel("简体中文补丁",410,341,170,23,10,Ink);
            vrStatus.SetBounds(40,365,340,42);vrStatus.ForeColor=Muted;vrStatus.BackColor=Card;Controls.Add(vrStatus);
            patchStatus.SetBounds(410,365,346,42);patchStatus.ForeColor=Muted;patchStatus.BackColor=Card;Controls.Add(patchStatus);
            vrBadge.SetBounds(252,341,128,23);patchBadge.SetBounds(628,341,128,23);
            foreach(var badge in new[]{vrBadge,patchBadge}){badge.TextAlign=ContentAlignment.MiddleRight;badge.BackColor=Card;Controls.Add(badge);}
            ButtonStyle(launch,"▶ 检查并启动带有最新中文补丁的游戏",24,427,752,true);launch.Height=61;launch.Font=new Font("Microsoft YaHei UI",15,FontStyle.Bold);
            launch.Click+=async delegate{await PlayLatest(pathBox.Text);};
            status.SetBounds(26,501,748,27);status.Text="一键完成版补丁版本检查、安装和游戏启动。";Controls.Add(status);
            updateStatus.SetBounds(26,532,748,25);updateStatus.ForeColor=Muted;Controls.Add(updateStatus);
            progress.SetBounds(24,562,752,4);progress.Style=ProgressBarStyle.Marquee;progress.Visible=false;Controls.Add(progress);
            TextLabel("游戏目录",26,579,88,27,9,Muted);pathBox.SetBounds(126,575,527,31);pathBox.BackColor=Card;pathBox.ForeColor=Ink;pathBox.AutoEllipsis=true;pathBox.TextAlign=ContentAlignment.MiddleLeft;pathBox.Padding=new Padding(10,0,10,0);Controls.Add(pathBox);
            var games=Program.FindGames();if(games.Count>0)pathBox.Text=games[0];pathTip.SetToolTip(pathBox,pathBox.Text);
            ButtonStyle(browse,"浏览",665,575,111,false);browse.Height=31;
            browse.Click+=delegate{using(var d=new FolderBrowserDialog{Description="选择包含 Titanfall2.exe 的文件夹",ShowNewFolderButton=false})if(d.ShowDialog(this)==DialogResult.OK)pathBox.Text=d.SelectedPath;};
            ButtonStyle(vrInstaller,"下载 VR 模组",24,621,252,false);vrInstaller.Click+=delegate{Process.Start(new ProcessStartInfo("https://github.com/CircuitLord/CircuitLordVRModInstaller/releases/latest"){UseShellExecute=true});};
            ButtonStyle(restore,"移除中文补丁",288,621,174,false);restore.Click+=async delegate{await Apply("Restore",pathBox.Text);};
            downloadUpdate.Text="更新日志 · GitHub";downloadUpdate.SetBounds(486,630,240,27);downloadUpdate.LinkColor=Accent;Controls.Add(downloadUpdate);downloadUpdate.LinkClicked+=delegate{Process.Start(new ProcessStartInfo(UpdateChecker.LatestPage){UseShellExecute=true});};
            messages.SetBounds(26,674,748,51);messages.Multiline=true;messages.ReadOnly=true;messages.BorderStyle=BorderStyle.None;messages.BackColor=BackColor;messages.ForeColor=Muted;messages.Text="由 YouTube 创作者 Zecole 制作韩语插件,？？？进行汉化  ·  请在游戏设置 → 音频中开启字幕。\r\n本补丁基于 VR 1.0.25 翻译 · 游戏内显示效果仍需实测。";Controls.Add(messages);
            AttachCardContents();pathBox.TextChanged+=delegate{pathTip.SetToolTip(pathBox,pathBox.Text);RefreshInstalled();};Shown+=async delegate{RefreshInstalled();await CheckUpdate();};
            FormClosing+=delegate(object sender,FormClosingEventArgs e){if(busy)e.Cancel=true;};
        }
        
private static string GetRunningGameProcesses()
{
    string[] processNames =
    {
        "Titanfall2",
        "Titanfall2VRLauncher"
    };

    var found = new List<string>();

    foreach (string name in processNames)
    {
        foreach (Process process in Process.GetProcessesByName(name))
        {
            using (process)
            {
                try
                {
                    found.Add(
                        "进程名：" + process.ProcessName +
                        "    PID：" + process.Id
                    );
                }
                catch (InvalidOperationException)
                {
                    // 进程可能在检查期间自行退出
                }
                catch (System.ComponentModel.Win32Exception)
                {
                    found.Add("进程名：" + name + "    PID：无法读取");
                }
            }
        }
    }

    if (found.Count == 0)
        return null;

    return "检测到以下进程仍在运行：\r\n"
    + String.Join("\r\n", found.ToArray())
    + "\r\n这些进程可能导致安装出错。"
    + "\r\n打开任务管理器并关闭它们，然后重新用本安装器安装补丁。";
}
        internal async Task PlayLatest(string root) {
            if(busy)return;
            SetBusy(true);
            try {
                pathBox.Text=root;
                if(Process.GetProcessesByName("Titanfall2").Length>0||Process.GetProcessesByName("Titanfall2VRLauncher").Length>0)throw new IOException("请先关闭正在运行的游戏或错误窗口。");
                var launchInfo=Manager.CreateVrLaunch(root);
                status.Text="正在检查最新的中文补丁…";
                var release=await UpdateChecker.CheckAsync(Assembly.GetExecutingAssembly().GetName().Version);
                if(release.Version==null)throw new IOException("无法获取最新版本。请检查网络连接后重试。");
                if(release.Newer) {
                    status.Text="正在下载最新补丁…";
                    var exe=await Manager.Download(release,new Progress<int>(v=>status.Text="下载最新补丁 · "+v+"%"));
                    Process.Start(new ProcessStartInfo(exe,"--play "+Program.Quote(root)){UseShellExecute=true});SetBusy(false);Close();return;
                }
                Version installedVersion;
                if(Version.TryParse(Manager.Installed(root,@"TF2VR\mods\Korean.MenuTest\mod.json","Version"),out installedVersion) && UpdateChecker.ParseVersion(installedVersion.ToString())>UpdateChecker.ParseVersion(Assembly.GetExecutingAssembly().GetName().Version.ToString()))throw new IOException("설치된 简体中文补丁가 이 프로그램보다 새 버전입니다. 최신 프로그램으로 실행해 주세요.");
                if(!Manager.IsReady(root,Assembly.GetExecutingAssembly().GetName().Version.ToString(3))) {
                    status.Text="正在应用中文补丁…";
                    if(Program.IsAdministrator())await Task.Run(()=>RunInstaller("Install",root));
                    else {
                        var worker=Process.Start(new ProcessStartInfo(Application.ExecutablePath,"--worker Install "+Program.Quote(root)){UseShellExecute=true,Verb="runas",WindowStyle=ProcessWindowStyle.Hidden});
                        await Task.Run(()=>worker.WaitForExit());int code=worker.ExitCode;worker.Dispose();if(code!=0)throw new IOException("应用补丁失败。请检查您的游戏文件夹及安装状态。");
                    }
                    Manager.MarkReady(root);
                }
                Process.Start(launchInfo);status.Text="已完成最新补丁检查，并已请求启动 VR 游戏。";RefreshInstalled();
            }catch(System.ComponentModel.Win32Exception ex){status.Text=ex.NativeErrorCode==1223?"已取消管理员权限请求。":"无法启动。";messages.Text=ex.Message;}
            catch(Exception ex){status.Text="操作未能完成。";messages.Text=ex.Message;}
            finally{SetBusy(false);}
        }
        private void RefreshInstalled() {
            var vr=Manager.Installed(pathBox.Text,@".circuitlord-vr-mods\Titanfall2VR.json","version");
            var patch=Manager.Installed(pathBox.Text,@"TF2VR\mods\Korean.MenuTest\mod.json","Version");
            ShowVersion(vrStatus,vrBadge,vr,latestVr);
            ShowVersion(patchStatus,patchBadge,patch,latest==null?null:latest.Version);
        }
        internal static string VersionState(string installed,string remote,bool loading) {
            Version local;
            if(!Version.TryParse(installed,out local))return "需要确认安装状态";
            if(remote==null)return loading?"正在检查":"无法确认";
            try {return UpdateChecker.ParseVersion(installed)<UpdateChecker.ParseVersion(remote)?"需要更新":"已是最新版本";}
            catch{return "无法确认";}
        }
        private void ShowVersion(Label label,Label badge,string installed,string remote) {
            var state=VersionState(installed,remote,checking);
            label.Text="已安装版本   "+installed+"\r\n最新发布   "+(remote??"正在检查 / 验证连接");
            label.ForeColor=Muted;badge.Text=state;
            badge.ForeColor=state=="已是最新版本"?Color.FromArgb(89,213,162):state=="需要更新"?Color.FromArgb(255,194,94):Muted;
        }

        private void SetBusy(bool value) {
            busy=value;install.Enabled=restore.Enabled=browse.Enabled=pathBox.Enabled=launch.Enabled=vrInstaller.Enabled=!value;
            checkUpdate.Enabled=!value&&!checking;update.Enabled=!value&&latest!=null&&latest.Newer&&latest.Url!=null;
            progress.Visible=value;
        }
        private async Task CheckUpdate() {
            if(checking||busy)return;checking=true;checkUpdate.Enabled=false;RefreshInstalled();updateStatus.Text="正在检查在线版本…";
            var patchTask=UpdateChecker.CheckAsync(Assembly.GetExecutingAssembly().GetName().Version);var vrTask=Manager.VrVersion();
            await Task.WhenAll(patchTask,vrTask);if(IsDisposed)return;
            latest=patchTask.Result;latestVr=vrTask.Result;checking=false;
            updateStatus.Text=latest.Message;RefreshInstalled();SetBusy(busy);
        }
        private async Task DownloadUpdate() {
            if(busy||latest==null||!latest.Newer)return;
            if(!Program.IsGame(pathBox.Text)){messages.Text="请先选择游戏安装目录。";return;}
            SetBusy(true);
            try {
                status.Text="正在下载最新的中文补丁…";
                var file=await Manager.Download(latest,new Progress<int>(p=>status.Text="下载中文补丁· "+p+"%"));
                status.Text="文件校验完成 · 正在切换到新版安装器。";
                Process.Start(new ProcessStartInfo(file,"--apply Install "+Program.Quote(pathBox.Text)){UseShellExecute=true});
                SetBusy(false);Close();
            }catch(Exception ex){status.Text="更新未能完成。";messages.Text=ex.Message+"\r\n现有安装不会受到影响。";}
            finally{SetBusy(false);}
        }

        internal async Task Apply(string action, string gamePath)
        {
            if (busy) return;
            try
            {
                if (!Program.IsGame(gamePath)) throw new IOException("请选择包含 Titanfall2.exe 的游戏安装目录。");
                gamePath = Path.GetFullPath(gamePath);
                if (!File.Exists(Path.Combine(gamePath, "Titanfall2VRLauncher.exe")) || !File.Exists(Path.Combine(gamePath, @".circuitlord-vr-mods\Titanfall2VR.json")))
                    throw new IOException("请先安装 VR 模组.");
                string runningProcesses = GetRunningGameProcesses();//238-280行
                if (runningProcesses != null)
                  throw new IOException(runningProcesses);
                if (!Program.IsAdministrator())
                {
                    var info = new ProcessStartInfo(Application.ExecutablePath, "--apply " + action + " " + Program.Quote(gamePath)) { UseShellExecute = true, Verb = "runas" };
                    Process.Start(info);
                    Close();
                    return;
                }
                pathBox.Text = gamePath;
                SetBusy(true);
                status.Text = action == "Install" ? "正在安装中文补丁…" : "正在恢复原始文件…";
                messages.Text = status.Text;
                string result = await Task.Run(delegate { return RunInstaller(action, gamePath); });
                status.Text = action == "Install" ? "安装完成！请通过 VR 模组安装程序启动游戏。" : "已恢复原始文件。";
                messages.Text = status.Text + "\r\n\r\n当前的韩语补丁基于 VR 模组 1.0.25 版本。\r\n如果模组版本高于此版本，可能会出现一些问题。\r\n游戏内的实际表现有待进一步验证。";
            }
            catch (System.ComponentModel.Win32Exception ex)
            {
                status.Text = ex.NativeErrorCode == 1223 ? "已取消管理员权限请求。" : ex.Message;
                messages.Text = status.Text;
            }
            catch (Exception ex) { status.Text = "操作未能完成。"; messages.Text = ex.Message; }
            finally { SetBusy(false); RefreshInstalled(); }
        }

        internal static string RunInstaller(string action, string gamePath)
        {
            string tempRoot = Path.GetFullPath(Path.GetTempPath());
            string temp = Path.Combine(tempRoot, "Zecole-TF2VR-" + Guid.NewGuid().ToString("N"));
            try
            {
                Program.ExtractPayload(temp);
                string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
                var info = new ProcessStartInfo(ps, "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File " + Program.Quote(Path.Combine(temp, "Install.ps1")) + " -Action " + action + " -GameRoot " + Program.Quote(gamePath)) {
                    UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true,
                    StandardOutputEncoding = Encoding.UTF8, StandardErrorEncoding = Encoding.UTF8
                };
                info.EnvironmentVariables["PSModulePath"] = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\Modules");
                using (var process = Process.Start(info))
                {
                    Task<string> stdout = process.StandardOutput.ReadToEndAsync();
                    Task<string> stderr = process.StandardError.ReadToEndAsync();
                    process.WaitForExit(); Task.WaitAll(stdout, stderr);
                    string output = stdout.Result + stderr.Result;
                    if (process.ExitCode != 0) throw new IOException(output.Trim());
                    return output;
                }
            }
            finally
            {
                // Only the unique child created by this invocation can be removed.
                string full = Path.GetFullPath(temp);
                if (Path.GetDirectoryName(full).TrimEnd('\\').Equals(tempRoot.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase)
                    && Path.GetFileName(full).StartsWith("Zecole-TF2VR-", StringComparison.Ordinal) && Directory.Exists(full))
                    try { Directory.Delete(full, true); } catch { }
            }
        }
    }
}
