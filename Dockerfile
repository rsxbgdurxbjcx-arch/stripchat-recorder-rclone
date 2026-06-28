FROM chantrail/stripchat-recorder:latest

LABEL maintainer="rclone-upload-module" \
      version="0.1.0" \
      description="StripchatRecorder with rclone upload module"

# 安装 rclone + python3
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        curl \
        ca-certificates && \
    curl -s https://rclone.org/install.sh | bash && \
    apt-get purge -y --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 将 rclone_upload 模块放入 modules.default
# 入口脚本启动时会自动复制到 modules/ 目录（不覆盖已有文件）
COPY module/rclone_upload /app/stripchat-recorder/modules.default/rclone_upload
RUN chmod +x /app/stripchat-recorder/modules.default/rclone_upload
