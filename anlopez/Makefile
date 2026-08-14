VENV_NAME    ?= venv          # Name for venv folder or conda environment
USE_CONDA    ?=               # Set to any value (e.g., 1) to use conda instead of venv
CONDA_PYTHON ?= python       # Python version for conda environment

update_dependencies:
	@echo "Updating dependencies..."
	pip install pip-tools
	pip-compile --output-file requirements.txt requirements.in
	pip install -r requirements.txt
	@echo "Dependencies updated successfully."

install_dvc:
	@echo "Installing DVC..."
	pip install dvc
	@echo "DVC installed successfully."

VENV_NAME   ?= venv          # Folder name for local venv or conda env
USE_CONDA   ?=               # Set to any value (e.g., 1) to use conda instead of venv
CONDA_PYTHON ?= python       # Python version for conda environment

create_python_env:
	@if [ -n "$(USE_CONDA)" ]; then \
		echo "Creating conda environment in './$(VENV_NAME)'..."; \
		conda create --prefix ./$(VENV_NAME) $(CONDA_PYTHON) -y; \
		echo "Conda environment created successfully at ./$(VENV_NAME)."; \
	else \
		echo "Creating Python virtual environment in './$(VENV_NAME)'..."; \
		python -m venv $(VENV_NAME); \
		echo "Python virtual environment created successfully."; \
	fi

activate:
	@if [ -n "$(USE_CONDA)" ]; then \
		echo "To activate the conda environment: conda activate ./$(VENV_NAME)"; \
	else \
		echo "To activate the virtual environment: source $(VENV_NAME)/bin/activate"; \
	fi