"""
Compare the two sigmoid LUT architectures:
  - uniform   : 256 evenly spaced nodes over [-8, 8)
  - optimized : symmetry sigma(-x)=1-sigma(x) + 3 segments of different density

The Python models are FAITHFUL to the RTL (floor to Q4.12, 1-sigma fold, same
address/segment formulas), so the errors match the simulation.

Outputs:
  - img/compare_error.png  : approximation error of both models vs x (at N=256)
  - img/error_vs_size.png  : max/mean error vs table size (sweep over N)
and prints a Markdown table for the README.
"""

import numpy as np
import matplotlib.pyplot as plt

SCALE = 4096          # Q4.12
LO, HI = -8.0, 8.0


def sigmoid(x):
    return 1.0 / (1.0 + np.exp(-x))


def quant(v):
    """Quantize to Q4.12 by floor (same as gen_*.py and the SV predictor)."""
    return np.floor(v * SCALE).astype(np.int64)


# ---------------------------------------------------------------------------
#  UNIFORM model (faithful to sigmoid_lut.sv)
# ---------------------------------------------------------------------------
def uniform_approx(x, N):
    step = 16.0 / N
    nodes = LO + np.arange(N) * step
    table = quant(sigmoid(nodes))
    idx = np.clip(np.floor((x - LO) / step).astype(np.int64), 0, N - 1)
    return table[idx] / SCALE


# ---------------------------------------------------------------------------
#  OPTIMIZED model (faithful to sigmoid_lut_optimized.sv)
#  Left half [-8,0): seg0 [-8,-4)=N/4, seg1 [-4,-2)=N/4, seg2 [-2,0)=N/2.
#  Right half reconstructed via the 1-sigma fold. x=0 is the symmetry axis.
# ---------------------------------------------------------------------------
def optimized_approx(x, N):
    n0 = N // 4               # [-8,-4)
    n1 = N // 4               # [-4,-2)
    n2 = N - n0 - n1          # [-2,0)  (= N/2)
    st0, st1, st2 = 4.0 / n0, 2.0 / n1, 2.0 / n2

    nodes = np.concatenate([
        -8 + np.arange(n0) * st0,
        -4 + np.arange(n1) * st1,
        -2 + np.arange(n2) * st2,
    ])
    table = quant(sigmoid(nodes))

    x = np.asarray(x, dtype=float)
    m = np.abs(x)
    xn = -m                                   # fold to negative magnitude
    idx = np.empty_like(x, dtype=np.int64)

    s0 = m >= 4                               # seg0
    s1 = (m >= 2) & (m < 4)                   # seg1
    s2 = m < 2                                # seg2
    idx[s0] = np.floor((xn[s0] + 8) / st0).astype(np.int64)
    idx[s1] = n0 + np.floor((xn[s1] + 4) / st1).astype(np.int64)
    idx[s2] = n0 + n1 + np.floor((xn[s2] + 2) / st2).astype(np.int64)
    idx = np.clip(idx, 0, N - 1)

    raw = table[idx]
    y = np.where(x < 0, raw, SCALE - raw).astype(float)   # fold for x>0
    y = np.where(x == 0, SCALE / 2, y)                     # symmetry axis
    return y / SCALE


# ---------------------------------------------------------------------------
#  Error metrics
# ---------------------------------------------------------------------------
def errors(approx_fn, N, n=400000):
    xs = np.linspace(LO, HI, n, endpoint=False)
    err = np.abs(approx_fn(xs, N) - sigmoid(xs))
    return err, xs


def stats(approx_fn, N):
    err, _ = errors(approx_fn, N)
    return err.max(), err.mean()


# ---------------------------------------------------------------------------
#  Plot 1: error vs x at N=256
# ---------------------------------------------------------------------------
N = 256
err_u, xs = errors(uniform_approx, N)
err_o, _ = errors(optimized_approx, N)

fig, ax = plt.subplots(figsize=(11, 5))
ax.plot(xs, err_u, color="tab:blue", lw=0.8, label=f"uniform (max={err_u.max():.4f})")
ax.plot(xs, err_o, color="tab:red", lw=0.8, label=f"optimized (max={err_o.max():.4f})")
ax.set_title(f"Approximation error |LUT(x) - sigma(x)|, N={N} entries")
ax.set_xlabel("x")
ax.set_ylabel("absolute error")
ax.grid(alpha=0.3)
ax.legend()
fig.tight_layout()
fig.savefig("img/compare_error.png", dpi=120)
print("saved img/compare_error.png")

# ---------------------------------------------------------------------------
#  Plot 2 + table: max/mean error vs table size
# ---------------------------------------------------------------------------
sizes = [8, 16, 32, 64, 128, 256, 512, 1024]
u_max, u_mean, o_max, o_mean = [], [], [], []
for n in sizes:
    mx, mn = stats(uniform_approx, n)
    u_max.append(mx); u_mean.append(mn)
    mx, mn = stats(optimized_approx, n)
    o_max.append(mx); o_mean.append(mn)

fig, ax = plt.subplots(figsize=(9, 6))
ax.loglog(sizes, u_max, "o-", color="tab:blue", label="uniform max")
ax.loglog(sizes, u_mean, "o--", color="tab:blue", alpha=0.6, label="uniform mean")
ax.loglog(sizes, o_max, "s-", color="tab:red", label="optimized max")
ax.loglog(sizes, o_mean, "s--", color="tab:red", alpha=0.6, label="optimized mean")
ax.set_xticks(sizes)
ax.set_xticklabels([f"{n}" for n in sizes])
ax.set_title("Approximation error vs table size")
ax.set_xlabel("number of entries N")
ax.set_ylabel("absolute error")
ax.grid(alpha=0.3, which="both")
ax.legend()
fig.tight_layout()
fig.savefig("img/error_vs_size.png", dpi=120)
print("saved img/error_vs_size.png")

# Markdown table for the README
print("\n| N | uniform max | uniform mean | optimized max | optimized mean | max improvement |")
print("|---|---|---|---|---|---|")
for i, n in enumerate(sizes):
    print(f"| {n} | {u_max[i]:.5f} | {u_mean[i]:.5f} | "
          f"{o_max[i]:.5f} | {o_mean[i]:.5f} | {u_max[i]/o_max[i]:.2f}x |")
