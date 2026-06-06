import numpy as np

N = 256
x = np.concatenate([
    np.linspace(-8, -4, N//4, endpoint=False),
    np.linspace(-4, -2, N//4, endpoint=False),
    np.linspace(-2, 0, N//2, endpoint=False)
])

y = 1 / (1 + np.exp(-x))

y_fixed = np.floor(y * 4096).astype(int)

with open("data/sigmoid_optimized.hex", "w") as f:
    for val in y_fixed:
        f.write(f"{val:04X}\n")
