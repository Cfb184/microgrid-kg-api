from flask import Flask, jsonify
from flask_cors import CORS
import matlab.engine
import numpy as np
import logging

# ==========================================
# 极端天气与网络攻击微电网知识库后端 (Flask API)
# ==========================================

app = Flask(__name__)
CORS(app)  # 开启跨域资源共享，允许前端应用(如 Vue/React)直接请求

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# 1. 全局挂载 MATLAB 引擎 (避免每次请求重复启动导致的阻塞)
logging.info("正在挂载 MATLAB R2022b 引擎，请稍候...")
eng = matlab.engine.start_matlab()
logging.info("MATLAB 引擎挂载成功，API 服务准备就绪。")


@app.route('/run_matlab', methods=['GET', 'POST'])
def get_knowledge_graph_data():
    """
    前端抓取数据的核心接口
    Endpoint: http://127.0.0.1:5026/run_matlab
    """
    try:
        # 调度同级目录下的 MATLAB 无头脚本 (不包含 figure 渲染代码)
        eng.eval("RMB261", nargout=0)

        # 提取空间坐标与轨迹数据 (跨语言内存转换)
        support_typ = np.array(eng.workspace['support_typ']).tolist()
        support_ice = np.array(eng.workspace['support_ice']).tolist()
        support_hea = np.array(eng.workspace['support_hea']).tolist()

        proto_typ = np.array(eng.workspace['proto_typ'])[0].tolist()
        proto_ice = np.array(eng.workspace['proto_ice'])[0].tolist()
        proto_hea = np.array(eng.workspace['proto_hea'])[0].tolist()

        traj_x = np.array(eng.workspace['traj_x'])[0].tolist()
        traj_y = np.array(eng.workspace['traj_y'])[0].tolist()
        dynamic_trajectory = [[x, y] for x, y in zip(traj_x, traj_y)]

        # 提取统计特征数据
        n_shots = int(eng.workspace['n_shots'])
        n_steps = int(eng.workspace['n_steps'])

        # 构建标准化响应 Payload
        frontend_payload = {
            "status": "success",
            "message": "Dynamic knowledge base updated successfully",
            "data": {
                "spatial_features": {
                    "support_sets": {
                        "typhoon": support_typ,
                        "ice_storm": support_ice,
                        "heatwave": support_hea
                    },
                    "prototypes": {
                        "typhoon": proto_typ,
                        "ice_storm": proto_ice,
                        "heatwave": proto_hea
                    },
                    "dynamic_trajectory": dynamic_trajectory
                },
                "statistical_composition": [
                    {"name": "Typhoon Prototypes", "value": n_shots},
                    {"name": "Ice Storm Prototypes", "value": n_shots},
                    {"name": "Heatwave Prototypes", "value": n_shots},
                    {"name": "Accident Trajectory", "value": n_steps}
                ]
            }
        }

        return jsonify(frontend_payload), 200

    except Exception as e:
        logging.error(f"MATLAB 推演执行失败: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500


if __name__ == '__main__':
    # 将 host 改为 '0.0.0.0'，端口保持 5026
    app.run(host='0.0.0.0', port=5026, debug=False)