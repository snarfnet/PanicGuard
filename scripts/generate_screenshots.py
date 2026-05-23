from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import math
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots"
HERO = Image.open(ROOT / "PanicGuard" / "Assets.xcassets" / "HeroComic.imageset" / "hero_comic.png").convert("RGB")
FONT_REGULAR = Path(r"C:\Windows\Fonts\meiryo.ttc")
FONT_BOLD = Path(r"C:\Windows\Fonts\meiryob.ttc")
if not FONT_BOLD.exists():
    FONT_BOLD = FONT_REGULAR


def font(size, bold=False):
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REGULAR), size)


def rounded(draw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def gradient(size, top=(255, 255, 255), bottom=(255, 232, 240)):
    width, height = size
    image = Image.new("RGB", size)
    px = image.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(width):
            px[x, y] = color
    return image


def center_text(draw, box, text, fnt, fill, spacing=8):
    x1, y1, x2, y2 = box
    bbox = draw.multiline_textbbox((0, 0), text, font=fnt, spacing=spacing, align="center")
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.multiline_text(
        (x1 + (x2 - x1 - tw) / 2, y1 + (y2 - y1 - th) / 2),
        text,
        font=fnt,
        fill=fill,
        spacing=spacing,
        align="center",
    )


def topbar(draw, width, margin, y, title, color=(255, 87, 132)):
    rounded(draw, (margin, y, width - margin, y + 92), 18, color)
    draw.text((margin + 40, y + 28), "9:41", font=font(24, True), fill="white")
    center_text(draw, (margin, y, width - margin, y + 92), title, font(31, True), "white")
    draw.ellipse((width - margin - 78, y + 32, width - margin - 58, y + 52), outline="white", width=4)
    draw.line((width - margin - 68, y + 22, width - margin - 68, y + 62), fill="white", width=4)
    draw.line((width - margin - 88, y + 42, width - margin - 48, y + 42), fill="white", width=4)


def paste_cover(base, source, box, radius=22):
    x1, y1, x2, y2 = box
    bw, bh = x2 - x1, y2 - y1
    image = source.copy()
    scale = max(bw / image.width, bh / image.height)
    image = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    image = image.crop(((image.width - bw) // 2, (image.height - bh) // 2, (image.width + bw) // 2, (image.height + bh) // 2))
    mask = Image.new("L", (bw, bh), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, bw, bh), radius=radius, fill=255)
    base.paste(image, (x1, y1), mask)


def tile(draw, box, color, bg, icon, title):
    rounded(draw, box, 20, bg)
    x1, y1, x2, y2 = box
    center_text(draw, (x1, y1 + 20, x2, y1 + 85), icon, font(54, True), color)
    center_text(draw, (x1 + 10, y1 + 92, x2 - 10, y2 - 14), title, font(25, True), color)


def home(size):
    width, height = size
    margin = int(width * 0.055)
    image = gradient(size)
    draw = ImageDraw.Draw(image)
    topbar(draw, width, margin, 42, "ストーカー撃退")

    y = 158
    paste_cover(image, HERO, (margin, y, width - margin, y + int(height * 0.21)))
    bubble = (margin + 28, y + 28, margin + int(width * 0.38), y + int(height * 0.18))
    rounded(draw, bubble, 18, "white", "black", 4)
    center_text(draw, bubble, "あなたを\n守るために\nいつでも\nサポート！", font(int(width * 0.032), True), "black")

    y += int(height * 0.23)
    gap = 22
    tile_w = (width - margin * 2 - gap) // 2
    tile_h = int(height * 0.145)
    tile(draw, (margin, y, margin + tile_w, y + tile_h), (255, 54, 104), (255, 230, 238), "●", "SOSアラーム")
    tile(draw, (margin + tile_w + gap, y, width - margin, y + tile_h), (250, 154, 20), (255, 248, 228), "♪", "録音・証拠を残す")
    y += tile_h + gap
    tile(draw, (margin, y, margin + tile_w, y + tile_h), (58, 174, 168), (229, 250, 248), "◆", "現在地を送信")
    tile(draw, (margin + tile_w + gap, y, width - margin, y + tile_h), (112, 100, 190), (242, 240, 255), "☎", "偽着信で離脱")

    y += tile_h + gap
    rounded(draw, (margin, y, width - margin, y + 118), 18, "white")
    draw.text((margin + 36, y + 28), "緊急時はすぐにSOS！", font=font(29, True), fill=(30, 25, 28))
    draw.text((margin + 36, y + 70), "大きな音と通知で助けを呼びます", font=font(21), fill=(110, 105, 110))
    draw.text((width - margin - 60, y + 42), "›", font=font(44, True), fill=(160, 150, 155))
    return image


def alert(size):
    width, height = size
    margin = int(width * 0.055)
    image = gradient(size)
    draw = ImageDraw.Draw(image)
    topbar(draw, width, margin, 42, "SOSアラーム")
    cx, cy = width // 2, int(height * 0.39)
    for i in range(64):
        angle = math.tau * i / 64
        draw.line(
            (cx + math.cos(angle) * 90, cy + math.sin(angle) * 90, cx + math.cos(angle) * int(height * 0.27), cy + math.sin(angle) * int(height * 0.27)),
            fill=(255, 188, 205),
            width=2,
        )
    draw.text((width // 2, int(height * 0.20)), "助けて！", font=font(int(width * 0.07), True), fill=(255, 54, 104), anchor="mm")
    draw.text((width // 2, int(height * 0.26)), "SOSアラーム作動中", font=font(int(width * 0.046), True), fill=(20, 15, 18), anchor="mm")
    draw.ellipse((cx - 130, cy - 130, cx + 130, cy + 130), fill=(255, 72, 119), outline=(255, 220, 230), width=16)
    draw.text((cx, cy), "●", font=font(92, True), fill="white", anchor="mm")
    draw.text((cx, cy + 170), "タップで停止", font=font(25, True), fill=(40, 35, 38), anchor="mm")

    y = int(height * 0.58)
    rounded(draw, (margin, y, width - margin, y + 300), 20, "white")
    draw.text((margin + 34, y + 34), "アラームの効果", font=font(31, True), fill=(255, 54, 104))
    for idx, text in enumerate(["大音量のサイレンを鳴らします", "周囲に危険を知らせます", "登録した連絡先にSOSを送れます", "証拠用の録音を残します"]):
        yy = y + 92 + idx * 48
        draw.text((margin + 40, yy), "✓", font=font(25, True), fill=(255, 54, 104))
        draw.text((margin + 82, yy), text, font=font(23, True), fill=(55, 50, 54))
    return image


def record(size):
    width, height = size
    margin = int(width * 0.055)
    image = gradient(size, (255, 255, 255), (255, 247, 229))
    draw = ImageDraw.Draw(image)
    topbar(draw, width, margin, 42, "録音・証拠を残す", (255, 168, 24))
    draw.text((width // 2, int(height * 0.20)), "録音中...", font=font(int(width * 0.06), True), fill=(255, 160, 20), anchor="mm")
    draw.text((width // 2, int(height * 0.26)), "00:02:48", font=font(int(width * 0.06), True), fill=(20, 18, 20), anchor="mm")
    y = int(height * 0.36)
    for x in range(margin, width - margin, 18):
        amp = 30 + int(50 * abs(math.sin(x * 0.04)))
        draw.line((x, y - amp, x, y + amp), fill=(255, 168, 24), width=4)
    cx, cy = width // 2, int(height * 0.51)
    draw.ellipse((cx - 102, cy - 102, cx + 102, cy + 102), fill=(255, 168, 24), outline=(255, 236, 195), width=12)
    draw.rounded_rectangle((cx - 35, cy - 35, cx + 35, cy + 35), radius=9, fill="white")
    draw.text((cx, cy + 150), "タップで停止", font=font(25, True), fill=(90, 82, 76), anchor="mm")
    y = int(height * 0.72)
    rounded(draw, (margin, y, width - margin, y + 190), 18, "white")
    draw.text((margin + 30, y + 28), "保存された録音", font=font(24, True), fill=(50, 45, 42))
    draw.text((margin + 30, y + 110), "2026/05/23 19:32", font=font(25), fill=(45, 42, 40))
    draw.text((width - margin - 210, y + 110), "00:05:21", font=font(25), fill=(45, 42, 40))
    draw.ellipse((width - margin - 92, y + 84, width - margin - 36, y + 140), fill=(255, 168, 24))
    draw.text((width - margin - 64, y + 112), "▶", font=font(24, True), fill="white", anchor="mm")
    return image


def location(size):
    width, height = size
    margin = int(width * 0.055)
    image = gradient(size, (255, 255, 255), (230, 250, 248))
    draw = ImageDraw.Draw(image)
    topbar(draw, width, margin, 42, "現在地を送信", (62, 184, 178))
    draw.text((width // 2, int(height * 0.20)), "現在地を共有中", font=font(int(width * 0.052), True), fill=(62, 184, 178), anchor="mm")
    center_text(draw, (margin, int(height * 0.24), width - margin, int(height * 0.32)), "あなたの位置情報を\n見守り人に送信しています", font(int(width * 0.032), True), (35, 30, 33))
    y = int(height * 0.35)
    rounded(draw, (margin, y, width - margin, y + 250), 18, (238, 244, 241))
    for i in range(6):
        draw.line((margin, y + 40 + i * 35, width - margin, y + 15 + i * 35), fill=(210, 220, 215), width=3)
    for i in range(4):
        draw.line((margin + 60 + i * 120, y, width - margin - 40 + i * 20, y + 250), fill=(210, 220, 215), width=3)
    cx, cy = width // 2, y + 125
    draw.ellipse((cx - 100, cy - 100, cx + 100, cy + 100), fill=(255, 210, 220))
    draw.ellipse((cx - 35, cy - 35, cx + 35, cy + 35), fill=(255, 54, 104))
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill="white")
    y += 300
    draw.text((margin, y), "共有先（3件）", font=font(24, True), fill=(80, 75, 78))
    draw.text((width - margin - 80, y), "編集", font=font(24, True), fill=(62, 184, 178))
    for idx, name in enumerate(["お母さん", "親友 ゆき", "警察相談専用ダイヤル"]):
        yy = y + 58 + idx * 80
        draw.ellipse((margin, yy, margin + 52, yy + 52), fill=(200, 205, 205))
        draw.text((margin + 70, yy), name, font=font(24, True), fill=(45, 42, 45))
        draw.text((margin + 70, yy + 32), "090-1234-5678" if idx < 2 else "#9110", font=font(19), fill=(120, 115, 118))
        draw.text((width - margin - 110, yy + 15), "送信中...", font=font(20, True), fill=(62, 184, 178))
    rounded(draw, (margin, int(height * 0.90), width - margin, int(height * 0.945)), 14, "white", (62, 184, 178), 2)
    center_text(draw, (margin, int(height * 0.90), width - margin, int(height * 0.945)), "共有を停止する", font(25, True), (62, 184, 178))
    return image


SCREENS = [
    ("screenshot_01_ready.png", home),
    ("screenshot_02_active.png", alert),
    ("screenshot_03_record.png", record),
    ("screenshot_04_location.png", location),
]


def main():
    (OUT / "iphone").mkdir(exist_ok=True)
    (OUT / "ipad").mkdir(exist_ok=True)
    for prefix, size, subdir in [("", (1290, 2796), "iphone"), ("ipad_", (2048, 2732), "ipad")]:
        for name, builder in SCREENS:
            filename = prefix + name
            image = builder(size)
            image.save(OUT / filename, optimize=True)
            image.save(OUT / subdir / filename, optimize=True)
        aliases = {
            prefix + "screenshot_03_record.png": prefix + "screenshot_03_fakecall.png",
            prefix + "screenshot_04_location.png": prefix + "screenshot_04_japanese.png",
        }
        for src, dest in aliases.items():
            shutil.copyfile(OUT / src, OUT / dest)
            shutil.copyfile(OUT / subdir / src, OUT / subdir / dest)
    print("Generated updated App Store screenshots")


if __name__ == "__main__":
    main()
