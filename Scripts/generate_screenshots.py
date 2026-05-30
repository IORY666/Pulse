"""生成Pulse App Store预览截图 - 模拟真实的App界面"""
from PIL import Image, ImageDraw, ImageFont
import os, math

# === 截图尺寸 ===
SCREENSHOTS = {
    "6.7": (1290, 2796),   # iPhone 14 Pro Max
    "6.5": (1242, 2688),   # iPhone 11 Pro Max / XS Max
}

OUTPUT_DIR = r"C:\Users\86199\Pulse\Resources\Screenshots"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 尝试加载中文字体
FONT_PATHS = [
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simsun.ttc",
    "C:/Windows/Fonts/simhei.ttf",
    "C:/Windows/Fonts/STHeiti Light.ttc",
    "C:/Windows/Fonts/STHeiti Medium.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
]

def load_font(size, bold=False):
    """加载最合适的中文字体"""
    for path in FONT_PATHS:
        try:
            return ImageFont.truetype(path, size)
        except (IOError, OSError):
            continue
    # 回退到默认字体
    try:
        return ImageFont.truetype("arial.ttf", size)
    except:
        return ImageFont.load_default()

def rounded_rect_mask(size, radius):
    """创建圆角矩形遮罩"""
    w, h = size
    mask = Image.new('L', (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=radius, fill=255)
    return mask

def draw_rounded_rect(draw, xy, radius, fill=None, outline=None, width=1):
    """绘制圆角矩形"""
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)

def draw_status_bar(draw, W):
    """iOS状态栏"""
    time_str = "9:41"
    font_sm = load_font(28, bold=True)
    # 时间
    draw.text((50, 18), time_str, fill=(0, 0, 0), font=font_sm)
    # 信号/WiFi/电池图标（简化）
    battery_rect = [(W - 80, 22), (W - 30, 42)]
    draw.rounded_rectangle(battery_rect, radius=6, outline=(0, 0, 0), width=3)
    draw.rectangle([(W - 75, 27), (W - 65, 37)], fill=(0, 0, 0))
    draw.rectangle([(W - 35, 27), (W - 35, 37)], fill=(0, 0, 0))

def draw_nav_bar(draw, W, title, show_plus=True):
    """导航栏"""
    y = 100
    # 大标题
    font_title = load_font(60, bold=True)
    draw.text((48, y), title, fill=(0, 0, 0), font=font_title)
    # 添加按钮
    if show_plus:
        font_plus = load_font(48, bold=True)
        draw.text((W - 90, y + 5), "+", fill=(74, 144, 217), font=font_plus)
    return y + 80

def interp_color(c1, c2, t):
    """颜色插值"""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_progress_ring(draw, cx, cy, r, rate, thickness=12):
    """绘制进度环"""
    # 背景环
    for angle in range(0, 360, 2):
        rad = math.radians(angle)
        x = cx + r * math.cos(rad)
        y = cy + r * math.sin(rad)
        draw.ellipse([(x-3, y-3), (x+3, y+3)], fill=(220, 220, 225))

    # 进度环（渐变效果）
    steps = int(360 * rate)
    for angle in range(0, steps, 2):
        rad = math.radians(angle - 90)
        t = angle / 360.0
        # 蓝色到绿色渐变
        r_c = int(74 + t * (52 - 74))
        g_c = int(144 + t * (199 - 144))
        b_c = int(217 - t * (217 - 89))
        x = cx + (r - 2) * math.cos(rad)
        y = cy + (r - 2) * math.sin(rad)
        draw.ellipse([(x-4, y-4), (x+4, y+4)], fill=(r_c, g_c, b_c))

