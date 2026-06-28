FROM chantrail/stripchat-recorder:latest

LABEL maintainer="rsxbgdurxbjcx-arch" \
      version="0.1.0" \
      description="StripchatRecorder with rclone upload module"

# 安装 python3（rclone 依赖）+ 下载 rclone
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        curl \
        ca-certificates \
        unzip && \
    curl -s https://rclone.org/install.sh | bash && \
    apt-get remove -y --auto-remove curl unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 将 rclone_upload 模块放入 modules.default
# 容器启动时入口脚本会自动复制到 modules/ 目录
COPY module/rclone_upload /app/stripchat-recorder/modules.default/rclone_upload
RUN chmod +x /app/stripchat-recorder/modules.default/rclone_upload
