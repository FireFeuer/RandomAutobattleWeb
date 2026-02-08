import time
from .abilities import Ability

class Player:
    def __init__(self, name, sid):
        self.name = name
        self.sid = sid
        self.hp = 1000
        self.max_hp = 1000
        self.perks = []
        # Выбор перка в текущем раунде
        self.round_choice = None
        
        # Настройка способностей (можно вынести в конфиг в будущем)
        self.abilities = [
            Ability("Quick", 10, 20, 0.2, 0.5),
            Ability("Heavy", 30, 50, 0.8, 1.2),
            Ability("Heal", 5, 15, 0.5, 1.0, is_heal=True),
        ]
        
        # Runtime stats (сбрасываются каждый раунд)
        self.shield = 0
        self.poison_stacks = 0

    def reset_round_state(self):
        self.hp = self.max_hp
        self.shield = 200 if "barrier" in self.perks else 0
        self.poison_stacks = 0
        speed_mod = 1.3 if "swiftness" in self.perks else 1.0
        
        current_time = time.time()
        for a in self.abilities:
            a.next_tick = current_time + a.get_delay(speed_mod)
    
    def to_dict(self):
        return {
            "name": self.name, 
            "hp": int(self.hp), 
            "shield": int(self.shield), 
            "max_hp": self.max_hp
        }