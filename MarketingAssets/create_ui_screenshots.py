from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(r"C:\Users\Windows\NailTry")
PHOTO_NATURAL = Path(
    r"C:\Users\Windows\.codex\generated_images\019e75e8-64d3-7410-be01-4e0f7dad622e\ig_06cc24a6e24203b6016a1a2acf60fc81918b302538f4f2af6d.png"
)
PHOTO_COSMIC = Path(
    r"C:\Users\Windows\.codex\generated_images\019e75e8-64d3-7410-be01-4e0f7dad622e\ig_06cc24a6e24203b6016a1a29ea0bb481918ed17f23760c9d10.png"
)
SAMPLES = ROOT / "NailTry" / "SampleDesigns"
OUT = ROOT / "MarketingAssets" / "Screenshots"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1290, 2796
WHITE = (255, 255, 255, 255)
MUTED = (255, 255, 255, 205)
ROSE = (240, 106, 151, 255)
INK = (45, 30, 38, 255)
LINE = (230, 210, 220, 255)


def jp_font(size, bold=False):
    paths = [
        r"C:\Windows\Fonts\SourceHanSansJP-Bold.otf" if bold else r"C:\Windows\Fonts\SourceHanSansJP-Normal.otf",
        r"C:\Windows\Fonts\NotoSansJP-VF.ttf",
        r"C:\Windows\Fonts\BIZ-UDGothicB.ttc" if bold else r"C:\Windows\Fonts\BIZ-UDGothicR.ttc",
        r"C:\Windows\Fonts\meiryob.ttc" if bold else r"C:\Windows\Fonts\meiryo.ttc",
    ]
    for path in paths:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


F_HUGE = jp_font(72, True)
F_TITLE = jp_font(54, True)
F_MID = jp_font(36, True)
F_SUB = jp_font(28)
F_SMALL = jp_font(24, True)
F_TINY = jp_font(19, True)
F_CHIP = jp_font(22, True)


def cover(path):
    img = Image.open(path).convert("RGB")
    scale = max(W / img.width, H / img.height)
    resized = img.resize((int(img.width * scale), int(img.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - W) // 2
    top = (resized.height - H) // 2
    return resized.crop((left, top, left + W, top + H)).convert("RGBA")


def gradient(base, top_alpha=100, bottom_alpha=170):
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pix = overlay.load()
    for y in range(H):
        a_top = max(0, int(top_alpha * (1 - y / 700)))
        a_bottom = max(0, int(bottom_alpha * ((y - 1550) / (H - 1550)))) if y > 1550 else 0
        alpha = max(a_top, a_bottom)
        for x in range(W):
            pix[x, y] = (0, 0, 0, alpha)
    return Image.alpha_composite(base, overlay)


def rr(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def glass(base, box, radius=42, fill=(255, 255, 255, 205), blur=20, outline=(255, 255, 255, 130)):
    x1, y1, x2, y2 = box
    bg = base.crop(box).filter(ImageFilter.GaussianBlur(blur))
    mask = Image.new("L", (x2 - x1, y2 - y1), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, x2 - x1, y2 - y1), radius=radius, fill=255)
    tint = Image.new("RGBA", (x2 - x1, y2 - y1), fill)
    bg = Image.alpha_composite(bg, tint)
    base.paste(bg, box, mask)
    ImageDraw.Draw(base).rounded_rectangle(box, radius=radius, outline=outline, width=2)


def status_bar(draw):
    draw.rounded_rectangle((520, 34, 770, 82), radius=24, fill=(0, 0, 0, 125))
    draw.text((72, 48), "9:41", font=F_SMALL, fill=WHITE)
    draw.text((1110, 48), "5G  ▰", font=F_TINY, fill=WHITE)


def top_copy(draw, title, subtitle):
    draw.text((58, 126), title, font=F_HUGE, fill=WHITE)
    draw.text((62, 222), subtitle, font=F_SUB, fill=MUTED)


def paste_tile(base, sid, box, selected=False, label=None):
    x, y, w, h = box
    tile = Image.open(SAMPLES / f"nail_sample_{sid:03d}.png").convert("RGBA").resize((w, h), Image.Resampling.LANCZOS)
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, w, h), radius=24, fill=255)
    base.paste(tile, (x, y), mask)
    d = ImageDraw.Draw(base)
    d.rounded_rectangle((x, y, x + w, y + h), radius=24, outline=ROSE if selected else LINE, width=6 if selected else 2)
    if label:
        text_w = d.textlength(label, font=F_TINY)
        d.text((x + (w - text_w) / 2, y + h + 10), label, font=F_TINY, fill=(90, 70, 82, 255))


