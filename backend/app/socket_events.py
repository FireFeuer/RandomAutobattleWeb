from flask import request
from flask_socketio import emit, join_room
import uuid
from . import socketio
from .game.manager import game_manager

@socketio.on('connect')
def on_connect():
    print('Client connected', request.sid)

@socketio.on('create_lobby')
def create_lobby(data):
    player_name = data['name']
    match_id = str(uuid.uuid4())[:6].upper()
    
    match = game_manager.create_match(match_id, player_name, request.sid, socketio)
    join_room(match_id)
    
    emit('lobby_created', {'match_id': match_id, 'players': [player_name]})

@socketio.on('join_lobby')
def join_lobby(data):
    match_id = data['match_id'].upper()
    player_name = data['name']
    
    match = game_manager.get_match(match_id)
    if match and not match.is_full():
        # Импорт внутри метода во избежание циклических зависимостей, если нужно
        from .game.player import Player 
        p2 = Player(player_name, sid=request.sid)
        match.add_player(p2)
        join_room(match_id)

        emit('lobby_joined', {'match_id': match_id, 'players': match.get_player_names()}, to=request.sid)

@socketio.on('player_ready')
def player_ready(data):
    match_id = data['match_id']
    match = game_manager.get_match(match_id)
    if match:
        match.ready_players.add(request.sid)
        print(f"Player ready: {request.sid}, total: {len(match.ready_players)}")
        if len(match.ready_players) == 2:
            match.start_game()

@socketio.on('choose_perk')
def choose_perk(data):
    match_id = data['match_id']
    perk_id = data['perk_id']
    match = game_manager.get_match(match_id)
    if match:
        match.apply_perk(request.sid, perk_id)

@socketio.on('disconnect')
def on_disconnect():
    sid = request.sid
    removed_matches = game_manager.remove_player_matches(sid)
    
    for match in removed_matches:
        # Уведомляем оппонента
        opponent_sid = None
        if match.p1 and match.p1.sid != sid:
            opponent_sid = match.p1.sid
        elif match.p2 and match.p2.sid != sid:
            opponent_sid = match.p2.sid
            
        if opponent_sid:
            emit('opponent_disconnected', {}, room=opponent_sid)