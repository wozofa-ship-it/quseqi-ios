# 取色器 iOS 版打包说明

把网页版取色器装进原生 App 壳（WKWebView），通过 GitHub Actions 在云端 Mac 上编译出 IPA。

## 步骤

1. 注册/登录 GitHub，新建一个空仓库（比如叫 `quseqi-ios`）。
2. 把本目录所有文件传到仓库（网页端 Add file → Upload files，或 `git push`）。
3. 打开仓库的 Actions 页面，启用 workflow，然后手动点 Run workflow（或直接 push 也会自动触发）。
4. 等几分钟构建完成，在页面底部的 Artifacts 下载 `QuSeQi-unsigned-ipa`，解压得到 `QuSeQi-unsigned.ipa`。

## 安装到 iPhone（重要）

这个 IPA 是**未签名**的，不能直接安装，需要自签：

- **Sideloadly**（Win/Mac）或 **AltStore**：用免费 Apple ID 自签后安装，7 天过期需重签（AltStore 可自动续）。
- **TrollStore**（系统版本支持才行）：安装后永久有效。

## 说明

- 包名默认 `com.quseqi.QuSeQi`，显示名"取色器"，改 `project.yml` 里的 `bundleIdPrefix` 和 `INFOPLIST_KEY_CFBundleDisplayName`。
- 更新网页功能后，把新的 `space.html` 覆盖 `App/www/index.html`，push 即重新打包。
- GitHub 免费账号的 macOS 构建分钟数有限，偶尔打个包没问题。
