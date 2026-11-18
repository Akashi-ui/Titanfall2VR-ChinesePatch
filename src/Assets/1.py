
from PIL import Image
import os
import sys

def convert_to_ico(input_path, output_path=None):
    try:
        img = Image.open(input_path).convert("RGBA")

        if output_path is None:
            output_path = os.path.splitext(input_path)[0] + ".ico"

        # 生成常用 Windows 图标尺寸
        img.save(
            output_path,
            format="ICO",
            sizes=[
                (16, 16),
                (32, 32),
                (48, 48),
                (64, 64),
                (128, 128),
                (256, 256)
            ]
        )

        print(f"[成功] {input_path} -> {output_path}")

    except Exception as e:
        print(f"[失败] {input_path}: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python img2ico.py 图片路径")
        print("     python img2ico.py 图片文件夹")
        sys.exit(1)

    path = sys.argv[1]

    if os.path.isfile(path):
        convert_to_ico(path)

    elif os.path.isdir(path):
        for filename in os.listdir(path):
            if filename.lower().endswith(
                (".png", ".jpg", ".jpeg", ".webp", ".bmp")
            ):
                full_path = os.path.join(path, filename)
                convert_to_ico(full_path)

        print("批量转换完成！")

    else:
        print("文件或文件夹不存在！")