def generate_screenshot_1_today(W, H):
    """截图1: 今日打卡主界面"""
    img = Image.new('RGB', (W, H), (242, 242, 247))  # iOS系统浅灰背景
    draw = ImageDraw.Draw(img)

    # 状态栏
    draw_status_bar(draw, W)

    # 导航栏
    header_y = draw_nav_bar(draw, W, "今日打卡")

    # === 进度卡片 ===
    card_w = W - 80
    card_h = 300
    card_x = 40
    card_y = header_y + 20

    # 卡片背景（白色圆角）
    draw_rounded_rect(draw, [(card_x, card_y), (card_x + card_w, card_y + card_h)],
                      radius=32, fill=(255, 255, 255))

    # 进度环
    ring_cx = card_x + card_w // 2
    ring_cy = card_y + 120
    ring_r = 80
    draw_progress_ring(draw, ring_cx, ring_cy, ring_r, 0.6)

    # 中心文字
    font_lg = load_font(42, bold=True)
    font_sm = load_font(24)
    text_w_1 = draw.textlength("3/5", font=font_lg)
    draw.text((ring_cx - text_w_1/2, ring_cy - 28), "3/5", fill=(0, 0, 0), font=font_lg)
    text_w_2 = draw.textlength("已完成", font=font_sm)
    draw.text((ring_cx - text_w_2/2, ring_cy + 20), "已完成", fill=(150, 150, 155), font=font_sm)

    # 统计行
    stats_y = card_y + 220
    stats = [("3", "已完成"), ("5", "总任务"), ("12", "最长连续")]
    seg_w = card_w // 3
    for i, (val, label) in enumerate(stats):
        sx = card_x + seg_w * i
        # 分隔线
        if i > 0:
            draw.line([(sx, stats_y + 5), (sx, stats_y + 60)], fill=(220, 220, 225), width=1)
        font_val = load_font(34, bold=True)
        font_lbl = load_font(20)
        tw = draw.textlength(val, font=font_val)
        draw.text((sx + seg_w//2 - tw//2, stats_y), val, fill=(0, 0, 0), font=font_val)
        tw2 = draw.textlength(label, font=font_lbl)
        draw.text((sx + seg_w//2 - tw2//2, stats_y + 40), label, fill=(150, 150, 155), font=font_lbl)

    # === 习惯列表 ===
    list_y = card_y + card_h + 30
    section_font = load_font(30, bold=True)
    draw.text((52, list_y), "待完成", fill=(150, 150, 155), font=section_font)

    # 习惯卡片
    habits_data = [
        ("figure.run", "晨跑 30 分钟", "7天", True, (52, 199, 89)),
        ("book.fill", "阅读 20 页", "5天", True, (74, 144, 217)),
        ("drop.fill", "喝 8 杯水", "12天", False, (90, 200, 250)),
        ("brain.head.profile", "冥想 10 分钟", "3天", False, (175, 82, 222)),
        ("leaf.fill", "不点外卖", "1天", False, (255, 149, 0)),
    ]

    item_y = list_y + 50
    for icon_name, name, streak, completed, color in habits_data:
        # 卡片背景
        draw_rounded_rect(draw, [(48, item_y), (W - 48, item_y + 88)],
                          radius=20, fill=(255, 255, 255))
        # 阴影效果（模拟）
        draw_rounded_rect(draw, [(48, item_y + 88), (W - 48, item_y + 90)],
                          radius=20, fill=(0, 0, 0, 15))

        # 图标背景
        icon_bg_x, icon_bg_y = 68, item_y + 16
        icon_size = 56
        draw_rounded_rect(draw, [(icon_bg_x, icon_bg_y), (icon_bg_x + icon_size, icon_bg_y + icon_size)],
                          radius=16, fill=color)

        # 图标用简单的圆形 + 图形表示（Pillow不直接支持SF Symbols，画简单图形）
        # 画一个小圆形作为图标占位
        draw_rounded_rect(draw, [(icon_bg_x + 14, icon_bg_y + 14), (icon_bg_x + icon_size - 14, icon_bg_y + icon_size - 14)],
                          radius=14, fill=(255, 255, 255, 200))

        # 习惯名称
        font_name = load_font(32)
        draw.text((icon_bg_x + icon_size + 20, icon_bg_y + 5), name, fill=(0, 0, 0), font=font_name)

        # 子信息
        font_sub = load_font(22)
        flame_color = (255, 149, 0) if int(streak.replace("天", "")) > 0 else (180, 180, 185)
        draw.text((icon_bg_x + icon_size + 20, icon_bg_y + 38), f"{streak}连续", fill=flame_color, font=font_sub)

        # 打卡圆
        check_cx = W - 100
        check_cy = item_y + 44
        check_r = 22
        if completed:
            draw.ellipse([(check_cx - check_r, check_cy - check_r),
                          (check_cx + check_r, check_cy + check_r)],
                         fill=(52, 199, 89))
            # 勾
            font_check = load_font(28, bold=True)
            tw = draw.textlength("✓", font=font_check)
            draw.text((check_cx - tw//2, check_cy - 18), "✓", fill=(255, 255, 255), font=font_check)
        else:
            draw.ellipse([(check_cx - check_r, check_cy - check_r),
                          (check_cx + check_r, check_cy + check_r)],
                         outline=(180, 180, 185), width=3)

        item_y += 104

    return img


def generate_screenshot_2_detail(W, H):
    """截图2: 习惯详情与统计"""
    img = Image.new('RGB', (W, H), (242, 242, 247))
    draw = ImageDraw.Draw(img)

    # 状态栏
    draw_status_bar(draw, W)

    # 导航栏
    header_y = draw_nav_bar(draw, W, "晨跑 30 分钟", show_plus=False)

    # === 头部卡片 ===
    card_w = W - 80
    card_x = 40
    card_y = header_y + 10

    # 白色卡片
    draw_rounded_rect(draw, [(card_x, card_y), (card_x + card_w, card_y + 340)],
                      radius=32, fill=(255, 255, 255))

    # 大图标背景
    icon_size = 100
    icon_x = card_x + card_w // 2 - icon_size // 2
    icon_y = card_y + 30
    draw_rounded_rect(draw, [(icon_x, icon_y), (icon_x + icon_size, icon_y + icon_size)],
                      radius=24, fill=(52, 199, 89))

    # 跑步小人图标（简化）
    font_big_icon = load_font(56, bold=True)
    tw = draw.textlength("R", font=font_big_icon)
    draw.text((icon_x + icon_size//2 - tw//2, icon_y + 20), "R", fill=(255, 255, 255), font=font_big_icon)

    # 名称
    font_name = load_font(44, bold=True)
    tw = draw.textlength("晨跑 30 分钟", font=font_name)
    draw.text((card_x + card_w//2 - tw//2, icon_y + icon_size + 20), "晨跑 30 分钟", fill=(0, 0, 0), font=font_name)

    # 频率信息
    font_freq = load_font(26)
    freq_text = "每天 · 目标 1 次"
    tw = draw.textlength(freq_text, font=font_freq)
    draw.text((card_x + card_w//2 - tw//2, icon_y + icon_size + 65), freq_text, fill=(150, 150, 155), font=font_freq)

    # 打卡按钮
    btn_w = 280
    btn_h = 60
    btn_x = card_x + card_w // 2 - btn_w // 2
    btn_y = icon_y + icon_size + 110
    draw_rounded_rect(draw, [(btn_x, btn_y), (btn_x + btn_w, btn_y + btn_h)],
                      radius=28, fill=(52, 199, 89, 30))
    font_btn = load_font(32, bold=True)
    btn_text = "✓ 今日已完成"
    tw = draw.textlength(btn_text, font=font_btn)
    draw.text((btn_x + btn_w//2 - tw//2, btn_y + 14), btn_text, fill=(52, 199, 89), font=font_btn)

    # === 连续打卡卡片 ===
    streak_y = card_y + 370
    streak_h = 120
    draw_rounded_rect(draw, [(card_x, streak_y), (card_x + card_w, streak_y + streak_h)],
                      radius=24, fill=(255, 255, 255))

    streak_data = [("7", "当前连续", (255, 149, 0)),
                   ("15", "最长连续", (255, 204, 0)),
                   ("73%", "30天完成率", (52, 199, 89))]
    seg_w = card_w // 3

    for i, (val, label, color) in enumerate(streak_data):
        sx = card_x + seg_w * i
        if i > 0:
            draw.line([(sx, streak_y + 20), (sx, streak_y + streak_h - 20)],
                     fill=(220, 220, 225), width=1)
        font_val = load_font(38, bold=True)
        font_lbl = load_font(22)
        tw = draw.textlength(val, font=font_val)
        draw.text((sx + seg_w//2 - tw//2, streak_y + 20), val, fill=color, font=font_val)
        tw2 = draw.textlength(label, font=font_lbl)
        draw.text((sx + seg_w//2 - tw2//2, streak_y + 65), label, fill=(150, 150, 155), font=font_lbl)

    # === 图表区域 ===
    chart_y = streak_y + streak_h + 30
    chart_h = 360
    draw_rounded_rect(draw, [(card_x, chart_y), (card_x + card_w, chart_y + chart_h)],
                      radius=24, fill=(255, 255, 255))

    # 图表标题
    font_chart_title = load_font(30, bold=True)
    draw.text((card_x + 30, chart_y + 20), "完成趋势", fill=(0, 0, 0), font=font_chart_title)

    # 时间选择器
    picker_w = 180
    picker_h = 48
    picker_x = card_x + card_w - picker_w - 30
    draw_rounded_rect(draw, [(picker_x, chart_y + 15), (picker_x + picker_w, chart_y + 15 + picker_h)],
                      radius=22, fill=(235, 235, 240))
    font_picker = load_font(24)
    draw.text((picker_x + 15, chart_y + 28), "7天", fill=(150, 150, 155), font=font_picker)

    # 简单柱状图
    bar_area_y = chart_y + 80
    bar_area_h = chart_h - 110
    bar_count = 7
    bar_width = (card_w - 80) // bar_count - 8
    days = ["一", "二", "三", "四", "五", "六", "日"]
    bar_data = [1, 1, 0, 1, 1, 1, 1]  # 完成/未完成

    for i in range(bar_count):
        bx = card_x + 40 + i * (card_w - 80) // bar_count
        bar_h = bar_area_h * 0.85 if bar_data[i] else bar_area_h * 0.15
        bar_color = (74, 144, 217) if bar_data[i] else (220, 220, 225)
        by = bar_area_y + bar_area_h - bar_h

        draw_rounded_rect(draw, [(bx, by), (bx + bar_width, bar_area_y + bar_area_h)],
                          radius=8, fill=bar_color)

        # 标签
        font_day = load_font(22)
        tw = draw.textlength(days[i], font=font_day)
        draw.text((bx + bar_width//2 - tw//2, bar_area_y + bar_area_h + 10),
                 days[i], fill=(150, 150, 155), font=font_day)

    return img


def generate_screenshot_3_widget(W, H):
    """截图3: Widget展示 + 功能介绍"""
    img = Image.new('RGB', (W, H), (242, 242, 247))
    draw = ImageDraw.Draw(img)

    # 状态栏
    draw_status_bar(draw, W)

    # 标题
    title_y = 100
    font_title = load_font(54, bold=True)
    draw.text((48, title_y), "精美小组件", fill=(0, 0, 0), font=font_title)
    font_sub = load_font(28)
    draw.text((48, title_y + 60), "把习惯放在主屏幕上", fill=(150, 150, 155), font=font_sub)

    # === Widget预览区 ===
    # 模拟iPhone主屏幕背景
    screen_y = title_y + 120
    screen_w = W - 100
    screen_h = H - screen_y - 200

    # 模拟壁纸背景
    for y in range(screen_y, screen_y + screen_h):
        ratio = (y - screen_y) / screen_h
        r = int(30 + ratio * 130)
        g = int(30 + ratio * 80)
        b = int(100 - ratio * 60)
        for x in range(50, W - 50):
            img.putpixel((x, y), (r, g, b))

    # 大Widget卡片
    big_widget_w = screen_w - 60
    big_widget_h = 320
    big_widget_x = 80
    big_widget_y = screen_y + 60

    # Widget背景（毛玻璃效果 - 半透明白色）
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    overlay_draw.rounded_rectangle(
        [(big_widget_x, big_widget_y), (big_widget_x + big_widget_w, big_widget_y + big_widget_h)],
        radius=28, fill=(255, 255, 255, 55)
    )

    # Widget 标题
    f_wt = load_font(28, bold=True)
    overlay_draw.text((big_widget_x + 24, big_widget_y + 20), "今日打卡", fill=(255, 255, 255, 220), font=f_wt)
    overlay_draw.text((big_widget_x + big_widget_w - 130, big_widget_y + 20), "3/5 完成", fill=(255, 255, 255, 180), font=load_font(24))

    # Widget中的习惯条目
    widget_items = [
        ("figure.run", "晨跑 30 分钟", True),
        ("book.fill", "阅读 20 页", True),
        ("drop.fill", "喝 8 杯水", False),
        ("brain.head.profile", "冥想 10 分钟", False),
    ]

    wy = big_widget_y + 62
    for icon, name, done in widget_items:
        # 图标圆形
        done_color = (52, 199, 89, 180) if done else (74, 144, 217, 180)
        overlay_draw.rounded_rectangle(
            [(big_widget_x + 24, wy), (big_widget_x + 52, wy + 28)],
            radius=12, fill=done_color
        )
        overlay_draw.text((big_widget_x + 64, wy + 2), name, fill=(255, 255, 255, 200), font=load_font(26, bold=True))

        # 完成标记
        if done:
            check_text = "✓"
            f_ck = load_font(24, bold=True)
            overlay_draw.text((big_widget_x + big_widget_w - 55, wy + 2), check_text, fill=(52, 199, 89, 220), font=f_ck)
        else:
            overlay_draw.ellipse(
                [(big_widget_x + big_widget_w - 55, wy + 4), (big_widget_x + big_widget_w - 29, wy + 30)],
                outline=(255, 255, 255, 130), width=2
            )
        wy += 60

    # 小Widget (2个并排)
    small_widget_w = (big_widget_w - 24) // 2
    small_widget_h = 200
    small_widget_y = big_widget_y + big_widget_h + 28

    for swi in range(2):
        swx = big_widget_x + (small_widget_w + 24) * swi
        overlay_draw.rounded_rectangle(
            [(swx, small_widget_y), (swx + small_widget_w, small_widget_y + small_widget_h)],
            radius=24, fill=(255, 255, 255, 45)
        )

        # 小进度环
        ring_cx = swx + small_widget_w // 2
        ring_cy = small_widget_y + 65
        ring_radius = 40
        rate = 0.6 if swi == 0 else 0.5

        # 背景环
        overlay_draw.ellipse(
            [(ring_cx - ring_radius, ring_cy - ring_radius), (ring_cx + ring_radius, ring_cy + ring_radius)],
            outline=(255, 255, 255, 50), width=8
        )

        # 进度（简化）
        for angle in range(-90, -90 + int(360 * rate), 3):
            rad = math.radians(angle)
            px = ring_cx + (ring_radius - 4) * math.cos(rad)
            py = ring_cy + (ring_radius - 4) * math.sin(rad)
            overlay_draw.ellipse([(px-3, py-3), (px+3, py+3)], fill=(255, 255, 255, 180))

        val_text = "3/5" if swi == 0 else "2/4"
        f_val = load_font(28, bold=True)
        tw_v = overlay_draw.textlength(val_text, font=f_val)
        overlay_draw.text((ring_cx - tw_v//2, ring_cy - 16), val_text, fill=(255, 255, 255, 220), font=f_val)
        f_sub2 = load_font(18)
        tw_s = overlay_draw.textlength("完成", font=f_sub2)
        overlay_draw.text((ring_cx - tw_s//2, ring_cy + 16), "完成", fill=(255, 255, 255, 150), font=f_sub2)

        # 火焰
        streak_text = f"🔥 12天" if swi == 0 else f"🔥 7天"
        f_st = load_font(20)
        tw_st = overlay_draw.textlength(streak_text, font=f_st)
        overlay_draw.text((ring_cx - tw_st//2, small_widget_y + small_widget_h - 40),
                         streak_text, fill=(255, 255, 255, 180), font=f_st)

    # 合并overlay
    img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')

    # === 底部功能介绍文字 ===
    features = [
        "✦  小号Widget：快速查看今日进度",
        "✦  中号Widget：展示所有待打卡习惯",
        "✦  一键点击完成打卡，无需打开App",
    ]
    feat_y = screen_y + screen_h + 20
    for i, feat in enumerate(features):
        f_feat = load_font(24)
        draw.text((60, feat_y + i * 42), feat, fill=(80, 80, 85), font=f_feat)

    return img


# === 生成全部截图 ===
designs = [
    ("01_Today", generate_screenshot_1_today),
    ("02_Detail", generate_screenshot_2_detail),
    ("03_Widget", generate_screenshot_3_widget),
]

for size_name, (W, H) in SCREENSHOTS.items():
    for base_name, generator in designs:
        print(f"Generating {size_name}inch - {base_name}...")
        img = generator(W, H)
        filename = f"Screenshot_{size_name}inch_{base_name}.png"
        filepath = os.path.join(OUTPUT_DIR, filename)
        img.save(filepath, "PNG")
        print(f"  [OK] {filename} ({W}x{H})")
        # 同时生成一个缩略图方便预览
        preview = img.resize((W // 4, H // 4), Image.LANCZOS)
        preview_path = os.path.join(OUTPUT_DIR, f"thumb_{filename}")
        preview.save(preview_path, "PNG")

print("\nAll screenshots generated successfully!")
print(f"Output directory: {OUTPUT_DIR}")
