from datetime import datetime
from enum import Enum

class ActivationType(Enum):
    ATTACK = "attack"
    HEAL = "heal"
    CRIT = "crit"
    POISON_APPLY = "poison_apply"
    POISON_TICK = "poison_tick"
    SHIELD = "shield"
    REFLECT = "reflect"
    LIFESTEAL = "lifesteal"
    STUN = "stun"

class ActivationEvent:
    def __init__(self, player_sid, player_name, ability_name, ability_rarity_color=None, 
                 value=0, is_heal=False, is_crit=False, effect_type=None, activation_type=None):
        self.player_sid = player_sid
        self.player_name = player_name
        self.ability_name = ability_name
        self.ability_rarity_color = ability_rarity_color
        self.value = value
        self.is_heal = is_heal
        self.is_crit = is_crit
        self.effect_type = effect_type
        self.activation_type = activation_type

    def to_dict(self):
        # Вспомогательная функция для превращения Enum в строку
        def serialize(obj):
            if isinstance(obj, Enum):
                return obj.value
            return obj

        return {
            "player_sid": self.player_sid,
            "player_name": self.player_name,
            "ability_name": self.ability_name,
            "ability_rarity_color": self.ability_rarity_color,
            "value": self.value,
            "is_heal": self.is_heal,
            "is_crit": self.is_crit,
            # Обязательно пропускаем через serialize
            "effect_type": serialize(self.effect_type),
            "activation_type": serialize(self.activation_type)
        }