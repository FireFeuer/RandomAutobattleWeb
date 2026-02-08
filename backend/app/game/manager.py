from .match import Match
from .player import Player

class GameManager:
    def __init__(self):
        self.matches = {}  # match_id -> Match

    def create_match(self, match_id, player_name, sid, socketio):
        p1 = Player(player_name, sid)
        match = Match(match_id, p1, socketio)
        self.matches[match_id] = match
        return match

    def get_match(self, match_id):
        return self.matches.get(match_id)

    def remove_player_matches(self, sid):
        """Находит и удаляет матчи, где участвовал отключившийся игрок"""
        removed_matches = []
        matches_to_remove = []
        
        for match_id, match in self.matches.items():
            if (match.p1 and match.p1.sid == sid) or (match.p2 and match.p2.sid == sid):
                matches_to_remove.append(match_id)
                removed_matches.append(match)
        
        for mid in matches_to_remove:
            del self.matches[mid]
            
        return removed_matches

# Создаем единственный экземпляр менеджера
game_manager = GameManager()