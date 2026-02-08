import eventlet
eventlet.monkey_patch()
from flask import Flask, request
from flask_socketio import SocketIO, emit, join_room, leave_room
import uuid, time, random
from game_logic import Match, Player
import threading

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

matches = {}          # match_id -> Match
players = {}          # sid -> player_name

@socketio.on('connect')
def on_connect():
    print('Client connected', request.sid)

@socketio.on('create_lobby')
def create_lobby(data):
    player_name = data['name']
    match_id = str(uuid.uuid4())[:6].upper()
    p1 = Player(player_name, sid=request.sid)
    match = Match(match_id, p1, socketio)  # передаем socketio в конструктор
    matches[match_id] = match
    join_room(match_id)
    emit('lobby_created', {'match_id': match_id, 'players': [player_name]})

@socketio.on('join_lobby')
def join_lobby(data):
    match_id = data['match_id'].upper()
    player_name = data['name']
    if match_id in matches and not matches[match_id].is_full():
        p2 = Player(player_name, sid=request.sid)
        match = matches[match_id]
        match.add_player(p2)
        join_room(match_id)

        # Только гостю (чтобы хост не получил lobby_joined и не создал второй GameScreen)
        emit('lobby_joined', {'match_id': match_id, 'players': match.get_player_names()}, to=request.sid)

        # НЕ запускаем игру сразу! Ждём, пока оба экрана GameScreen скажут "ready"
        # match.start_game()  ← закомментируй или удали эту строку

@socketio.on('player_ready')
def player_ready(data):
    match_id = data['match_id']
    match = matches.get(match_id)
    if match:
        match.ready_players.add(request.sid)          # ← добавь это поле в класс Match ниже
        print(f"Player ready: {request.sid}, total ready: {len(match.ready_players)}")
        if len(match.ready_players) == 2:
            print("Both players ready → starting game")
            match.start_game()

@socketio.on('choose_perk')
def choose_perk(data):
    match_id = data['match_id']
    perk_id = data['perk_id']
    match = matches.get(match_id)
    if match:
        match.apply_perk(request.sid, perk_id)

@socketio.on('disconnect')
def on_disconnect():
    # Удаляем игрока из всех матчей при отключении
    sid = request.sid
    matches_to_remove = []
    for match_id, match in matches.items():
        if match.p1 and match.p1.sid == sid:
            matches_to_remove.append(match_id)
        elif match.p2 and match.p2.sid == sid:
            matches_to_remove.append(match_id)
    
    for match_id in matches_to_remove:
        if match_id in matches:
            # Уведомляем другого игрока
            match = matches[match_id]
            if match.p1 and match.p1.sid != sid:
                emit('opponent_disconnected', {}, room=match.p1.sid)
            elif match.p2 and match.p2.sid != sid:
                emit('opponent_disconnected', {}, room=match.p2.sid)
            del matches[match_id]

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)