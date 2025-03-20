#!/usr/bin/env python3
import frontend
from fastapi import FastAPI

app = FastAPI()

@app.get('/health')
def read_root():
    return {'status': 'ok'}

frontend.init(app)

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app)