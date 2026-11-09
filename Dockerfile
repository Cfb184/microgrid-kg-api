# 1. 强制使用 MathWorks 官方提供的 R2022b 镜像作为底座
FROM mathworks/matlab:r2022b

# 2. 切换到 root 权限以安装系统级 Python 依赖
USER root

# 3. 安装 Python 3 和 pip (官方镜像基于 Ubuntu)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. 设置工作目录并将你的代码拷贝进容器
WORKDIR /app
COPY RMB30026.py /app/
COPY RMB261.m /app/

# 5. 安装 Python 后端库
RUN pip3 install --no-cache-dir --ignore-installed flask flask-cors numpy

# 6. 安装与 R2022b 严格绑定的 MATLAB Python Engine (版本号 9.13)
# 不要直接 pip install matlabengine，必须指定匹配版本，否则必报错
RUN pip3 install --no-cache-dir matlabengine==9.13.15

# 7. 暴露 API 端口
EXPOSE 5026

# 8. 切换回普通用户(必须切换，否则 MATLAB 引擎容易报安全权限错)
USER matlab

# 9. 启动命令
CMD ["python3", "RMB30026.py"]
