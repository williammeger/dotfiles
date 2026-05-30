# Creative LLM Integrations

## Overview

Local LLM integrations for creative workflows — shader development, game engines,
3D tools, VJing, and music production. Separated from the core bootstrap plan to
keep system setup distinct from creative tooling.

**Prerequisites:** Complete the [windows-setup.md](windows-setup.md) bootstrap first.
Ollama and LM Studio should be installed and working before configuring these integrations.

---

## 1 — Blender MCP (Model Context Protocol)

### 1.1 What This Does

Connects Blender to your local LLM via MCP, enabling natural-language control of
Blender operations: generating geometry, writing shader nodes, automating repetitive
tasks, and explaining scene setups — all offline.

### 1.2 Requirements

| Component | Minimum | Notes |
|---|---|---|
| Blender | 4.1+ | MCP add-on requires modern Python API |
| Ollama | Running locally | `ollama serve` or LM Studio as backend |
| RAM free | ~8–20 GB | On top of Blender's own usage |
| Recommended model | `qwen2.5-coder:32b` | Best for code generation tasks in Blender |

### 1.3 Install Blender

```powershell
# Native Windows install
winget install BlenderFoundation.Blender

# Verify
blender --version
```

### 1.4 Install Blender MCP Add-on

```powershell
# Clone the MCP server
git clone https://github.com/ahujasid/blender-mcp.git C:\Tools\blender-mcp
cd C:\Tools\blender-mcp

# Install Python dependencies (uses Blender's bundled Python)
& "C:\Program Files\Blender Foundation\Blender 4.1\4.1\python\bin\python.exe" -m pip install -r requirements.txt
```

### 1.5 Configure MCP Server

Create or edit the MCP config (e.g. for Claude Desktop, Cursor, or any MCP client):

```json
{
  "mcpServers": {
    "blender": {
      "command": "python",
      "args": ["C:\\Tools\\blender-mcp\\server.py"],
      "env": {
        "OLLAMA_HOST": "http://localhost:11434",
        "OLLAMA_MODEL": "qwen2.5-coder:32b"
      }
    }
  }
}
```

### 1.6 Enable in Blender

1. Edit → Preferences → Add-ons → Install from Disk
2. Navigate to `C:\Tools\blender-mcp\addon\` and select the `.py` file
3. Enable the add-on (check the box)
4. In the 3D Viewport sidebar (N panel), find the MCP tab
5. Click "Connect" — status should show connected to local Ollama

### 1.7 Usage Examples

```
"Create a low-poly mountain landscape with 5 peaks"
"Write a shader node group that creates a procedural wood texture"
"Explain what this geometry nodes setup does"
"Add a particle system that emits from the selected mesh vertices"
```

### 1.8 Memory Budget (Blender + LLM)

| Scenario | Blender | Model | Total | Feasible on |
|---|---|---|---|---|
| Simple scene + 7B | ~4 GB | ~5 GB | ~9 GB | 64 GB laptop ✓ |
| Heavy scene + 32B | ~12 GB | ~20 GB | ~32 GB | 64 GB laptop (tight) |
| Heavy scene + 32B | ~12 GB | ~20 GB | ~32 GB | 128 GB desktop ✓ |
| Production scene + 70B | ~20 GB | ~40 GB | ~60 GB | 128 GB desktop ✓ |

> **Tip:** Set `OLLAMA_KEEP_ALIVE=10m` when using with Blender. The model unloads
> quickly after you stop chatting, freeing RAM for renders.

---

## 2 — Shader / Game / 3D Toolchain

All of these run native Windows. Installed by `bootstrap/windows.ps1`.

### 2.1 Graphics APIs & SDKs

| Tool | Install | Purpose |
|---|---|---|
| Vulkan SDK | `winget install KhronosGroup.VulkanSDK` | `glslc`, `glslangValidator`, `spirv-cross`, validation layers |
| Windows SDK | Ships with VS Build Tools | `dxc.exe` (HLSL shader compiler), PIX hooks |
| RenderDoc | `winget install BaldurKarlsson.RenderDoc` | GPU frame capture, shader debugging |
| Slang | `winget install ShaderSlang.Slang` | Write once → HLSL/GLSL/SPIR-V/Metal/CUDA |
| NSight Graphics | Manual download (nvidia.com) | NVIDIA shader debugger + GPU profiler |

### 2.2 Shader Dev Workflow (WSL2 CLI)

```bash
# Compile GLSL → SPIR-V
glslangValidator -V shader.vert -o vert.spv
glslangValidator -V shader.frag -o frag.spv

