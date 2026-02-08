import random
import time

class Ability:
    def __init__(self, name, min_dmg, max_dmg, min_delay, max_delay, is_heal=False):
        self.name = name
        self.min_dmg = min_dmg
        self.max_dmg = max_dmg
        self.base_min_delay = min_delay
        self.base_max_delay = max_delay
        self.is_heal = is_heal
        self.next_tick = 0

    def get_delay(self, speed_modifier=1.0):
        mn = self.base_min_delay / speed_modifier
        mx = self.base_max_delay / speed_modifier
        return random.uniform(mn, mx)

    def activate(self, speed_modifier=1.0):
        """Возвращает (урон/хил, новая_задержка)"""
        val = random.randint(self.min_dmg, self.max_dmg)
        new_delay = self.get_delay(speed_modifier)
        return val, new_delay