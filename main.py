
import subprocess
import sys
import platform
import os

# Define environment and script names
ENV_NAME = "drugs_info"
PYTHON_SCRIPT = "codes/main_construction.py"
R_SCRIPT = "codes/main_analysis.R"

# Activate the conda environment
if os.system("conda --version") == 0:
    # Check if the environment already exists
    env_name = "drugs_info"  # Replace with your environment name
    if os.system(f"conda env list | findstr {env_name}") != 0:
        os.system("conda env create -f environment.yml")
        print("Conda environment successfully created!")
    else:
        print(f"Conda environment '{env_name}' already exists.")
        os.system("conda activate drugs_info")
else:
    print("Error: Conda is not installed.")


def run_command(command):
    """Run a shell command, ensuring compatibility across OS."""
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        sys.exit(1)


def activate_env():
    """Activate Conda environment in a cross-platform way."""
    system = platform.system()

    if system == "Windows":
        # Windows uses `conda.bat` to activate
        return f"conda activate {ENV_NAME} && "
    else:
        # macOS and Linux use `source` to activate Conda
        return f"source activate {ENV_NAME} && "


def main():
    """Runs Python and R scripts within the Conda environment."""
    print("Activating Conda environment and running scripts...")

    env_command = activate_env()

    # Run Python script
    run_command(f"{env_command} python {PYTHON_SCRIPT}")

    # Run R script
    run_command(f"{env_command} Rscript {R_SCRIPT}")

    print("Execution completed successfully.")


if __name__ == "__main__":
    main()