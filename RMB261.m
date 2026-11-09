% =========================================================================
% 极端天气小样本学习引导的事故动态知识库 (综合分析脚本)
% 包含: 图1 - 特征空间映射与动态轨迹 ; 图2 - 数据分布环形图
% =========================================================================
clear; clc; close all;

%% 1. 全局参数与 IEEE 学术配色定义 (Global Configuration)
% 统一定义配色，确保两张图的视觉一致性
color_typ = [0.1216, 0.4667, 0.7059]; % 经典蓝 - 台风
color_ice = [0.1725, 0.6275, 0.1725]; % 沉稳绿 - 冰冻
color_hea = [0.8392, 0.1529, 0.1569]; % 砖红 - 高温
color_dyn = [0.5804, 0.4039, 0.7412]; % 演化紫 - 动态特征流

colors_matrix = [color_typ; color_ice; color_hea; color_dyn];

% 数据量定义 (被图1和图2共享)
n_shots = 5;      % 每种极端天气的小样本支持集数量
n_steps = 20;     % 事故演化的动态轨迹采样点数

%% ========================================================================
%% Figure 1: 特征空间映射与动态知识决策边界 (Latent Space & Trajectory)
%% ========================================================================
fig1 = figure('Name', 'Feature Space', 'Color', 'w', 'Position', [100, 100, 750, 600]);

% --- 生成空间数据 ---
rng(42); 
proto_centers = [2, 5; 6, 2; 7, 7]; % 预设三种天气的分布中心
support_typ = proto_centers(1,:) + 0.6 * randn(n_shots, 2);
support_ice = proto_centers(2,:) + 0.6 * randn(n_shots, 2);
support_hea = proto_centers(3,:) + 0.6 * randn(n_shots, 2);

proto_typ = mean(support_typ);
proto_ice = mean(support_ice);
proto_hea = mean(support_hea);

% --- 绘制 Voronoi 知识边界 ---
[X, Y] = meshgrid(0:0.1:10, 0:0.1:10);
Z = zeros(size(X));
for i = 1:size(X, 1)
    for j = 1:size(X, 2)
        dists = [norm([X(i,j), Y(i,j)] - proto_typ), ...
                 norm([X(i,j), Y(i,j)] - proto_ice), ...
                 norm([X(i,j), Y(i,j)] - proto_hea)];
        [~, Z(i,j)] = min(dists);
    end
end
contourf(X, Y, Z, [1,2,3], 'LineStyle', 'none');
colormap(fig1, [color_typ; color_ice; color_hea]);
alpha(0.15); hold on;

