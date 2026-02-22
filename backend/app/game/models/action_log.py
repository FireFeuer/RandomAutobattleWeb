from datetime import datetime
from enum import Enum

class ActionType(Enum):
    ATTACK = "attack"
    HEAL = "heal"
    CRIT = "crit"
    POISON_APPLY = "poison_apply"
    POISON_DAMAGE = "poison_damage"
    SHIELD_GAIN = "shield_gain"
    REFLECT = "reflect"
    LIFESTEAL = "lifesteal"

class ActionLog:
    def __init__(self, player_name, ability_name, action_type, value, 
                 target_name=None, is_crit=False, stacks=1, rarity_color="#9E9E9E",
                 min_delay=None, max_delay=None, actual_delay=None,
                 ability_description=None):
        self.player_name = player_name
        self.ability_name = ability_name
        self.action_type = action_type
        self.value = value
        self.target_name = target_name
        self.is_crit = is_crit
        self.stacks = stacks
        self.rarity_color = rarity_color
        self.min_delay = min_delay
        self.max_delay = max_delay
        self.actual_delay = actual_delay
        self.ability_description = ability_description
        self.timestamp = datetime.now()
        
    def to_dict(self):
        return {
            'player_name': self.player_name,
            'ability_name': self.ability_name,
            'action_type': self.action_type.value,
            'value': self.value,
            'target_name': self.target_name,
            'is_crit': self.is_crit,
            'stacks': self.stacks,
            'rarity_color': self.rarity_color,
            'min_delay': self.min_delay,
            'max_delay': self.max_delay,
            'actual_delay': self.actual_delay,
            'ability_description': self.ability_description,
            'timestamp': self.timestamp.strftime("%H:%M:%S")
        }