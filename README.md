# Multimodal Mental Health Framework

An adaptive diagnostic interview system featuring a Flutter-based frontend and a FastAPI (Python) backend. The system uses a Finite State Machine (FSM) to provide an adaptive questioning experience based on clinical severity.

## 🚀 Getting Started

Follow these steps to get the environment up and running.

### 1. Backend Setup (FastAPI)

The backend is responsible for data ingestion, risk flagging, and session storage.

**Prerequisites:** Python 3.8+

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Start the server:
   ```bash
   uvicorn main:app --reload --port 8080
   ```
   *The API will be available at `http://127.0.0.1:8000`. You can view the interactive documentation at `http://127.0.0.1:8000/docs`.*

---

### 2. Frontend Setup (Flutter)

The frontend handles the adaptive interview flow and communicates results to the backend.

**Prerequisites:** Flutter SDK ins`talled and configured.

1. Navigate to the root directory:
   ```bash
   cd ..
   ```
2. Get Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 📂 Project Architecture

### Backend (`/backend`)
- `main.py`: FastAPI server with JSON/CSV storage and high-risk session detection.
- `data/`: Local storage for session records and risk logs.

### Frontend (`/lib`)
- **Engine**: Contains the `ScoringEngine` (clinical logic) and `FSMEngine` (state transitions).
- **State**: Managed via `FsmProvider` (Riverpod) for real-time scoring and UI updates.
- **Data**: `QuestionBank` with 100+ questions and adaptive branching logic.
- **Models**: Type-safe definitions for Sessions, Scores, and Safety Flags.

---

## 🛠️ Performance & Safety Features
- **Adaptive Branching**: Skips irrelevant questions if low severity is detected.
- **Real-time Risk Detection**: Evaluates 13+ safety rules during the interview.
- **Persistent Storage**: Automatically saves data in both JSON and CSV formats on the server.
- **ML Ready**: Generates high-dimensional feature vectors for session analysis.