def screenshot_tryon():
    canvas = gradient(cover(PHOTO_COSMIC), 145, 185)
    d = ImageDraw.Draw(canvas)
    status_bar(d)
    d.text((58, 126), "Nail Try", font=F_TITLE, fill=WHITE)
    d.text((58, 194), "爪にデザインを重ねて試着", font=F_SUB, fill=MUTED)
    rr(d, (58, 250, 390, 312), 31, (240, 106, 151, 215), outline=(255, 255, 255, 90), width=2)
    d.text((88, 266), "1000デザイン収録", font=F_SMALL, fill=WHITE)
    glass(canvas, (58, 1952, 1232, 2028), 38, (255, 255, 255, 70), 16)
    d = ImageDraw.Draw(canvas)
    d.ellipse((90, 1978, 112, 2000), fill=ROSE)
    d.text((130, 1970), "5本の指を検出中", font=F_SMALL, fill=WHITE)
    d.text((1110, 1972), "LIVE", font=F_TINY, fill=ROSE)
    glass(canvas, (34, 2058, 1256, 2746), 54, (255, 255, 255, 205), 24, (255, 255, 255, 145))
    d = ImageDraw.Draw(canvas)
    tabs = ["カラー", "サンプル", "グラデ", "画像", "設定"]
    tab_box = (82, 2100, 1208, 2172)
    rr(d, tab_box, 24, (255, 255, 255, 150), outline=LINE, width=2)
    tw = (tab_box[2] - tab_box[0]) // len(tabs)
    for i, tab in enumerate(tabs):
        x1 = tab_box[0] + i * tw
        x2 = tab_box[0] + (i + 1) * tw if i < len(tabs) - 1 else tab_box[2]
        if tab == "サンプル":
            rr(d, (x1 + 7, tab_box[1] + 7, x2 - 7, tab_box[3] - 7), 20, (255, 210, 225, 255))
            fill = ROSE
        else:
            fill = (115, 88, 100, 255)
        d.text((x1 + (x2 - x1 - d.textlength(tab, font=F_CHIP)) / 2, tab_box[1] + 22), tab, font=F_CHIP, fill=fill)
    d.text((82, 2206), "宇宙・星座デザイン", font=F_MID, fill=INK)
    ids = [201, 208, 217, 226, 236, 247, 253, 267, 279, 292]
    labels = ["星座", "三日月", "月リング", "星尾", "星図", "土星", "天球", "流星", "惑星", "銀月"]
    for idx, sid in enumerate(ids):
        r, c = divmod(idx, 5)
        paste_tile(canvas, sid, (82 + c * 230, 2278 + r * 206, 206, 148), idx == 1, labels[idx])
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((470, 2762, 820, 2773), radius=6, fill=(255, 255, 255, 220))
    canvas.convert("RGB").save(OUT / "nailtry_ui_cosmic_tryon.png", quality=95)


def screenshot_library():
    canvas = gradient(cover(PHOTO_NATURAL), 90, 200)
    d = ImageDraw.Draw(canvas)
    status_bar(d)
    top_copy(d, "1000種類から選べる", "カラー・キラキラ・キャラ・宇宙・季節デザインをすぐ試着")
    chips = [("カラー", 82, 345, 230), ("キラキラ", 250, 345, 430), ("キャラ", 450, 345, 604), ("宇宙", 624, 345, 760)]
    for text, x1, y1, x2 in chips:
        active = text == "宇宙"
        rr(d, (x1, y1, x2, y1 + 58), 29, (35, 38, 88, 230) if active else (255, 255, 255, 215), outline=(255, 255, 255, 120), width=2)
        d.text((x1 + (x2 - x1 - d.textlength(text, font=F_CHIP)) / 2, y1 + 15), text, font=F_CHIP, fill=WHITE if active else INK)
    glass(canvas, (34, 1638, 1256, 2746), 54, (255, 255, 255, 220), 24, (255, 255, 255, 150))
    d = ImageDraw.Draw(canvas)
    d.text((82, 1690), "サンプルデザイン", font=F_TITLE, fill=INK)
    d.text((84, 1760), "タップするだけで爪に反映", font=F_SUB, fill=(110, 90, 100, 255))
    rr(d, (875, 1694, 1206, 1752), 29, (240, 106, 151, 235))
    d.text((910, 1709), "全1000デザイン", font=F_CHIP, fill=WHITE)
    ids = [1, 7, 101, 116, 201, 208, 306, 415, 528, 642, 701, 736, 812, 921, 988]
    for idx, sid in enumerate(ids):
        r, c = divmod(idx, 5)
        paste_tile(canvas, sid, (82 + c * 228, 1834 + r * 242, 204, 166), sid == 208)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((470, 2762, 820, 2773), radius=6, fill=(255, 255, 255, 220))
    canvas.convert("RGB").save(OUT / "nailtry_ui_design_library.png", quality=95)


