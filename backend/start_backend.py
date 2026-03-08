import uvicorn
import sys
import os

if __name__ == "__main__":
    # Ensure the current directory is in the path
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.append(current_dir)
    
    print(f"Starting server from: {current_dir}")
    print(f"Python path: {sys.path}")
    
    try:
        import main
        print("Successfully imported main.py")
    except ImportError as e:
        print(f"Failed to import main.py: {e}")
        sys.exit(1)

    uvicorn.run("main:app", host="127.0.0.1", port=8080, reload=False)
