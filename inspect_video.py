from moviepy import VideoFileClip

try:
    clip = VideoFileClip("loading_animation.mp4")
    frame = clip.get_frame(0)
    h, w, c = frame.shape
    top_left = frame[0, 0]
    print(f"Video resolution: {w}x{h}")
    print(f"Top left pixel color: {top_left}")
    print(f"Total duration: {clip.duration}s, FPS: {clip.fps}")
    clip.close()
except Exception as e:
    print(f"Error: {e}")
