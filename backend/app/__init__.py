from flask import Flask
from flask_socketio import SocketIO

# Создаем экземпляр SocketIO глобально, но не привязываем к app пока
socketio = SocketIO(cors_allowed_origins="*", async_mode='eventlet')

def create_app():
    app = Flask(__name__)
    
    socketio.init_app(app)
    
    # Импортируем события, чтобы они зарегистрировались
    from . import socket_events
    
    return app