# Inspect SPIR-V
spirv-dis vert.spv

# Cross-compile SPIR-V → HLSL (for DX12 targets)
spirv-cross vert.spv --hlsl --output vert.hlsl

# Ask LLM to explain or fix shader code
cat shader.frag | codex "This GLSL fragment shader has a compile error. Diagnose and fix it."
```

### 2.3 VS Code Shader Extensions

```powershell
code --install-extension slevesque.shader
code --install-extension raczzalan.glsl-linter
code --install-extension TimJones.hlsl-preview
code --install-extension shader-slang.slang-vscode-extension
```

### 2.4 Game Engines

| Engine | Install | Notes |
|---|---|---|
| Unreal Engine 5 | Epic Games Launcher | 128 GB handles shader compilation well |

### 2.5 3D & Asset Tools

| Tool | Install | Notes |
|---|---|---|
| Houdini | sidefx.com (apprentice free) | Procedural 3D, VFX, large VDB sims |
| Git LFS | `scoop install git-lfs` | Required for binary assets (textures, meshes) |

### 2.6 C++ Build System (Custom Engines)

```powershell
# VS Build Tools (installs MSVC compiler)
winget install Microsoft.VisualStudio.2022.BuildTools

# vcpkg (C++ package manager)
git clone https://github.com/microsoft/vcpkg C:\vcpkg
C:\vcpkg\bootstrap-vcpkg.bat
[Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")

# Common graphics libs
cd C:\vcpkg
.\vcpkg install glfw3 glm imgui vulkan-headers spirv-cross shaderc
```

---

## 3 — VJing & Real-Time Visual Performance

### 3.1 Relevant Tools

| Tool | Purpose | LLM Integration |
|---|---|---|
| TouchDesigner | Node-based real-time visuals | Python scripting — LLM can generate TOPs/CHOPs/SOPs |
| Resolume Arena | Live VJ mixing & mapping | GLSL shader effects (LLM can write custom shaders) |
| VDMX | macOS real-time video | Quartz Composer / ISF shaders |
| Notch | Real-time 3D for live events | Node graphs, HLSL compute |

### 3.2 LLM-Assisted Shader Writing for VJing

```bash
# Generate a Resolume FFGL shader via local LLM
ollama run qwen2.5-coder:32b "Write a GLSL fragment shader for Resolume that creates
a reactive audio-visualizer effect. Input uniforms: iResolution, iTime, iAudioFFT[256]."

# Generate a TouchDesigner GLSL TOP
ollama run qwen2.5-coder:32b "Write a GLSL shader for a TouchDesigner GLSL TOP that
creates a kaleidoscope effect with 8-fold symmetry. Use standard TD uniforms."
```

### 3.3 Memory Warning

> **Do NOT run LLMs during live VJ performance.** Real-time visuals require
> deterministic frame timing. Any memory pressure from a loaded model can cause
> frame drops. Use LLMs for content creation (before the show), not during.

---

## 4 — Music Production & LLM

### 4.1 Where LLMs Help

| Task | Model | Example Prompt |
|---|---|---|
| Max/MSP patching | `qwen2.5-coder:32b` | "Write a Max patch that granular-synthesizes an audio buffer" |
| SuperCollider | `qwen2.5-coder:32b` | "Write a SynthDef for FM synthesis with 3 operators" |
| Lyrics / concepts | `llama3.1:70b` | Creative writing, brainstorming |
| Audio plugin code (JUCE/C++) | `qwen2.5-coder:32b` | "Write a JUCE AudioProcessor for a stereo delay" |

### 4.2 Memory Warning

> Same rule as VJing: **don't run LLMs while tracking/mixing in your DAW.**
> Ableton/Logic/Reaper with large sessions + plugins can easily consume 16–32 GB.
> Unload models before opening heavy sessions: `ollama stop <model>`

---

## 5 — Model Recommendations for Creative Work

| Use Case | Model | Size | Why |
|---|---|---|---|
| GLSL/HLSL shaders | `qwen2.5-coder:32b` | ~20 GB | Strong at graphics code |
| Blender scripting | `qwen2.5-coder:32b` | ~20 GB | Python + 3D API knowledge |
| General creative ideation | `llama3.1:70b` | ~40 GB | Broader reasoning for concepts |
| Quick shader iteration | `qwen2.5-coder:7b` | ~5 GB | Fast responses, good enough for small fixes |
| Image understanding (ref sheets) | `llava:13b` | ~8 GB | Describe reference images for prompting |
