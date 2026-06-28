# Veil-Miner
Veil ProgPOW miner with CPU mining support for Apple Silicon (ARM) and Linux/Windows GPU mining via OpenCL and CUDA.

## Table of Contents
- [Requirements](#requirements)
- [Building on macOS (Apple Silicon)](#building-on-macos-apple-silicon)
- [Building on Linux](#building-on-linux)
- [Running the miner](#running-the-miner)
- [Notes](#notes)

---

## Requirements

### macOS (Apple Silicon — M1/M2/M3/M4)
Install dependencies via Homebrew:
```bash
brew install cmake boost@1.85 jsoncpp openssl@3 cli11 pkg-config git
```

### Linux
```bash
sudo apt-get install build-essential cmake libboost-all-dev libjsoncpp-dev libssl-dev
```

---

## Building on macOS (Apple Silicon)

```bash
# 1. Clone the repo
git clone https://github.com/ohcee/Veil-Miner.git
cd Veil-Miner/veil-progpow-miner

# 2. Pull the cmake submodules
git clone https://github.com/ethereum/cable cmake/cable
git clone https://github.com/hunter-packages/disabled-mode cmake/Hunter/disabled-mode

# 3. Create build directory
mkdir build && cd build

# 4. Configure (CPU mining is auto-enabled on Apple Silicon)
cmake -DETHASHCPU=ON -DETHASHCL=OFF -DETHASHCUDA=OFF ..

# 5. Build
make -j$(sysctl -n hw.logicalcpu)
```

The binary will be at `build/veilminer/veilminer`.

---

## Building on Linux

```bash
git clone https://github.com/ohcee/Veil-Miner.git
cd Veil-Miner/veil-progpow-miner

git clone https://github.com/ethereum/cable cmake/cable
git clone https://github.com/hunter-packages/disabled-mode cmake/Hunter/disabled-mode

mkdir build && cd build

# GPU (OpenCL + CUDA)
cmake -DETHASHCL=ON -DETHASHCUDA=ON -DETHASHCPU=OFF ..

# CPU only
cmake -DETHASHCL=OFF -DETHASHCUDA=OFF -DETHASHCPU=ON ..

make -j$(nproc)
```

---

## Running the miner

### CPU mining (macOS / Linux)
```bash
./build/veilminer/veilminer --cpu -P stratum+tcp://WALLET_ADDRESS@POOL_HOST:PORT
```

### GPU mining — OpenCL (AMD / Intel)
```bash
./build/veilminer/veilminer --cl -P stratum+tcp://WALLET_ADDRESS@POOL_HOST:PORT
```

### GPU mining — CUDA (Nvidia)
```bash
./build/veilminer/veilminer --cuda -P stratum+tcp://WALLET_ADDRESS@POOL_HOST:PORT
```

### Example (Yada Miners pool)
```bash
./build/veilminer/veilminer --cpu -P stratum+tcp://YOUR_VEIL_ADDRESS@veil.yadaminers.pl:3334
```

### List available devices
```bash
./build/veilminer/veilminer --help
```

---

## Notes

- **DAG size**: At epoch 218 (block ~3.9M) the DAG is ~4.55 GB. You need at least 6 GB of RAM for comfortable CPU mining. On Apple Silicon the unified memory is shared with the OS so 8 GB systems will be tight — 16 GB+ recommended.
- **Apple Silicon thread affinity**: macOS does not expose hard CPU affinity on ARM. The miner uses scheduling hints instead; this is normal and expected.
- **DAG epoch parameters**: This miner uses Veil's correct epoch length (5525 blocks before block 2,100,000; 8175 blocks after). The DAG resets to epoch 0 at block 2,100,000 and then grows more slowly (~750 MB/year).
- **Hashrate**: On an M1 Mac mini (8-core) expect ~1.7–1.8 Kh/s total across all cores.