% --- 绘制支持集散点与原型锚点 ---
s1 = scatter(support_typ(:,1), support_typ(:,2), 60, color_typ, 'o', 'filled', 'MarkerEdgeColor', 'w');
s2 = scatter(support_ice(:,1), support_ice(:,2), 60, color_ice, 's', 'filled', 'MarkerEdgeColor', 'w');
s3 = scatter(support_hea(:,1), support_hea(:,2), 60, color_hea, '^', 'filled', 'MarkerEdgeColor', 'w');
p1 = scatter(proto_typ(1), proto_typ(2), 250, color_typ, 'p', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
p2 = scatter(proto_ice(1), proto_ice(2), 250, color_ice, 'p', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
p3 = scatter(proto_hea(1), proto_hea(2), 250, color_hea, 'p', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

% --- 模拟并绘制动态轨迹 ---
t = linspace(0, 1, n_steps);
traj_x = 1.5 + 4 * t + 0.3 * sin(10*t);
traj_y = 1.5 + 0.8 * t.^2 + 0.2 * cos(10*t);
plot(traj_x, traj_y, '-', 'Color', color_dyn, 'LineWidth', 2.5);
q_point = scatter(traj_x(end), traj_y(end), 120, color_dyn, 'd', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
plot([traj_x(end), proto_typ(1)], [traj_y(end), proto_typ(2)], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);

% --- Figure 1 渲染与排版 ---
box on; grid on; set(gca, 'GridAlpha', 0.2, 'GridLineStyle', ':', 'LineWidth', 1.2, 'FontName', 'Times New Roman', 'FontSize', 12);
xlim([0, 9]); ylim([0, 9]);
xlabel('Latent Feature $\mathcal{Z}_1(\mathbf{x})$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Latent Feature $\mathcal{Z}_2(\mathbf{x})$', 'Interpreter', 'latex', 'FontSize', 14);
title('\textbf{Dynamic Knowledge Base Space via Few-Shot Embedding}', 'Interpreter', 'latex', 'FontSize', 15);
lgd1 = legend([s1, s2, s3, p1, q_point], ...
    {'Typhoon Support Set $\mathcal{S}_{typ}$', 'Ice Storm Support Set $\mathcal{S}_{ice}$', ...
    'Heatwave Support Set $\mathcal{S}_{hea}$', 'Knowledge Prototypes $\mathbf{c}_k$', ...
    'Dynamic Accident Trajectory $\mathbf{q}_t$'}, 'Interpreter', 'latex', 'Location', 'northwest', 'FontSize', 11);
set(lgd1, 'EdgeColor', 'none', 'Color', 'none');


%% ========================================================================
%% Figure 2: 数据分布特征环形统计图 (Data Composition Donut Chart)
%% ========================================================================
% 将窗口设置宽一点(950)以防图例遮挡或裁剪
fig2 = figure('Name', 'Data Composition', 'Color', 'w', 'Position', [900, 100, 950, 550]); 
colormap(fig2, colors_matrix);

data_counts = [n_shots, n_shots, n_shots, n_steps];
explode = [0, 0, 0, 0.12]; 
total_points = sum(data_counts);
pct = round((data_counts / total_points) * 100, 1);

labels = {sprintf('Typhoon $\\mathcal{S}_{typ}$ (%.1f\\%%)', pct(1)), ...
          sprintf('Ice Storm $\\mathcal{S}_{ice}$ (%.1f\\%%)', pct(2)), ...
          sprintf('Heatwave $\\mathcal{S}_{hea}$ (%.1f\\%%)', pct(3)), ...
          sprintf('Dynamic Process $\\mathbf{q}_{1:T}$ (%.1f\\%%)', pct(4))};

% --- 绘制饼图 ---
p = pie(data_counts, explode);
for i = 1:2:length(p)
    set(p(i), 'EdgeColor', 'w', 'LineWidth', 2);
end
for i = 2:2:length(p)
    set(p(i), 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 13);
    p(i).String = labels{i/2};
    % 标签向心聚拢 15% 防止超边
    set(p(i), 'Position', get(p(i), 'Position') * 0.85); 
end

% --- 中心镂空白遮罩 ---
hold on; theta = linspace(0, 2*pi, 150);
patch(0.5 * cos(theta), 0.5 * sin(theta), 'w', 'EdgeColor', 'w');

% --- Figure 2 渲染与排版 ---
text(0, 0.08, '\textbf{Total Points}', 'Interpreter', 'latex', 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', 'FontSize', 12);
text(0, -0.15, sprintf('\\textbf{N = %d}', total_points), 'Interpreter', 'latex', 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', 'FontSize', 17);

% 保护边界并设置坐标轴范围，彻底杜绝标签显示不全的问题
axis([-1.6, 1.5, -1.2, 1.2]); 
set(gca, 'Position', [0.12, 0.1, 0.65, 0.75]); 

title('\textbf{Data Composition: Few-Shot Anchors vs. Dynamic Trajectory}', 'Interpreter', 'latex', 'FontSize', 16, 'FontName', 'Times New Roman');
lgd2 = legend(sprintf('Typhoon Prototypes ($N_{typ}=%d$)', n_shots), ...
              sprintf('Ice Storm Prototypes ($N_{ice}=%d$)', n_shots), ...
              sprintf('Heatwave Prototypes ($N_{hea}=%d$)', n_shots), ...
              sprintf('Accident Trajectory Steps ($T=%d$)', n_steps), ...
              'Location', 'eastoutside');
set(lgd2, 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 12, 'EdgeColor', 'none', 'Color', 'none');