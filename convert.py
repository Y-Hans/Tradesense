import numpy as np
from moviepy import VideoFileClip
from PIL import Image

clip = VideoFileClip("loading_animation.mp4")
bg_color = np.array([0, 83, 6])
threshold = 50

min_y, max_y, min_x, max_x = 10000, 0, 10000, 0
all_frames_data = []

print("Extracting frames and finding bounding box...")
for frame in clip.iter_frames():
    dist = np.linalg.norm(frame - bg_color, axis=-1)
    mask = dist > threshold
    if np.any(mask):
        ys, xs = np.where(mask)
        min_y = min(min_y, ys.min())
        max_y = max(max_y, ys.max())
        min_x = min(min_x, xs.min())
        max_x = max(max_x, xs.max())
    
    alpha = np.where(mask, 255, 0).astype(np.uint8)
    rgba = np.dstack((frame, alpha))
    all_frames_data.append(rgba)

padding = 10
min_y = max(0, min_y - padding)
max_y = min(clip.h, max_y + padding)
min_x = max(0, min_x - padding)
max_x = min(clip.w, max_x + padding)

print(f"Cropping to: y={min_y}:{max_y}, x={min_x}:{max_x}")

final_frames = []
for rgba in all_frames_data:
    cropped = rgba[min_y:max_y, min_x:max_x]
    img = Image.fromarray(cropped)
    img.thumbnail((120, 120), Image.Resampling.LANCZOS)
    final_frames.append(img)

print("Saving as transparent GIF...")
final_frames[0].save('assets/animations/bitcoin_loading.gif', 
                     save_all=True, append_images=final_frames[1:], 
                     optimize=True, duration=int(1000/clip.fps), loop=0, disposal=2)
print("Done!")
