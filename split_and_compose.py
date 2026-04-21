#!/usr/bin/env python3
"""四宫格拆分与重组 v5 — 修正背景与排版"""
import os
from PIL import Image, ImageDraw, ImageFont

INPUT  = "/Users/yyx/Downloads/20260420-134152.jpg"
OUT    = "/Users/yyx/ztqc/cc_kaiyuan/claude-code-main/output"
W, H   = 1080, 1920
TOL    = 30
os.makedirs(OUT, exist_ok=True)

# ─── 1. 拆分 ───
grid = Image.open(INPUT).convert("RGB")
gw, gh = grid.size
hw, hh = gw//2, gh//2
print(f"原图 {gw}x{gh} → 每格 {hw}x{hh}")

bg_p   = grid.crop((0, 0, hw, hh))      # 场景
car_p  = grid.crop((hw, 0, gw, hh))     # 汽车
txt_p  = grid.crop((0, hh, hw, gh))     # 标题+列表
bot_p  = grid.crop((hw, hh, gw, gh))    # 底部文字
for n,im in [("bg",bg_p),("car",car_p),("txt",txt_p),("bot",bot_p)]:
    im.save(f"{OUT}/raw_{n}.png")

# ─── 2. 抠图 ───
def cutout(img):
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    m = min(20, w//10, h//10)
    c = [px[m,m], px[w-m-1,m], px[m,h-m-1], px[w-m-1,h-m-1]]
    avg = tuple(sum(c[j] for c in c) // 4 for j in range(3))
    out = Image.new("RGBA",(w,h))
    op = out.load()
    T, S = TOL*3, TOL*2
    for y in range(h):
        for x in range(w):
            r,g,b,_ = px[x,y]
            d = abs(r-avg[0]) + abs(g-avg[1])*1.2 + abs(b-avg[2])
            if d < T-S:
                op[x,y] = (0,0,0,0)
            elif d >= T:
                op[x,y] = (r,g,b,255)
            else:
                a = int(255*(d-(T-S))/S)
                op[x,y] = (r,g,b,min(255,max(0,a)))
    return out

car_t = cutout(car_p); car_t.save(f"{OUT}/elem_car.png")
tw2,th2 = txt_p.size; sy=int(th2*0.38)
title_t = cutout(txt_p.crop((0,0,tw2,sy)));  title_t.save(f"{OUT}/elem_title.png")
list_t  = cutout(txt_p.crop((0,sy,tw2,th2))); list_t.save(f"{OUT}/elem_list.png")
bot_t   = cutout(bot_p); bot_t.save(f"{OUT}/elem_bottom.png")
print("抠图完成")

# ─── 3. 构建背景 ───
# 关键修正：原场景只有上半部分，下半留白
# 不拉伸！原比例缩放场景到目标宽度，下方留白/补色
pw, ph = bg_p.size  # 1024x1024
# 缩放使宽度匹配
sc = W / pw  # 1080/1024 ≈ 1.055
sw, sh = int(pw*sc), int(ph*sc)  # 1080 x 1080
scene = bg_p.resize((sw, sh), Image.LANCZOS)
print(f"场景缩放 {sc:.3f} → {sw}x{sh}")

# 创建画布：上半场景 + 下半米色地面（延续场景底部）
canvas = Image.new("RGBA", (W, H), (245, 240, 230, 255))  # 米白底色
canvas.paste(scene, (0, 0))  # 场景在顶部 1080x1080

# 下方区域用场景底部颜色填充（地面延续）
# 取场景底部一行像素作为参考
scene_px = scene.load()
# 左侧绿地面色 & 右侧米地面色
green_floor = scene_px[100, sh-5]
marble_floor = scene_px[sw-100, sh-5]
print(f"地面色: 绿{green_floor} 米{marble_floor}")

for y in range(sh, H):
    ratio = (y - sh) / (H - sh)  # 0→1 从上到下
    for x in range(W):
        if x < W * 0.42:
            # 左侧绿地面 → 逐渐变暗
            r = int(green_floor[0] * (1 - ratio*0.3))
            g = int(green_floor[1] * (1 - ratio*0.2))
            b = int(green_floor[2] * (1 - ratio*0.2))
        else:
            # 右侧米地面 → 逐渐变暗
            r = int(marble_floor[0] * (1 - ratio*0.15))
            g = int(marble_floor[1] * (1 - ratio*0.1))
            b = int(marble_floor[2] * (1 - ratio*0.08))
        canvas.putpixel((x, y), (r, g, b, 255))

canvas_rgb = canvas.convert("RGB")
canvas_rgb.save(f"{OUT}/background_full.png")
print(f"背景构建: 场景{sw}x{sh} + 地面{W}x{H-sh}")

final = canvas.copy()

# ─── 4. 放置汽车 ───
cs = 0.68
cw = int(car_t.size[0]*cs); ch = int(car_t.size[1]*cs)
car_s = car_t.resize((cw,ch), Image.LANCZOS)
cx, cy = 40, 600
final.paste(car_s, (cx,cy), car_s)
print(f"汽车: ({cx},{cy}) {cw}x{ch}")

# 倒影
ca = final.crop((cx,cy,cx+cw,cy+ch))
ref = ca.transpose(Image.FLIP_TOP_BOTTOM)
rw,rh = ref.size
al = ref.split()[3]
ad = list(al.getdata())
na = []
for y in range(rh):
    f = int(130*(1-y/rh)*0.4)
    for x in range(rw):
        v = ad[y*rw+x]
        na.append(min(v,f) if v>0 else 0)
al.putdata(na); ref.putalpha(al)
ry = cy + ch - 2
ref = ref.crop((0,0,rw, min(rh, H-ry)))
final.paste(ref, (cx, ry), ref)

# ─── 5. 放置文字 ───
# 策略：每个文字块加白色圆角底框，确保在任何背景下可读
def place_with_bg(elem, x, y, sc, pad=20, radius=16, fill_alpha=175):
    """放置元素，先加白色半透底框"""
    ew, eh = elem.size
    sw2, sh2 = int(ew * sc), int(eh * sc)
    es = elem.resize((sw2, sh2), Image.LANCZOS)
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    d.rounded_rectangle(
        (x - pad, y - pad//2, x + sw2 + pad, y + sh2 + pad//2),
        radius=radius, fill=(255, 255, 255, fill_alpha)
    )
    final.paste(es, (x, y), es)
    return es, x, y, ov, sw2, sh2

# 标题 "零跑Lafa5" — 场景上半部，偏右侧
es_t, tx, ty, ov_t, tw3, th3 = place_with_bg(title_t, 260, 80, 0.46, pad=28, radius=18, fill_alpha=175)
final = Image.alpha_composite(final, ov_t)
print(f"标题: ({tx},{ty}) {tw3}x{th3}")

# 列表 — 标题下方靠左
es_l, lx, ly, ov_l, lw3, lh3 = place_with_bg(list_t, 90, 200, 0.38, pad=22, radius=16, fill_alpha=175)
final = Image.alpha_composite(final, ov_l)
print(f"列表: ({lx},{ly}) {lw3}x{lh3}")

# 底部文字 — 汽车下方，不盖倒影
es_b, bx, by, ov_b, bw3, bh3 = place_with_bg(bot_t, 130, 1450, 0.38, pad=25, radius=16, fill_alpha=175)
final = Image.alpha_composite(final, ov_b)
print(f"底部: ({bx},{by}) {bw3}x{bh3}")

# ─── 6. 水印 ───
wm = Image.new("RGBA",(W,H),(0,0,0,0))
wd = ImageDraw.Draw(wm)
fp = None
for p in ["/System/Library/Fonts/AppleSDGothicNeo.ttc","/System/Library/Fonts/ArialHB.ttc"]:
    if os.path.exists(p): fp=p; break
try:
    wf = ImageFont.truetype(fp, 14) if fp else ImageFont.load_default()
except: wf = ImageFont.load_default()
wx,wy = W-55, H-28
bb = wd.textbbox((0,0),"AI生成",font=wf)
ww2=bb[2]-bb[0]+8; wh2=bb[3]-bb[1]+3
wd.rounded_rectangle((wx,wy,wx+ww2,wy+wh2),radius=3,
    fill=(255,255,255,100),outline=(200,200,200,100),width=1)
wd.text((wx+4,wy),"AI生成",fill=(170,170,170,160),font=wf)
final = Image.alpha_composite(final, wm)

out = final.convert("RGB")
out.save(f"{OUT}/composed.png","PNG",optimize=True)
p = out.resize((540,960), Image.LANCZOS)
p.save(f"{OUT}/composed_preview.png")
print(f"\n完成: {OUT}/composed.png  {W}x{H}")
