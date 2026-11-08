using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Script.Serialization;

namespace Zecole.TitanfallKorean
{
    internal sealed class UpdateResult
    {
        internal string Message;
        internal bool Newer;
        internal string Version, Url, Sha256;
    }

    internal static class UpdateChecker
    {
       internal const string LatestPage = "https://github.com/Akashi-ui/Titanfall2VR-ChinesePatch/releases/latest";
        internal const string Api = "https://api.github.com/repos/Akashi-ui/Titanfall2VR-ChinesePatch/releases/latest";

        internal static Version ParseVersion(string tag)
        {
            if (String.IsNullOrEmpty(tag) || !System.Text.RegularExpressions.Regex.IsMatch(tag, @"\Av?\d+\.\d+\.\d+(\.\d+)?\z"))
                throw new FormatException();
            Version v = Version.Parse(tag.TrimStart('v'));
            return new Version(v.Major, v.Minor, v.Build, Math.Max(0, v.Revision));
        }

        internal static UpdateResult Parse(string json, Version current)
        {
            var data = new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(json);
            if (data == null || !data.ContainsKey("draft") || !(data["draft"] is bool) || (bool)data["draft"] ||
                !data.ContainsKey("prerelease") || !(data["prerelease"] is bool) || (bool)data["prerelease"] ||
                !data.ContainsKey("tag_name") || !(data["tag_name"] is string)) throw new FormatException();
            Version latest = ParseVersion((string)data["tag_name"]);
            int comparison = latest.CompareTo(ParseVersion(current.ToString()));
            string version = latest.ToString(latest.Revision == 0 ? 3 : 4);
            string url = null, digest = null;
            if (data.ContainsKey("assets")) foreach (object item in (System.Collections.IEnumerable)data["assets"])
            {
                var asset = item as Dictionary<string, object>;
                if (asset == null || !asset.ContainsKey("name") || (string)asset["name"] != "Titanfall2VR-Chinese-Setup-v" + version + ".exe") continue;
                url = asset.ContainsKey("browser_download_url") ? asset["browser_download_url"] as string : null;
                digest = asset.ContainsKey("digest") ? asset["digest"] as string : null;
                if (url == null || !url.StartsWith("https://github.com/Akashi-ui/Titanfall2VR-ChinesePatch/releases/download/", StringComparison.Ordinal) ||
                    digest == null || !System.Text.RegularExpressions.Regex.IsMatch(digest, "^sha256:[a-fA-F0-9]{64}$")) { url = null; digest = null; }
            }
            return new UpdateResult {
                Version = version, Url = url, Sha256 = digest == null ? null : digest.Substring(7),
                Newer = comparison > 0,
                Message = comparison > 0 ? "发现新版本 v" + version + "，请下载最新版本。" :
                    comparison == 0 ? "当前已是最新版本。（GitHub v" + version + "）" :
                    "GitHub 上的最新稳定版为 v" + version + ""
            };
        }

        internal static async Task<UpdateResult> CheckAsync(Version current, HttpMessageHandler handler = null, TimeSpan? timeout = null)
        {
            try
            {
                ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
                using (var client = handler == null ? new HttpClient() : new HttpClient(handler))
                {
                    client.Timeout = timeout ?? TimeSpan.FromSeconds(8);
                    client.MaxResponseContentBufferSize = 1024 * 1024;
                    client.DefaultRequestHeaders.UserAgent.ParseAdd("Akashi-ui-Titanfall2VR-Chinese-Installer/" + current);
                    client.DefaultRequestHeaders.Accept.ParseAdd("application/vnd.github+json");
                    using (var response = await client.GetAsync(Api).ConfigureAwait(false))
                    {
                        response.EnsureSuccessStatusCode();
                        return Parse(await response.Content.ReadAsStringAsync().ConfigureAwait(false), current);
                    }
                }
            }
            catch (Exception)
            {
                return new UpdateResult { Message = "无法检查最新版本，但你仍然可以继续安装。" };
            }
        }
    }
}
