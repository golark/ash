# Runtime hook for llama_cpp
import os
import sys

# Add the directory containing the llama library to the library path
if getattr(sys, 'frozen', False):
    # Running as PyInstaller executable
    base_path = sys._MEIPASS
    lib_path = os.path.join(base_path, 'llama_cpp')
    if os.path.exists(lib_path):
        os.environ['LD_LIBRARY_PATH'] = lib_path + os.pathsep + os.environ.get('LD_LIBRARY_PATH', '')
        os.environ['DYLD_LIBRARY_PATH'] = lib_path + os.pathsep + os.environ.get('DYLD_LIBRARY_PATH', '') 