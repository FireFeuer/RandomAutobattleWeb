import random
import time
from enum import Enum

class Rarity(Enum):
    COMMON = "common"
    RARE = "rare"
    EPIC = "epic"
    LEGENDARY = "legendary"

class Ability:
    def __init__(self, name, name_ru, description, rarity, 
                 min_dmg, max_dmg, min_delay, max_delay, 
                 is_heal=False, stackable=True, special_properties=None):
        self.name = name  # английский ID для кода
        self.name_ru = name_ru  # русское название для отображения
        self.description = description
        self.rarity = rarity
        self.min_dmg = min_dmg
        self.max_dmg = max_dmg
        self.base_min_delay = min_delay
        self.base_max_delay = max_delay
        self.is_heal = is_heal
        self.stackable = stackable  # можно ли брать повторно
        self.special_properties = special_properties or {}
        self.next_tick = 0
        self.stack_count = 1  # количество стеков (для усиления)

    def get_delay(self, speed_modifier=1.0):
        mn = self.base_min_delay / speed_modifier
        mx = self.base_max_delay / speed_modifier
        return random.uniform(mn, mx)

    def activate(self, speed_modifier=1.0, stack_multiplier=1.0):
        """Возвращает (урон/хил, новая_задержка) с учётом множителя от стеков"""
        val = random.randint(self.min_dmg, self.max_dmg)
        
        # Применяем множитель от стеков
        if self.stackable:
            val = int(val * stack_multiplier)
        
        new_delay = self.get_delay(speed_modifier)
        return val, new_delay

    def get_rarity_color(self):
        """Возвращает цвет полоски для редкости"""
        colors = {
            Rarity.COMMON: "#9E9E9E",  # gridLine
            Rarity.RARE: "#72c144",
            Rarity.EPIC: "#77136f",
            Rarity.LEGENDARY: "#d2b61e"
        }
        return colors.get(self.rarity, "#9E9E9E")
    

    
    def get_stats_text_with_stacks(self, stacks=1):
        """Возвращает текст с характеристиками с учетом количества стеков"""
        stats = []
        
        # Базовый урон/лечение с множителем от стеков
        stack_multiplier = 1.0
        if stacks > 1 and self.stackable:
            stack_multiplier = 1.0 + (stacks - 1) * 0.2
        
        min_dmg_with_stacks = int(self.min_dmg * stack_multiplier)
        max_dmg_with_stacks = int(self.max_dmg * stack_multiplier)
        
        if self.is_heal:
            stats.append(f"Лечение: {min_dmg_with_stacks}-{max_dmg_with_stacks}")
        else:
            stats.append(f"Урон: {min_dmg_with_stacks}-{max_dmg_with_stacks}")
        
        # Скорость (может меняться от Swiftness)
        stats.append(f"Скорость: {self.base_min_delay:.1f}-{self.base_max_delay:.1f} сек")
        
        # Специальные свойства с учетом стеков
        for key, value in self.special_properties.items():
            if key == "crit_chance":
                crit_chance = value + (stacks - 1) * 0.05 if stacks > 1 else value
                stats.append(f"Крит: {int(crit_chance*100)}%")
            elif key == "lifesteal":
                lifesteal = value + (stacks - 1) * 0.1 if stacks > 1 else value
                stats.append(f"Вампиризм: {int(lifesteal*100)}%")
            elif key == "poison_chance":
                poison_chance = value + (stacks - 1) * 0.1 if stacks > 1 else value
                stats.append(f"Яд: {int(poison_chance*100)}%")
            elif key == "reflect":
                reflect = value + (stacks - 1) * 0.05 if stacks > 1 else value
                stats.append(f"Отражение: {int(reflect*100)}%")
            elif key == "speed_boost":
                speed_boost = value + (stacks - 1) * 0.3 if stacks > 1 else value
                stats.append(f"Бонус скорости: x{speed_boost:.1f}")
        
        if self.stackable:
            stats.append(f"Усиление: +20% за уровень (текущий x{stack_multiplier:.1f})")
        
        return "\n".join(stats)

    def get_stats_text(self):
        """Возвращает текст с характеристиками"""
        stats = []
        if self.is_heal:
            stats.append(f"Лечение: {self.min_dmg}-{self.max_dmg}")
        else:
            stats.append(f"Урон: {self.min_dmg}-{self.max_dmg}")
        
        stats.append(f"Скорость: {self.base_min_delay:.1f}-{self.base_max_delay:.1f} сек")
        
        # Добавляем специальные свойства
        for key, value in self.special_properties.items():
            if key == "crit_chance":
                stats.append(f"Крит: {int(value*100)}%")
            elif key == "lifesteal":
                stats.append(f"Вампиризм: {int(value*100)}%")
            elif key == "poison_chance":
                stats.append(f"Яд: {int(value*100)}%")
            elif key == "reflect":
                stats.append(f"Отражение: {int(value*100)}%")
        
        if self.stackable:
            stats.append("Усил при повторном выборе")
        
        return "\n".join(stats)


