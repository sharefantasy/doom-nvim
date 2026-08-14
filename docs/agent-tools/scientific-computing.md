# 形式化与科学计算工作流

Lean 负责机器可检查的定义和证明；Python 负责数值实验、数据处理和可视化。两者互相
补充，不应强迫其中一套承担所有任务。

## 推荐目录

```text
geometry-lab/
├── formal/       # Lean + Mathlib
├── numeric/      # uv + Python 3.12
├── notebooks/    # 数值实验
├── data/         # 输入数据
└── notes/        # 推导、假设和形式化映射
```

## Mathlib 适合的内容

- 光滑流形、带角流形和 Riemannian geometry 基础。
- 切空间、向量丛、微分和积分。
- 测度论、概率论和内积空间。
- Fourier transform、inversion、Poisson summation。
- 卷积、Schwartz space 和分布。

Mathlib 目前不提供成熟的通用信息几何和工程 DSP 框架。Fisher information metric、
α-connection、STFT、wavelet、FIR/IIR 等内容通常需要自行形式化，或者先在数值环境中
探索。

## Python 环境

使用独立 `uv` 项目，不修改系统 Python：

```bash
mkdir -p geometry-lab/numeric
cd geometry-lab/numeric
uv init --python 3.12
uv add numpy scipy sympy matplotlib jupyterlab ipykernel
uv add geomstats pymanopt autograd
uv add librosa soundfile PyWavelets control cvxpy
```

用途：

- `numpy` / `scipy`：线性代数、积分、优化和信号处理。
- `sympy`：符号推导。
- `matplotlib`：流形、轨迹、频谱和滤波结果。
- `geomstats`：流形统计、Riemannian geometry 和 Fisher-Rao。
- `pymanopt` / `autograd`：流形约束优化。
- `librosa` / `soundfile`：音频和时频分析。
- `PyWavelets`：小波。
- `control`：传递函数和状态空间系统。
- `cvxpy`：凸优化和带约束滤波器设计。

启动：

```bash
uv run jupyter lab
```

## 已有系统基础

当前机器已有的基础能力包括：

- Apple Silicon arm64。
- `uv`、`clang`、`cargo`。
- `cmake`、`ninja`、`pkg-config`。
- `ffmpeg`、`libsndfile`、`graphviz`。

只有出现明确需求时再补：

```bash
# 实时音频输入
brew install portaudio

# pyFFTW 或显式 FFTW 基准
brew install fftw
uv add pyfftw
```

暂时不要默认安装 Julia、SageMath、PyTorch、JAX 或 OpenBLAS。它们应由明确的问题规模、
GPU 或算法需求触发。

## 从实验到证明

推荐闭环：

1. 在 Notebook 中提出模型并进行数值实验。
2. 明确参数范围、正则性、可积性和边界条件。
3. 把稳定结论改写成与实现无关的数学命题。
4. 在 Lean 中复用 Mathlib 定义并补齐缺失 lemma。
5. 用 `lean-lsp-mcp` 做局部证明反馈。
6. 使用 `lean_verify` 和 `lake build` 做最终机器检查。

数值实验可以发现模式和反例，但不能替代 Lean proof；Lean proof 可以保证命题正确，但
不会自动提供高性能 DSP 实现。