def paste_nail(base, texture, cx, cy, w, h, angle):
    tile = texture.resize((int(w * 1.8), int(h * 1.8)), Image.Resampling.LANCZOS)
    crop = tile.crop(((tile.width - int(w)) // 2, (tile.height - int(h)) // 2, (tile.width + int(w)) // 2, (tile.height + int(h)) // 2))
    mask = Image.new("L", (int(w), int(h)), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, int(w), int(h)), radius=int(min(w, h) * 0.45), fill=235)
    gloss = Image.new("RGBA", (int(w), int(h)), (255, 255, 255, 0))
    gd = ImageDraw.Draw(gloss)
    gd.ellipse((int(w * 0.18), int(h * 0.05), int(w * 0.45), int(h * 0.35)), fill=(255, 255, 255, 70))
    nail = Image.alpha_composite(crop, gloss)
    nail.putalpha(mask)
    rot = nail.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    base.alpha_composite(rot, (int(cx - rot.width / 2), int(cy - rot.height / 2)))


def screenshot_fit():
    canvas = gradient(cover(PHOTO_NATURAL), 120, 210)
    texture = Image.open(SAMPLES / "nail_sample_208.png").convert("RGBA")
    for args in [(350, 1345, 92, 220, -22), (535, 1360, 94, 230, -8), (710, 1465, 94, 230, 6), (875, 1590, 92, 220, 13), (1032, 1770, 82, 194, 20)]:
        paste_nail(canvas, texture, *args)
    d = ImageDraw.Draw(canvas)
    status_bar(d)
    top_copy(d, "爪にぴったり調整", "サイズ・位置・濃さを見ながらリアルタイムで合わせる")
    for cx, cy, w, h in [(350, 1345, 106, 238), (535, 1360, 108, 248), (710, 1465, 108, 248), (875, 1590, 106, 238), (1032, 1770, 96, 214)]:
        d.rounded_rectangle((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), radius=48, outline=(255, 255, 255, 145), width=3)
        d.rounded_rectangle((cx - w / 2 - 8, cy - h / 2 - 8, cx + w / 2 + 8, cy + h / 2 + 8), radius=56, outline=(240, 106, 151, 120), width=2)
    glass(canvas, (58, 1900, 1232, 1978), 39, (255, 255, 255, 75), 16)
    d = ImageDraw.Draw(canvas)
    d.ellipse((92, 1926, 114, 1948), fill=ROSE)
    d.text((132, 1918), "5本の指を検出中", font=F_SMALL, fill=WHITE)
    d.text((1110, 1920), "LIVE", font=F_TINY, fill=ROSE)
    glass(canvas, (34, 2014, 1256, 2746), 54, (255, 255, 255, 225), 24, (255, 255, 255, 155))
    d = ImageDraw.Draw(canvas)
    d.text((82, 2065), "フィット調整", font=F_TITLE, fill=INK)
    d.text((84, 2136), "爪に合わせて自然に見せる", font=F_SUB, fill=(110, 90, 100, 255))
    paste_tile(canvas, 208, (84, 2210, 210, 210), True)
    d = ImageDraw.Draw(canvas)
    d.text((330, 2224), "星座ネイルを適用中", font=F_MID, fill=INK)
    d.text((332, 2278), "濃さ・サイズ・先端寄せを調整", font=F_SUB, fill=(110, 90, 100, 255))

    def slider(y, label, value, percent):
        d.text((330, y), label, font=F_SMALL, fill=INK)
        d.text((1090, y), value, font=F_SMALL, fill=(110, 90, 100, 255))
        x1, x2, yy = 330, 1160, y + 58
        d.rounded_rectangle((x1, yy, x2, yy + 12), radius=6, fill=(230, 218, 224, 255))
        d.rounded_rectangle((x1, yy, x1 + int((x2 - x1) * percent), yy + 12), radius=6, fill=ROSE)
        knob = x1 + int((x2 - x1) * percent)
        d.ellipse((knob - 24, yy - 18, knob + 24, yy + 30), fill=WHITE, outline=ROSE, width=5)

    slider(2370, "不透明度", "78%", 0.68)
    slider(2490, "爪サイズ", "100%", 0.48)
    slider(2610, "先端寄せ", "0", 0.50)
    d.rounded_rectangle((470, 2762, 820, 2773), radius=6, fill=(255, 255, 255, 220))
    canvas.convert("RGB").save(OUT / "nailtry_ui_fit_adjust.png", quality=95)


screenshot_tryon()
screenshot_library()
screenshot_fit()
print(OUT / "nailtry_ui_cosmic_tryon.png")
print(OUT / "nailtry_ui_design_library.png")
print(OUT / "nailtry_ui_fit_adjust.png")
