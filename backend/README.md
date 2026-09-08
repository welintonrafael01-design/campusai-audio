# StudyBook AI Backend

## Local Python Environment

Create the virtual environment locally; generated dependencies are intentionally
not tracked by Git.

```bash
cd /path/to/campusai-audio
python3 -m venv backend/.venv
source backend/.venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r backend/requirements.txt
```

Run the backend test suite from the repository root:

```bash
PYTHONPATH=backend backend/.venv/bin/python -m pytest backend/tests
```

Local environment files and credentials must remain outside Git.
