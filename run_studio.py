"""One-click launcher for Quarklytics Studio."""
import webbrowser, uvicorn

if __name__ == '__main__':
    print("Launching Quarklytics Studio at http://localhost:8000 ...")
    webbrowser.open("http://localhost:8000")
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=False)
