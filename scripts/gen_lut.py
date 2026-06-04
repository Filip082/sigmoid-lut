import numpy as np

N = 256
x = np.linspace(-8, 8, N + 1)
y = 1 / (1 + np.exp(-x))

y_fixed = np.floor(y * 4096).astype(int)

with open("data/sigmoid.hex", "w") as f:
    for val in y_fixed[:-1]:
        f.write(f"{val:04X}\n")
