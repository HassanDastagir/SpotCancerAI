from PIL import Image
import numpy as np
import os

out_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'backend', 'data', 'test.png')
os.makedirs(os.path.dirname(out_path), exist_ok=True)
# Create a simple RGB gradient image 256x256
w=h=256
x=np.linspace(0,255,w,dtype=np.uint8)
y=np.linspace(0,255,h,dtype=np.uint8)
r=np.tile(x,(h,1))
g=np.tile(y.reshape(h,1),(1,w))
b=np.full((h,w),128,dtype=np.uint8)
img=np.dstack([r,g,b])
Image.fromarray(img).save(out_path)
print('Wrote', out_path)