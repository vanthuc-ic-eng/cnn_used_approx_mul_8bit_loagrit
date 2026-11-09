#!/usr/bin/env python3
import re
import os

def encode_nano(val):
    sign = 1 if val < 0 else 0
    mag = (~(val & 0x7F)) & 0x7F if sign else (val & 0x7F)
    zero = 1 if (val & 0x7F) == 0 else 0
    
    if (mag & (1 << 6)):   ka, fa = 6, (mag >> 5) & 1
    elif (mag & (1 << 5)): ka, fa = 5, (mag >> 4) & 1
    elif (mag & (1 << 4)): ka, fa = 4, (mag >> 3) & 1
    elif (mag & (1 << 3)): ka, fa = 3, (mag >> 2) & 1
    elif (mag & (1 << 2)): ka, fa = 2, (mag >> 1) & 1
    elif (mag & (1 << 1)): ka, fa = 1, (mag >> 0) & 1
    else:                 ka, fa = 0, 0
    
    # 8-bit packed: {sign, zero, 2'b00, k[2:0], f}
    return (sign << 7) | (zero << 6) | (ka << 1) | fa

def convert_rom(file_path, addr_bits):
    with open(file_path, "r") as f:
        content = f.read()
    
    pattern = re.compile(rf"({addr_bits}'d\d+:\s+data\s*=\s*)([-]?\s*8'sd\d+);")
    
    def replacer(match):
        prefix = match.group(1)
        val_str = match.group(2).replace(" ", "")
        if val_str.startswith("-8'sd"):
            val = -int(val_str.replace("-8'sd", ""))
        else:
            val = int(val_str.replace("8'sd", ""))
        code = encode_nano(val)
        return f"{prefix}8'h{code:02X}; // Orig: {val:+4d}"
    
    new_content = pattern.sub(replacer, content)
    with open(file_path, "w") as f:
        f.write(new_content)
    print(f"[OK] Pre-encoded {file_path} into Log8-Nano format!")

if __name__ == "__main__":
    convert_rom("/workspace/projects/cnn_mnist/rtl/conv2d_kernel_rom.v", 6)
    convert_rom("/workspace/projects/cnn_mnist/rtl/dense_weights_rom.v", 12)
