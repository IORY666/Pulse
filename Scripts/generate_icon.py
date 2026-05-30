"""生成Pulse App图标 - 1024x1024 PNG"""
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
CENTER = SIZE // 2

# 创建画布
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# === 1. 绘制圆角方形背景（iOS风格）===
corner_radius = 200
margin = 20

# 绘制圆角矩形背景（深蓝→紫色渐变）
for y in range(margin, SIZE - margin):
    # 渐变：顶部深蓝 #1a1a5e → 底部深紫 #4a154b
    ratio = (y - margin) / (SIZE - 2 * margin)
    r = int(26 + ratio * (74 - 26))   # 26 → 74
    g = int(26 + ratio * (21 - 26))   # 26 → 21
    b = int(94 - ratio * (94 - 75))   # 94 → 75

    # 计算圆角（通过alpha通道模拟）
    for x in range(margin, SIZE - margin):
        # 判断是否在圆角内
        dx_left = x - margin
        dx_right = SIZE - margin - x
        dy_top = y - margin
        dy_bottom = SIZE - margin - y

        in_corner = False
        if dx_left < corner_radius and dy_top < corner_radius:
            dist = math.sqrt((corner_radius - dx_left)**2 + (corner_radius - dy_top)**2)
            in_corner = dist > corner_radius
        elif dx_right < corner_radius and dy_top < corner_radius:
            dist = math.sqrt((corner_radius - dx_right)**2 + (corner_radius - dy_top)**2)
            in_corner = dist > corner_radius
        elif dx_left < corner_radius and dy_bottom < corner_radius:
            dist = math.sqrt((corner_radius - dx_left)**2 + (corner_radius - dy_bottom)**2)
            in_corner = dist > corner_radius
        elif dx_right < corner_radius and dy_bottom < corner_radius:
            dist = math.sqrt((corner_radius - dx_right)**2 + (corner_radius - dy_bottom)**2)
            in_corner = dist > corner_radius

        if not in_corner:
            img.putpixel((x, y), (r, g, b, 255))

# 边缘柔化：对圆角区域做抗锯齿
# （简化处理：直接使用高斯模糊的遮罩方法）
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle(
    [(margin, margin), (SIZE - margin, SIZE - margin)],
    radius=corner_radius,
    fill=255
)

# 创建纯色背景并应用遮罩
bg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
for y in range(margin, SIZE - margin):
    ratio = (y - margin) / (SIZE - 2 * margin)
    r = int(26 + ratio * (74 - 26))
    g = int(26 + ratio * (21 - 26))
    b = int(94 - ratio * (94 - 75))
    for x in range(margin, SIZE - margin):
        if mask.getpixel((x, y)) > 128:
            bg.putpixel((x, y), (r, g, b, 255))

# 应用遮罩
bg.putalpha(mask)
img = bg

# === 2. 绘制脉冲心跳线条（白色，中间位置）===
# 设计一个优雅的心跳/脉冲波形
draw = ImageDraw.Draw(img)

# 波形参数
wave_center_y = CENTER + 30
wave_amplitude = 130
line_width = 14

# 定义心跳波形：平线 → 小峰 → 大峰 → 小峰 → 平线
# 用贝塞尔风格的点序列模拟心电图
wave_points = []

# 左边平线
left_x = CENTER - 280
right_x = CENTER + 280
flat_y = wave_center_y + 40

# 生成心电图样的波形
def ecg_wave(t):
    """ECG风格波形函数，t范围[-1, 1]"""
    t = max(-1, min(1, t))
    # 正常心跳：P波 → QRS波群 → T波
    # 简化为一组特征峰
    if t < -0.7:
        return 0  # 基线
    elif t < -0.55:
        # P波(小圆峰)
        phase = (t + 0.7) / 0.15
        return 0.25 * math.sin(phase * math.pi)
    elif t < -0.35:
        return 0  # PR间期
    elif t < -0.2:
        # Q波(小向下)
        phase = (t + 0.35) / 0.15
        return -0.15 * math.sin(phase * math.pi)
    elif t < -0.05:
        # R波(大向上峰)
        phase = (t + 0.2) / 0.15
        return 1.0 * math.sin(phase * math.pi)
    elif t < 0.05:
        # S波(向下)
        phase = (t + 0.05) / 0.1
        return -0.3 * math.sin(phase * math.pi)
    elif t < 0.35:
        return 0  # ST段
    elif t < 0.55:
        # T波(中等圆峰)
        phase = (t - 0.35) / 0.2
        return 0.35 * math.sin(phase * math.pi)
    else:
        return 0  # 基线

# 生成波形路径点
path_points = []
num_points = 600
for i in range(num_points):
    t = (i / (num_points - 1)) * 2 - 1  # [-1, 1]
    x = left_x + (i / (num_points - 1)) * (right_x - left_x)
    y = flat_y - ecg_wave(t) * wave_amplitude
    path_points.append((x, y))

# 绘制粗线条波形（发光效果：先绘外发光再绘主线）
# 外发光
for width_mult in [4, 2.5, 1.5]:
    glow_width = int(line_width * width_mult)
    alpha = int(30 / width_mult)
    for i in range(len(path_points) - 1):
        draw.line(
            [path_points[i], path_points[i + 1]],
            fill=(255, 255, 255, alpha),
            width=glow_width,
        )

# 主线
for i in range(len(path_points) - 1):
    # 渐变色：青色→白色→粉色
    progress = i / (len(path_points) - 1)
    if progress < 0.3:
        r, g, b = 100, 210, 255  # 青蓝色
    elif progress < 0.7:
        r, g, b = 255, 255, 255  # 纯白
    else:
        r, g, b = 255, 150, 200  # 粉色
    draw.line(
        [path_points[i], path_points[i + 1]],
        fill=(r, g, b, 230),
        width=line_width,
    )

# === 3. 添加微妙的网格装饰（增加科技感）===
grid_color = (255, 255, 255, 8)
grid_spacing = 80
for x in range(margin + corner_radius, SIZE - margin - corner_radius, grid_spacing):
    draw.line([(x, margin + corner_radius), (x, SIZE - margin - corner_radius)], fill=grid_color, width=1)
for y in range(margin + corner_radius, SIZE - margin - corner_radius, grid_spacing):
    draw.line([(margin + corner_radius, y), (SIZE - margin - corner_radius, y)], fill=grid_color, width=1)

# === 4. 添加中心光晕 ===
glow_radius = 200
glow_center = (CENTER, wave_center_y - 20)
for r in range(glow_radius, 0, -5):
    alpha = int(15 * (1 - r / glow_radius))
    draw.ellipse(
        [
            (glow_center[0] - r, glow_center[1] - r),
            (glow_center[0] + r, glow_center[1] + r),
        ],
        fill=(200, 220, 255, alpha),
    )

# === 保存 ===
output_path = r"C:\Users\86199\Pulse\Resources\AppIcon.png"
img.save(output_path, "PNG")
print(f"[OK] App icon generated: {output_path}")
print(f"Size: {SIZE}x{SIZE}px")
print(f"Format: PNG (RGBA)")

# 生成一个预览缩略图便于查看
preview = img.resize((256, 256), Image.LANCZOS)
preview_path = r"C:\Users\86199\Pulse\Resources\AppIcon_preview.png"
preview.save(preview_path, "PNG")
print(f"[OK] Preview generated: {preview_path}")
