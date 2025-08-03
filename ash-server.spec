# -*- mode: python ; coding: utf-8 -*-

import os
import sys
from PyInstaller.utils.hooks import collect_dynamic_libs, collect_data_files

# Get the directory where this spec file is located
spec_dir = os.getcwd()

# Collect llama-cpp-python dynamic libraries and data files
llama_libs = collect_dynamic_libs('llama_cpp')
llama_data = collect_data_files('llama_cpp')

block_cipher = None

# Check if model file exists
model_path = os.path.join(spec_dir, 'models', 'qwen2.5-coder-3b-instruct-q4_k_m.gguf')
cli_tools_path = os.path.join(spec_dir, 'ash', 'cli_tools_kb.json')

datas = []
if os.path.exists(cli_tools_path):
    datas.append(('ash/cli_tools_kb.json', 'ash'))
if os.path.exists(model_path):
    datas.append(('models/qwen2.5-coder-3b-instruct-q4_k_m.gguf', 'models'))

a = Analysis(
    ['ash/server.py'],
    pathex=[spec_dir],
    binaries=llama_libs,
    datas=datas + llama_data,
    hiddenimports=[
        'llama_cpp',
        'llama_cpp.llama_cpp',
        'llama_cpp.llama_types',
        'llama_cpp.llama_grammar',
        'llama_cpp.llama_chat_format',
        'llama_cpp.llama',
        'llama_cpp.llama_cpp.llama_cpp',
    ],
    hookspath=['hooks'],
    hooksconfig={},
    runtime_hooks=['ash/hooks/runtime_hook_llama.py'],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='ash-server',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='ash-server',
)
