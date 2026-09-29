# GitHub 打包 IPA 操作教程

## 准备的东西
- 一个 GitHub 账号（没有的话先注册）
- 我给你的 `quseqi-ios.zip`（解压成文件夹）
- 手机浏览器或电脑都能操作

---

## 一、注册 GitHub（已有账号跳过）

1. 打开 github.com
2. 点右上角 **Sign up**，按提示填邮箱、密码、用户名
3. 去邮箱点验证链接完成注册

## 二、新建仓库

1. 登录后，点右上角 **+** → **New repository**
2. Repository name 填 `quseqi-ios`
3. 下面选 **Public**（公开仓库的 Actions 更耐用）
4. **不要**勾选 Add a README，保持空仓库
5. 点 **Create repository**

## 三、上传文件

1. 进入刚建好的仓库页面，点 **uploading an existing file**
   （或者点 Add file → Upload files）
2. 把解压后的 `quseqi-ios` 文件夹里**所有文件**拖进上传框
3. ⚠️ 注意：`.github` 是隐藏文件夹，解压后确认它存在，一起拖进去
   目录结构应该是这样：
   ```
   App/Sources/QuSeQiApp.swift
   App/www/index.html
   project.yml
   README.md
   .github/workflows/ipa.yml
   ```
4. 页面拉到底，点 **Commit changes**

> 如果网页上传看不到 `.github` 文件夹，改用 git 命令行：
> ```
> git clone <你的仓库地址>
> cd quseqi-ios
> # 把解压的文件全部拷进这个目录
> git add .
> git commit -m "init"
> git push
> ```

## 四、运行打包

1. 进仓库，点顶部 **Actions** 标签
2. 如果页面提示启用 workflow，点 **I understand my workflows, go ahead and enable them**
3. 左侧列表点 **Build IPA**
4. 右侧点 **Run workflow** → 再点 **Run workflow**
5. 等待 5~10 分钟，看到**绿色对勾**就是成功了
6. 如果是红色叉号：点进去看报错日志，发给我修

## 五、下载 IPA

1. 点进那次绿色对勾的运行记录
2. 页面拉到最底部 **Artifacts**，点 **QuSeQi-unsigned-ipa** 下载
3. 解压得到 `QuSeQi-unsigned.ipa`

## 六、安装到 iPhone

这个 IPA 是**未签名**的，不能直接安装，需要自签（二选一）：

**方法 A：Sideloadly（推荐，有 Win/Mac 版）**
1. 电脑安装 Sideloadly，iPhone 连电脑并信任
2. 把 IPA 拖进 Sideloadly，输入你的 Apple ID（免费的就行）
3. 点 Start，等安装完成

**方法 B：AltStore**
- 原理同上，免费 Apple ID 签 7 天，到期前 AltStore 可自动续签

**方法 C：TrollStore**
- 系统版本支持的话装完永久有效，不用续签

## 七、以后更新

取色器网页功能更新后，把新的 `space.html` 改名覆盖 `App/www/index.html`，
重新上传到仓库（或 git push），Actions 会自动重新打包。

---

## 常见问题

| 问题 | 解决 |
|---|---|
| Actions 红色报错 | 点进失败的步骤看日志，发给我修 |
| 上传时找不到 `.github` | 用上面的 git 命令行方式 |
| 提示分钟数不够 | GitHub 免费账号 macOS 构建时间有限，偶尔打包够用，别频繁触发 |
| 装到手机提示"无法验证" | 自签过期了，重新签一次 |