# Предопределенные способности
ABILITIES = {
    "crit": Ability(
        name="crit",
        name_ru="Критический удар",
        description="Шанс нанести двойной урон",
        rarity=Rarity.RARE,
        min_dmg=5, max_dmg=10,
        min_delay=0.8, max_delay=1.5,  # Было 1.0-1.8
        stackable=True,
        special_properties={"crit_chance": 0.25}
    ),
    "barrier": Ability(
        name="barrier",
        name_ru="Барьер",
        description="Поглощает урон щитом",
        rarity=Rarity.COMMON,
        min_dmg=10, max_dmg=20,
        min_delay=1.5, max_delay=2.8,  # Было 2.0-3.5
        is_heal=False,
        stackable=True,
        special_properties={"shield_gain": True}
    ),
    "venom": Ability(
        name="venom",
        name_ru="Яд",
        description="Отравляет противника, нанося периодический урон",
        rarity=Rarity.RARE,
        min_dmg=3, max_dmg=6,
        min_delay=0.6, max_delay=1.2,  # Было 0.8-1.5
        stackable=True,
        special_properties={"poison_chance": 0.3, "poison_damage": 0.1}
    ),
    "bloodlust": Ability(
        name="bloodlust",
        name_ru="Кровавая жажда",
        description="Восстанавливает здоровье от нанесенного урона",
        rarity=Rarity.EPIC,
        min_dmg=8, max_dmg=15,
        min_delay=1.2, max_delay=2.0,  # Было 1.5-2.5
        stackable=True,
        special_properties={"lifesteal": 0.5}
    ),
    "swiftness": Ability(
        name="swiftness",
        name_ru="Скорость",
        description="Увеличивает скорость атак",
        rarity=Rarity.RARE,
        min_dmg=2, max_dmg=5,
        min_delay=0.4, max_delay=1.0,  # Было 0.6-1.2
        stackable=False,
        special_properties={"speed_boost": 2.0}  # Увеличили бонус скорости с 1.5 до 2.0
    ),
    "soulbind": Ability(
        name="soulbind",
        name_ru="Связь душ",
        description="Отражает часть полученного урона",
        rarity=Rarity.EPIC,
        min_dmg=4, max_dmg=8,
        min_delay=1.5, max_delay=2.5,  # Было 1.8-3.0
        stackable=True,
        special_properties={"reflect": 0.2}
    ),
    "healing_light": Ability(
        name="healing_light",
        name_ru="Свет исцеления",
        description="Мощное лечение",
        rarity=Rarity.COMMON,
        min_dmg=15, max_dmg=25,
        min_delay=2.5, max_delay=3.8,  # Было 3.0-4.5
        is_heal=True,
        stackable=True
    ),
    "divine_shield": Ability(
        name="divine_shield",
        name_ru="Божественный щит",
        description="Мощный щит, поглощающий урон",
        rarity=Rarity.LEGENDARY,
        min_dmg=25, max_dmg=40,
        min_delay=3.0, max_delay=4.5,  # Было 3.5-5.0
        is_heal=False,
        stackable=True,
        special_properties={"divine_protection": True}
    ),
    "chain_lightning": Ability(
        name="chain_lightning",
        name_ru="Цепная молния",
        description="Наносит урон и оглушает",
        rarity=Rarity.LEGENDARY,
        min_dmg=15, max_dmg=30,
        min_delay=1.5, max_delay=3.0,  # Было 2.0-3.5
        stackable=False,
        special_properties={"stun_chance": 0.2}
    )
}

def get_ability_by_id(ability_id):
    """Получить способность по ID"""
    return ABILITIES.get(ability_id)

def get_random_perks(count=5):
    """Получить случайный набор способностей с учётом stackable"""
    all_abilities = list(ABILITIES.values())
    # Учитываем stackable при выборе
    return random.sample([(a.name, a) for a in all_abilities], count)

def get_ability_description(self):
    """Возвращает полное описание способности"""
    desc = self.description
    if self.is_heal:
        desc += f" Лечит от {self.min_dmg} до {self.max_dmg} HP."
    else:
        desc += f" Наносит от {self.min_dmg} до {self.max_dmg} урона."
    return desc