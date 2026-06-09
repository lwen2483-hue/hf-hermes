FROM nikolaik/python-nodejs:python3.10-nodejs22

USER root

# 1. 安装基础依赖组件（确保 ffmpeg 等多媒体组件正常）
RUN apt-get update && apt-get install -y \
    build-essential \
    ffmpeg \
    git \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. 直接在 root 用户根目录下创建所需的全部目录
RUN mkdir -p /data/.hermes /data/.hermes-web-ui /app/logs /root/.hermes-web-ui/logs \
    && mkdir -p /root/.baoyu-skills/baoyu-imagine/scripts \
    && mkdir -p /opt/hermes-web-ui/dist \
    && ln -sf /data/.hermes /root/.hermes \
    && mkdir -p /root/.cache

WORKDIR /app

# 3. 安装 Bun 运行环境
RUN echo "Installing Bun runtime" \
    && curl -fsSL https://bun.sh/install | bash \
    && export PATH="/root/.bun/bin:$PATH" \
    && cp /root/.bun/bin/bun /usr/local/bin/bun \
    && chmod +x /usr/local/bin/bun

# 4. 安装 yq 工具
RUN curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/bin/yq \
    && chmod +x /usr/bin/yq

# 5. 复制依赖描述文件并安装 Python 依赖
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# 6. 安装 Playwright 浏览器内核
RUN npx playwright install chromium --with-deps --only-shell

# 7. 复制项目核心源码
COPY src/ /app/src/
COPY config/config.yaml /data/.hermes/config.yaml
COPY image-gen-siliconflow.ts /app/
COPY image-proxy.js /app/
COPY entrypoint.sh /app/

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
