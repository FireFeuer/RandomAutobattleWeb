import time
from .abilities import get_ability_by_id, Ability

class Player:
    def __init__(self, name, sid):
        self.name = name
        self.sid = sid
        self.hp = 1000
        self.max_hp = 1000
        self.perks = []  # Старая структура для обратной совместимости
        self.abilities_dict = {}  # {ability_id: stack_count}
        # Выбор перка в текущем раунде
        self.round_choice = None
        
        # Инициализация базовых способностей с новой структурой
        self.abilities = []  # Будет заполнено через abilities_dict
        
        # Runtime stats (сбрасываются каждый раунд)
        self.shield = 0
        self.poison_stacks = 0
        self.stun_duration = 0

    def reset_round_state(self):
        """Сброс состояния для нового раунда"""
        self.hp = self.max_hp
        self.poison_stacks = 0
        
        # Базовый щит от барьера
        self.shield = 0
        if "barrier" in self.abilities_dict:
            # Учитываем стеки барьера
            barrier_stacks = self.abilities_dict["barrier"]
            self.shield = 200 + (barrier_stacks - 1) * 50  # Увеличение щита со стеками
        
        # Вычисляем модификатор скорости
        speed_mod = 1.0
        if "swiftness" in self.abilities_dict:
            ability_obj = get_ability_by_id("swiftness")
            if ability_obj:
                speed_mod = ability_obj.special_properties.get("speed_boost", 1.3)
        
        # Сбрасываем таймеры способностей с учётом скорости
        current_time = time.time()
        for ability in self.abilities:
            ability.next_tick = current_time + ability.get_delay(speed_mod)
    
    def add_ability(self, ability_id):
        """Добавление способности игроку с учётом стеков"""
        ability_obj = get_ability_by_id(ability_id)
        if not ability_obj:
            return False
        
        # Проверяем, можно ли добавить способность
        if ability_id in self.abilities_dict:
            if ability_obj.stackable:
                # Увеличиваем стек
                self.abilities_dict[ability_id] += 1
            else:
                # Нельзя взять повторно
                return False  # <-- Это правильно
        else:
            # Добавляем новую способность
            self.abilities_dict[ability_id] = 1
        
        # Обновляем список способностей для боя
        self._update_abilities_list()
        return True
    
    def _update_abilities_list(self):
        """Обновляет список способностей для боя на основе словаря"""
        self.abilities = []
        self.perks = []  # Обновляем и старую структуру для совместимости
        
        for ability_id, stacks in self.abilities_dict.items():
            ability_obj = get_ability_by_id(ability_id)
            if ability_obj:
                # ИСПРАВЛЕНИЕ: Создаём ТОЛЬКО ОДНУ копию способности,
                # но с правильным количеством стеков
                new_ability = Ability(
                    name=ability_obj.name,
                    name_ru=ability_obj.name_ru,
                    description=ability_obj.description,
                    rarity=ability_obj.rarity,
                    min_dmg=ability_obj.min_dmg,
                    max_dmg=ability_obj.max_dmg,
                    min_delay=ability_obj.base_min_delay,
                    max_delay=ability_obj.base_max_delay,
                    is_heal=ability_obj.is_heal,
                    stackable=ability_obj.stackable,
                    special_properties=ability_obj.special_properties.copy() if ability_obj.special_properties else {}
                )
                new_ability.stack_count = stacks  # Сохраняем количество стеков
                self.abilities.append(new_ability)
                
                # Для обратной совместимости добавляем ID в perks (но только один раз)
                self.perks.append(ability_id)
    
    def get_ability_stats(self):
        """Возвращает статистику по способностям для отображения"""
        stats = {}
        for ability_id, stacks in self.abilities_dict.items():
            ability_obj = get_ability_by_id(ability_id)
            if ability_obj:
                stats[ability_id] = {
                    'name_ru': ability_obj.name_ru,
                    'rarity': ability_obj.rarity.value,
                    'stacks': stacks,
                    'stackable': ability_obj.stackable
                }
        return stats
        
    def to_dict(self):
        abilities_list = []
        for ability_id, stacks in self.abilities_dict.items():
            ability_obj = get_ability_by_id(ability_id)
            if ability_obj:
                abilities_list.append({
                    'id': ability_id,
                    'name_ru': ability_obj.name_ru,
                    'description': ability_obj.description,
                    'rarity': ability_obj.rarity.value,
                    'stats': ability_obj.get_stats_text_with_stacks(stacks),
                    'stackable': ability_obj.stackable,
                    'stacks': stacks
                })
        
        return {
            "name": self.name, 
            "hp": int(self.hp), 
            "shield": int(self.shield), 
            "max_hp": self.max_hp,
            "abilities": abilities_list,
            "poison_stacks": int(self.poison_stacks),  # Добавить
            "stun_duration": int(self.stun_duration)    # Добавить
        }