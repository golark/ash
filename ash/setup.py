from setuptools import setup, find_packages

setup(
    name="qsh",
    version="0.1.0",
    description="AI-powered shell command suggestion tool",
    author="Your Name",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[],  # Add dependencies if needed
    package_data={
        "": ["zsh/qsh.zsh"],
    },
    entry_points={
        "console_scripts": [
            "qsh-client=qsh.client:main",
            "qsh-server=qsh.server:main",
        ],
    },
) 