#!/usr/bin/env python3
import re
import subprocess

def encode_nano(val):
    sign = 1 if val < 0 else 0
    # Clamping to [-127, 127]
    val_clamped = max(-127, min(127, val))
    mag = (~(val_clamped & 0x7F)) & 0x7F if sign else (val_clamped & 0x7F)
    zero = 1 if (val_clamped & 0x7F) == 0 else 0
    
    if (mag & (1 << 6)):   ka, fa = 6, (mag >> 5) & 1
    elif (mag & (1 << 5)): ka, fa = 5, (mag >> 4) & 1
    elif (mag & (1 << 4)): ka, fa = 4, (mag >> 3) & 1
    elif (mag & (1 << 3)): ka, fa = 3, (mag >> 2) & 1
    elif (mag & (1 << 2)): ka, fa = 2, (mag >> 1) & 1
    elif (mag & (1 << 1)): ka, fa = 1, (mag >> 0) & 1
    else:                 ka, fa = 0, 0
    
    return (sign << 7) | (zero << 6) | (ka << 1) | fa

def generate_rom(src_branch, rom_name, addr_bits, scale_factor=1.0):
    cmd = ["git", "show", f"{src_branch}:rtl/{rom_name}"]
    raw_content = subprocess.check_output(cmd, cwd="/workspace/projects/cnn_mnist").decode("utf-8")
    
    pattern = re.compile(rf"({addr_bits}'d\d+:\s+data\s*=\s*)([-]?\s*8'sd\d+);")
    
    def replacer(match):
        prefix = match.group(1)
        val_str = match.group(2).replace(" ", "")
        if val_str.startswith("-8'sd"):
            orig_val = -int(val_str.replace("-8'sd", ""))
        else:
            orig_val = int(val_str.replace("8'sd", ""))
        
        # Apply pre-scaling factor
        scaled_val = int(round(orig_val * scale_factor))
        scaled_val = max(-127, min(127, scaled_val))
        
        code = encode_nano(scaled_val)
        return f"{prefix}8'h{code:02X}; // Orig: {orig_val:+4d} -> Scaled: {scaled_val:+4d}"
    
    new_content = pattern.sub(replacer, raw_content)
    dest_path = f"/workspace/projects/cnn_mnist/rtl/{rom_name}"
    with open(dest_path, "w") as f:
        f.write(new_content)
    print(f"[OK] Generated {rom_name} with scale_factor={scale_factor:.4f}")

if __name__ == "__main__":
    import sys
    scale = float(sys.argv[1]) if len(sys.argv) > 1 else 1.07
    generate_rom("baseline", "conv2d_kernel_rom.v", 6, scale)
    generate_rom("baseline", "dense_weights_rom.v", 12, scale)
