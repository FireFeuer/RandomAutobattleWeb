import eventlet
eventlet.monkey_patch()

from app import create_app, socketio

app = create_app()

if __name__ == '__main__':
    print("🚀 Server starting on http://0.0.0.0:5000")
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)