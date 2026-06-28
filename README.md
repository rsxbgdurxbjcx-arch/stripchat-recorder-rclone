# StripchatRecorder Rclone 上传模块

基于 [StripchatRecorder](https://github.com/ChanTrail/StripchatRecorder) 官方镜像构建，内置 rclone 和 `rclone_upload` 后处理模块。

录制完成后自动将视频上传至 PikPak、Google Drive 等云盘，按主播名自动分类存储。

---

## 工作原理

```
StripchatRecorder 官方镜像
         ↓  +rclone +python3 +pp模块
本镜像 (ghcr.io/rsxbgdurxbjcx-arch/stripchat-recorder-rclone)
         ↓  docker compose up
    容器启动，入口脚本自动将 rclone_upload 复制到 modules/
         ↓
    Web UI → 后处理流水线 → "选择模块" 列表出现 "Rclone 上传 0.1.0"
         ↓
    录制完成 → SR 调用 rclone_upload → 上传到云盘
```

## 功能

- 通过 Rclone 上传视频至任意支持的云盘（PikPak、Google Drive、OneDrive 等）
- 自动从文件名提取主播名，在云盘按主播名创建子文件夹
- 上传失败自动重试
- 可选上传成功后删除本地文件
- 实时进度上报

---

## 前置条件

1. **Docker** + **Docker Compose**
2. **Rclone** 已在宿主机配置好远程存储（如 PikPak）

### 配置 Rclone

```bash
curl https://rclone.org/install.sh | bash
```

```bash
rclone config
```

> 按提示操作：
> - 输入 `n` 新建远程
> - 名字填 `pikpak`（或其他云盘）
> - 输入 `pikpak`
> - 输入 PikPak账号
> - 输入 `y` 确认
> - 输入PikPak密码
> - 再次输入密码
> - 输入 `n` 跳过高级配置
> - 输入 `y` 确认
> - 输入 `q` 退出

```bash
rclone lsd pikpak:
```

> 能列出云盘目录即配置成功。

---

## 安装部署

### 1. 下载 docker-compose.yml 并准备目录

```bash
mkdir -p /opt/stripchat-recorder-rclone && cd /opt/stripchat-recorder-rclone && curl -o docker-compose.yml https://raw.githubusercontent.com/rsxbgdurxbjcx-arch/stripchat-recorder-rclone/main/docker-compose.yml && mkdir -p data/{logs,recordings,modules,config,rclone} && cp /root/.config/rclone/rclone.conf data/rclone/
```

> 如果之前部署过 StripchatRecorder 官方镜像，先清理旧容器避免端口冲突：
>
> ```bash
> docker stop stripchat-recorder 2>/dev/null; docker rm stripchat-recorder 2>/dev/null
> ```

### 2. 拉取镜像并启动

```bash
cd /opt/stripchat-recorder-rclone && docker compose pull && docker compose up -d
```

### 3. 验证

```bash
docker logs -f sr-rclone
```

> 看到以下日志说明启动成功：
> ```
> Server mode: listening on http://0.0.0.0:3030
> ```
>
> 浏览器访问 `http://服务器IP:3030/` 打开 Web UI。

---

## 使用模块

1. 打开 SR Web UI → **后处理** 流水线
2. 点击 **+ 添加模块**
3. 模块列表中选择 **Rclone 上传 0.1.0**
4. 配置参数：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| Rclone 远程名称 | `pikpak` | `rclone config` 中配置的远程名 |
| 云盘目标目录 | `StripchatRecorder` | 云盘上的根目录 |
| Rclone 路径 | `rclone` | rclone 二进制路径（一般不用改） |
| 最大重试次数 | `3` | 上传失败重试次数 |
| 上传成功后删除本地文件 | `false` | 是否删除本地录制文件 |
| 并行传输数 | `2` | rclone 并行连接数 |

5. 保存

之后每次录制结束，视频会自动上传到 `pikpak:StripchatRecorder/主播名/` 目录。

---

## 文件名解析

录制文件名格式为 `{model_name}_{YYYYMMDD}_{HHmmss}.mp4`：

```
testmodel_20260625_071400.mp4
         ↓
提取主播名: testmodel
         ↓
云盘路径: pikpak:StripchatRecorder/testmodel/testmodel_20260625_071400.mp4
```

---

## 更新镜像

当仓库有更新时，拉取最新镜像并重启：

```bash
cd /opt/stripchat-recorder-rclone && docker compose pull && docker compose up -d
```

---

## 常用命令

> 以下命令都需要先 `cd /opt/stripchat-recorder-rclone` 进入部署目录。

```bash
docker logs -f sr-rclone
```

```bash
docker compose restart
```

```bash
docker compose down
```

---

## docker-compose.yml 参考

```yaml
services:
  stripchat-recorder:
    image: ghcr.io/rsxbgdurxbjcx-arch/stripchat-recorder-rclone:latest
    container_name: sr-rclone
    restart: unless-stopped
    environment:
      - TZ=Asia/Shanghai
    ports:
      - "3030:3030"
    volumes:
      - ./data/logs:/app/stripchat-recorder/logs
      - ./data/recordings:/app/stripchat-recorder/recordings
      - ./data/modules:/app/stripchat-recorder/modules
      - ./data/config:/app/stripchat-recorder/config
      - ./data/rclone:/root/.config/rclone
```

如需修改端口，添加 `PORT` 环境变量或创建 `.env` 文件。

---

## 支持的 rclone 远程类型

本模块兼容所有 rclone 支持的云盘，包括但不限于：

- PikPak
- Google Drive
- OneDrive
- Dropbox
- S3 / 对象存储
- WebDAV
- SFTP

只需在 `rclone config` 中配置对应的远程，然后在模块参数中填入远程名称即可。

---

## 技术细节

- **基础镜像**: `chantrail/stripchat-recorder:latest`
- **额外依赖**: rclone（最新版）、python3
- **模块协议**: 遵循 [StripchatRecorder 后处理模块协议](https://github.com/ChanTrail/StripchatRecorder/blob/main/docs/module-development.md)
- **模块 ID**: `rclone_upload`
- **进度上报**: 通过解析 rclone `--progress` 输出，实时上报至 SR UI

## License

MIT
