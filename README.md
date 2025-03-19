# openai_nicegui_chat

## Deveopment Setup
```
python_version=$(python3 --version | awk '{print $2}')
uv venv --env-file .env --python $python_version
uv sync  
```