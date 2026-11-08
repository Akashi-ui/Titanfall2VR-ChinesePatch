using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
namespace Zecole.TitanfallKorean {
 internal static class Manager {
  internal const string ManifestUrl="https://raw.githubusercontent.com/CircuitLord/CircuitLordVRModInstaller/main/manifest-v3.json";
  internal static string Installed(string root,string relative,string key) {
   try {var d=new JavaScriptSerializer().Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(root,relative)));return d[key] as string ?? "无法确认";} catch {return "未安装 / 无法确认";}
  }
  internal static async Task<string> VrVersion() {
   try {ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
    using(var c=new HttpClient()){c.Timeout=TimeSpan.FromSeconds(8);c.MaxResponseContentBufferSize=1024*1024;
     var d=new JavaScriptSerializer().Deserialize<Dictionary<string,object>>(await c.GetStringAsync(ManifestUrl));
     var v=(string)((Dictionary<string,object>)d["titanfall2vr"])["version"];UpdateChecker.ParseVersion(v);return v;}}
   catch {return null;}
  }
  internal static System.Diagnostics.ProcessStartInfo CreateVrLaunch(string root) {
   root=Path.GetFullPath(root);
   foreach(var relative in new[]{"Titanfall2.exe","Titanfall2VRLauncher.exe",@"TF2VR\Northstar.dll",@"TF2VR\plugins\Titanfall2VR.dll",@"TF2VR\tools\crash_monitor.exe",@"TF2VR\tools\launch.json"})
    if(!File.Exists(Path.Combine(root,relative)))throw new IOException("VR 模式文件缺失。请通过官方安装程序检查安装状态: "+relative);
   var settings=new JavaScriptSerializer().Deserialize<Dictionary<string,string[]>>(File.ReadAllText(Path.Combine(root,@"TF2VR\tools\launch.json")));
   var args=new List<string>();
   foreach(var key in new[]{"arguments","vrArguments"})foreach(var arg in settings[key]) {
    var value=arg.Replace("{profile}","TF2VR").Replace("{width}","1280").Replace("{height}","720").Replace("{sound}","1");
    if(value.Contains("{")||value.Contains("}"))throw new IOException("需要检查新的 VR 启动设置。请通过官方安装程序启动。");
    args.Add(Program.Quote(value));
   }
   var info=new System.Diagnostics.ProcessStartInfo(Path.Combine(root,@"TF2VR\tools\crash_monitor.exe")) {WorkingDirectory=root,UseShellExecute=false};
   info.Arguments=Program.Quote(Path.Combine(root,"TF2VR"))+" "+Program.Quote(Path.Combine(root,"Titanfall2VRLauncher.exe"))+" "+String.Join(" ",args);
   var keys=new List<string>();foreach(string key in info.EnvironmentVariables.Keys)keys.Add(key);
   foreach(var key in keys)if(key.StartsWith("TF2VR_",StringComparison.OrdinalIgnoreCase)||Array.Exists(new[]{"VR_PATHREG_OVERRIDE","VR_CONFIG_PATH","VR_LOG_PATH","XR_RUNTIME_JSON"},v=>v.Equals(key,StringComparison.OrdinalIgnoreCase)))info.EnvironmentVariables.Remove(key);
   info.EnvironmentVariables["TF2VR_OPENXR"]="1";
   return info;
  }
  private static string Fingerprint(string root) {
   var files=new List<string>(Directory.GetFiles(Path.Combine(root,@"TF2VR\mods\Korean.MenuTest"),"*",SearchOption.AllDirectories));
   files.Add(Path.Combine(root,@"TF2VR\plugins\Titanfall2VR.dll"));files.Add(Path.Combine(root,@"TF2VR\plugins\Korean.CaptionLayout.dll"));
   files.Add(Path.Combine(root,@"TF2VR\Northstar.dll"));
   var cockpit=Path.Combine(root,@"TF2VR\mods\Titanfall2VR.Cockpit\mod");
   files.Add(Path.Combine(cockpit,@"resource\tf2vr\startup\text.r8"));
   foreach(var folder in new[]{"scripts",@"resource\ui"}) {
    var path=Path.Combine(cockpit,folder);if(Directory.Exists(path))files.AddRange(Directory.GetFiles(path,"*",SearchOption.AllDirectories));
   }
   files.Sort(StringComparer.OrdinalIgnoreCase);var text=new System.Text.StringBuilder(Path.GetFullPath(root).ToLowerInvariant());
   using(var sha=SHA256.Create())foreach(var file in files){text.Append(file);using(var stream=File.OpenRead(file))text.Append(BitConverter.ToString(sha.ComputeHash(stream)));}
   using(var sha=SHA256.Create())return BitConverter.ToString(sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(text.ToString())));
  }
  private static string ReadyFile(string root) {
   string name;using(var sha=SHA256.Create())name=BitConverter.ToString(sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(Path.GetFullPath(root).ToLowerInvariant())));
   var dir=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Zecole","Titanfall2VR","Ready");Directory.CreateDirectory(dir);return Path.Combine(dir,name+".txt");
  }
  internal static bool IsReady(string root,string version) {
   try {
    if(Installed(root,@"TF2VR\mods\Korean.MenuTest\mod.json","Version")!=version)return false;
    var enabled=new JavaScriptSerializer().Deserialize<Dictionary<string,Dictionary<string,bool>>>(File.ReadAllText(Path.Combine(root,@"TF2VR\enabledmods.json")));
    if(!enabled["Korean.MenuTest"][version])return false;
    return File.ReadAllText(ReadyFile(root))==Fingerprint(root);
   }catch{return false;}
  }
  internal static void MarkReady(string root){File.WriteAllText(ReadyFile(root),Fingerprint(root));}
  internal static void Verify(string path,string hash) {
   using(var sha=SHA256.Create()) using(var input=File.OpenRead(path)) {
    if(!BitConverter.ToString(sha.ComputeHash(input)).Replace("-","").Equals(hash,StringComparison.OrdinalIgnoreCase))throw new IOException("下载的文件验证失败。请重试。");
   }
  }
  internal static async Task<string> Download(UpdateResult release, IProgress<int> progress) {
   if(release.Url==null || release.Sha256==null)throw new IOException("没有可验证的安装文件。请检查是否有最新版本。");
   var folder=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Zecole","Titanfall2VR","Updates",Guid.NewGuid().ToString("N"));Directory.CreateDirectory(folder);
   var path=Path.Combine(folder,"Titanfall2VR-Korean-Setup-v"+release.Version+".exe");
   try {
    using(var client=new HttpClient()) {client.Timeout=TimeSpan.FromMinutes(5);client.DefaultRequestHeaders.UserAgent.ParseAdd("Zecole-KoreanPatch");
     using(var response=await client.GetAsync(release.Url,HttpCompletionOption.ResponseHeadersRead)) {response.EnsureSuccessStatusCode();
      long length=response.Content.Headers.ContentLength ?? 0,total=0;
      if(length>100*1024*1024)throw new IOException("安装文件大小超出预期范围。");
      using(var input=await response.Content.ReadAsStreamAsync())using(var output=File.Create(path)) {var buffer=new byte[65536];int count;
       while((count=await input.ReadAsync(buffer,0,buffer.Length))>0) {total+=count;if(total>100*1024*1024)throw new IOException("安装文件太大。");await output.WriteAsync(buffer,0,count);progress.Report(length>0?(int)(total*100/length):0);}
      }
     }
    }
    Verify(path,release.Sha256);return path;
   } catch {if(File.Exists(path))File.Delete(path);throw;}
  }
 }
}
