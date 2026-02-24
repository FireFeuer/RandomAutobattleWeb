import random
import time
from threading import Event
from .abilities import get_ability_by_id, get_random_perks
from .models.action_log import ActionLog, ActionType
from .abilities import get_ability_by_id
import random
from .abilities import ABILITIES, get_ability_by_id, get_random_perks
from .models.activation_event import ActivationEvent, ActivationType
from .abilities import get_ability_by_id, get_random_perks, AbilityType

class Match:
    def __init__(self, match_id, p1, socketio):
        self.match_id = match_id
        self.p1 = p1
        self.p2 = None
        self.socketio = socketio
        self.round_num = 0
        self.wins = {p1.sid: 0}
        self.stop_event = Event()
        self.room = match_id
        self.ready_players = set()
        self.state = "waiting"
        self.action_logs = []  # Новое поле для хранения логов
        self.max_logs = 50      # Максимальное количество логов
        
        self.p1.round_choice = None
        # Инициализируем способности игроков
        self.p1.abilities_dict = {}  # {ability_id: stack_count}

    def add_player(self, p2):
        self.p2 = p2
        self.wins[p2.sid] = 0
        self.p2.round_choice = None
        self.p2.abilities_dict = {}

    def is_full(self):
        return self.p2 is not None

    def get_player_names(self):
        names = [self.p1.name]
        if self.p2:
            names.append(self.p2.name)
        return names

    def start_game(self):
        self.round_num = 1
        self.start_picking_phase()

    def add_action_log(self, log):
        """Добавляет запись в лог и отправляет клиентам"""
        self.action_logs.append(log.to_dict())
        # Ограничиваем размер лога
        if len(self.action_logs) > self.max_logs:
            self.action_logs = self.action_logs[-self.max_logs:]
        
        # Отправляем обновление лога всем в комнате
        self.socketio.emit('action_log_update', {
            'logs': self.action_logs
        }, room=self.room)

    # В методе start_picking_phase класса Match
    def start_picking_phase(self):
        if self.state == "finished":
            print(f"Match {self.match_id}: Cannot start picking phase, match is finished")
            return
            
        self.state = "picking"
        self.p1.round_choice = None
        if self.p2:
            self.p2.round_choice = None
        
        print(f"Match {self.match_id}: Starting picking phase for round {self.round_num}")

        # Формируем счет побед для фронтенда
        wins_with_names = {
            self.p1.name: self.wins.get(self.p1.sid, 0),
            self.p2.name: self.wins.get(self.p2.sid, 0) if self.p2 else 0
        }

        # Отправляем УНИКАЛЬНЫЙ набор перков первому игроку
        self._emit_unique_perk_offer(self.p1, wins_with_names)

        # Отправляем УНИКАЛЬНЫЙ набор перков второму игроку
        if self.p2:
            self._emit_unique_perk_offer(self.p2, wins_with_names)

    def _emit_unique_perk_offer(self, player, wins_with_names):
        """Вспомогательный метод для генерации и отправки уникальных перков одному игроку"""
        
        # 1. Исключаем не-стакающиеся способности, которые игрок УЖЕ взял
        exclude_ids = [aid for aid, stacks in player.abilities_dict.items() 
                    if not get_ability_by_id(aid).stackable]
        
        # 2. Получаем 5 случайных перков из доступных
        perks = get_random_perks(5, exclude_ids=exclude_ids)
        
        # 3. Формируем список способностей в том формате, который ждет фронтенд
        offer = []
        for perk_obj in perks:
            # Сколько стаков этой способности УЖЕ есть у этого игрока
            current_stacks = player.abilities_dict.get(perk_obj.name, 0)
            
            # Получаем словарь способности
            perk_dict = perk_obj.to_dict(current_stacks + 1)
            
            # ЯВНО добавляем/перезаписываем is_heal
            perk_dict['is_heal'] = (perk_obj.ability_type == AbilityType.HEAL)
            
            # Добавляем текущие стаки для отображения
            perk_dict['p1_stacks'] = current_stacks
            perk_dict['p2_stacks'] = 0
            
            offer.append(perk_dict)

        print(f"Match {self.match_id}: Emitting perk_offer with {len(offer)} perks to {player.name}")
        
        # 4. Отправляем событие 'perk_offer' ТОЛЬКО конкретному игроку (room=player.sid)
        self.socketio.emit('perk_offer', {
            'perks': offer,
            'round': self.round_num,
            'wins': wins_with_names
        }, room=player.sid)

    def _get_player_stacks(self, perk_id):
        """Получить текущее количество стеков способности у игроков"""
        stacks = {}
        if self.p1 and perk_id in self.p1.abilities_dict:
            stacks[self.p1.sid] = self.p1.abilities_dict[perk_id]
        if self.p2 and perk_id in self.p2.abilities_dict:
            stacks[self.p2.sid] = self.p2.abilities_dict[perk_id]
        return stacks
    
    def add_activation_event(self, event):
        """Отправляет событие активации конкретному игроку"""
        print(f"📢 Sending activation event: {event.to_dict()}")  # Отладка
        # Отправляем всем в комнате, чтобы оба видели анимации
        self.socketio.emit('ability_activation', event.to_dict(), room=self.room)

    def apply_perk(self, sid, perk_id):
        player = self.p1 if sid == self.p1.sid else self.p2
        if not player:
            print(f"DEBUG: Player with sid {sid} not found in match {self.match_id}")
            return

        # Записываем выбор
        player.round_choice = perk_id
        player.abilities_dict[perk_id] = player.abilities_dict.get(perk_id, 0) + 1
        
        print(f"DEBUG: Match {self.match_id} - {player.name} chose {perk_id}. Total stacks: {player.abilities_dict[perk_id]}")

        # Проверяем, сделали ли выбор оба
        if self.p1.round_choice and (self.p2 and self.p2.round_choice):
            print(f"DEBUG: Match {self.match_id} - Both players chosen. Processing...")
            
            # Сбрасываем флаги выбора
            self.p1.round_choice = None
            self.p2.round_choice = None

            total_perks = sum(self.p1.abilities_dict.values())
            
            if total_perks < 3:
                print(f"DEBUG: Match {self.match_id} - Starting next picking phase ({total_perks}/3)")
                self.start_picking_phase()
            else:
                print(f"DEBUG: Match {self.match_id} - All perks chosen. TRANSITION TO PLAYING")
                self.state = "playing"
                
                # ВАЖНО: Перед началом цикла сбрасываем HP и щиты для боя
                self.p1.reset_round_state()
                self.p2.reset_round_state()
                
                # Отправляем финальное состояние перед боем, чтобы способности появились в UI
                self.broadcast_state() 
                
                # Запускаем цикл боя
                self.socketio.start_background_task(self.game_loop)

    def broadcast_state(self):
        """Отправляет текущие данные обо всех игроках в комнату матча"""
        data = {
            'p1': self.p1.to_dict(),
            'p2': self.p2.to_dict() if self.p2 else None,
            'round': self.round_num,
            'state': self.state,
            'logs': [log.to_dict() for log in self.action_logs[-10:]] # последние 10 логов
        }
        self.socketio.emit('state_update', data, room=self.room)
    
    def send_perks_to_player(self, player):
        """Генерирует и отправляет уникальный набор перков игроку"""
        # Исключаем не стакающиеся способности, которые уже есть
        exclude_ids = [aid for aid, stacks in player.abilities_dict.items() 
                       if not get_ability_by_id(aid).stackable]
        
        perks = get_random_perks(5, exclude_ids=exclude_ids)
        
        # Используем метод to_dict() самого объекта Ability
        perks_data = [p.to_dict(player.abilities_dict.get(p.name, 0) + 1) for p in perks]
        
        print(f"Match {self.match_id}: Sending {len(perks_data)} perks to {player.name}")
        self.socketio.emit('show_perks', {'perks': perks_data}, room=player.sid)

    def _update_player_abilities(self, player):
        """Обновляет список способностей игрока на основе словаря"""
        player.abilities = []
        for ability_id, stacks in player.abilities_dict.items():
            ability_obj = get_ability_by_id(ability_id)
            if ability_obj:
                # Создаем копию способности с текущим стеком
                for _ in range(stacks):
                    player.abilities.append(ability_obj)

    def start_combat_phase(self):
        self.state = "fighting"
        self.p1.reset_round_state()
        self.p2.reset_round_state()
        self.stop_event.clear()
        
        self.socketio.emit('round_start', {}, room=self.room)
        self.socketio.start_background_task(self.game_loop)

    def game_loop(self):
        print(f"DEBUG: !!! BATTLE LOOP STARTED for match {self.match_id} !!!")
        
        self.p1.update_abilities_from_dict()
        self.p2.update_abilities_from_dict()
        
        print(f"DEBUG: P1 abilities count: {len(self.p1.abilities)}")
        print(f"DEBUG: P2 abilities count: {len(self.p2.abilities)}")

        last_stun_update = time.time()
        last_time = time.time()
        
        try:
            while self.state == "playing" and not self.stop_event.is_set():
                current_time = time.time()
                
                # Обновляем длительность стана для обоих игроков
                delta_time = current_time - last_stun_update
                self.p1.update_stun(delta_time)
                self.p2.update_stun(delta_time)
                last_stun_update = current_time
                last_time = current_time
                
                # Логика способностей P1
                if not self.p1.is_stunned():  # Проверяем стан
                    for ability in self.p1.abilities:
                        if current_time >= ability.next_tick:
                            print(f"DEBUG: {self.p1.name} activating {ability.name}")
                            ability.activate(self.p1, self.p2, self) 
                            ability.next_tick = current_time + ability.get_delay()
                else:
                    print(f"DEBUG: {self.p1.name} is stunned, cannot act")

                # Логика способностей P2
                if not self.p2.is_stunned():  # Проверяем стан
                    for ability in self.p2.abilities:
                        if current_time >= ability.next_tick:
                            print(f"DEBUG: {self.p2.name} activating {ability.name}")
                            ability.activate(self.p2, self.p1, self)
                            ability.next_tick = current_time + ability.get_delay()
                else:
                    print(f"DEBUG: {self.p2.name} is stunned, cannot act")

                self.broadcast_state()

                if self.p1.hp <= 0 or self.p2.hp <= 0:
                    self.resolve_round_winner()
                    break

                self.socketio.sleep(0.1)
                
        except Exception as e:
            import traceback
            print(f"CRITICAL ERROR in game_loop: {e}")
            traceback.print_exc()

    def resolve_round_winner(self):
        """Определяет победителя раунда и проверяет окончание игры"""
        winner_sid = None
        game_winner = None

        if self.p1.hp <= 0 and self.p2.hp <= 0:
            # Ничья (редко, но бывает)
            print(f"Match {self.match_id}: Round DRAW!")
        elif self.p1.hp <= 0:
            winner_sid = self.p2.sid
            self.wins[self.p2.sid] = self.wins.get(self.p2.sid, 0) + 1
        else:
            winner_sid = self.p1.sid
            self.wins[self.p1.sid] = self.wins.get(self.p1.sid, 0) + 1

        # Проверка на победу в матче (например, до 5 побед)
        if self.wins.get(self.p1.sid, 0) >= 5:
            game_winner = self.p1.name
            self.state = "finished"
        elif self.wins.get(self.p2.sid, 0) >= 5:
            game_winner = self.p2.name
            self.state = "finished"

        # Формируем словарь побед с именами для фронтенда
        wins_with_names = {
            self.p1.name: self.wins.get(self.p1.sid, 0),
            self.p2.name: self.wins.get(self.p2.sid, 0)
        }

        # Отправляем событие конца раунда
        self.socketio.emit('round_end', {
            'winner_sid': winner_sid,
            'wins': wins_with_names,
            'game_over': game_winner is not None,
            'winner_name': game_winner
        }, room=self.room)

        if not game_winner:
            # Если игра продолжается, готовимся к новому выбору перков
            self.round_num += 1
            self.state = "picking"
            self.p1.reset_round_state()
            self.p2.reset_round_state()
            # Даем небольшую паузу и запускаем фазу выбора
            self.socketio.sleep(1.5)
            self.start_picking_phase()

    def update_abilities_from_dict(self):
        self.abilities = []
        for ability_id, stacks in self.abilities_dict.items():
            ability_template = get_ability_by_id(ability_id)
            if ability_template:
                # Создаем копию объекта способности для этого игрока
                import copy
                new_ability = copy.copy(ability_template)
                new_ability.stack_count = stacks
                # Устанавливаем время первого срабатывания сразу
                new_ability.next_tick = 0 
                self.abilities.append(new_ability)

    def tick(self):
        current_time = time.time()
        
        # Обновляем длительность стана для обоих игроков в начале каждого тика
        delta_time = 0.1  # Предполагаем, что тик происходит каждые 0.1 сек
        self.p1.update_stun(delta_time)
        self.p2.update_stun(delta_time)
        
        # Флаги для отслеживания, кто был оглушен в этом тике
        p1_stunned_this_tick = False
        p2_stunned_this_tick = False
        
        # Сначала обрабатываем P1
        attacker, defender = self.p1, self.p2
        if attacker and defender:
            if not attacker.is_stunned() and not p1_stunned_this_tick:
                # Группируем способности по типу для применения стеков
                ability_groups = {}
                for ab in attacker.abilities:
                    if ab.name not in ability_groups:
                        ability_groups[ab.name] = []
                    ability_groups[ab.name].append(ab)
                
                # Применяем способности с учётом стеков
                for ability_name, ability_list in ability_groups.items():
                    stacks = len(ability_list)
                    
                    # Множитель от стеков
                    stack_multiplier = 1.0
                    if stacks > 1 and ability_list[0].stackable:
                        stack_multiplier = 1.0 + (stacks - 1) * 0.2
                    
                    speed_mod = 1.0
                    if "swiftness" in attacker.abilities_dict:
                        swiftness_stacks = attacker.abilities_dict.get("swiftness", 0)
                        speed_mod = 2.0 + (swiftness_stacks - 1) * 0.3
                    
                    # Проходим по каждой копии способности
                    for ab in ability_list:
                        if current_time >= ab.next_tick:
                            val, new_delay = ab.activate(speed_mod, stack_multiplier)
                            ab.next_tick = current_time + new_delay
                            
                            # ЛЕЧЕНИЕ
                            if ab.is_heal:
                                attacker.hp = min(attacker.max_hp, attacker.hp + val)
                                self.add_activation_event(ActivationEvent(
                                    player_sid=attacker.sid,
                                    player_name=attacker.name,
                                    ability_name=ab.name,
                                    ability_rarity_color=ab.get_rarity_color(),
                                    value=val,
                                    is_heal=True,
                                    is_crit=False
                                ))
                            
                            # УРОН
                            else:
                                dmg = val
                                was_crit = False
                                
                                # Проверяем на крит
                                crit_chance = 0.1
                                
                                if ab.name == "berserker_strike":
                                    crit_chance = ab.special_properties.get('crit_chance', 0.4)
                                
                                if "crit" in attacker.abilities_dict:
                                    crit_stacks = attacker.abilities_dict.get("crit", 0)
                                    crit_chance += (crit_stacks - 1) * 0.05
                                
                                if random.random() < crit_chance:
                                    dmg = int(dmg * 2)
                                    was_crit = True
                                
                                # Применяем урон с учетом щита
                                self.apply_damage(defender, dmg)
                                
                                # Отправляем ОДНО событие атаки
                                self.add_activation_event(ActivationEvent(
                                    player_sid=attacker.sid,
                                    player_name=attacker.name,
                                    ability_name=ab.name,
                                    ability_rarity_color=ab.get_rarity_color(),
                                    value=dmg,
                                    is_heal=False,
                                    is_crit=was_crit
                                ))
                                
                                # Оглушение для chain_lightning - ТОЛЬКО проверка на стан, без отправки урона
                                if ab.name == "chain_lightning" and not defender.is_stunned():
                                    stun_chance = ab.special_properties.get('stun_chance', 0.2)
                                    if random.random() < stun_chance:
                                        defender.stun_duration = 1.0
                                        print(f"DEBUG: {defender.name} is stunned immediately by {attacker.name}!")
                                        
                                        # Устанавливаем флаг, что защитник оглушен в этом тике
                                        if defender == self.p1:
                                            p1_stunned_this_tick = True
                                        else:
                                            p2_stunned_this_tick = True
                                        
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=defender.sid,
                                            player_name=defender.name,
                                            ability_name="Оглушение",
                                            ability_rarity_color="#d2b61e",
                                            value=0,
                                            is_heal=False,
                                            is_crit=False,
                                            effect_type=ActivationType.STUN
                                        ))

                                if ab.name == "ice_touch":
                                    # Получаем базовую длительность из свойств способности
                                    base_duration = ab.special_properties.get('stun_duration', 1.0)
                                    # Учитываем стаки
                                    current_stacks = getattr(ab, 'stack_count', 1)
                                    total_duration = base_duration + (current_stacks - 1) * 0.5
                                    
                                    defender.stun_duration = max(defender.stun_duration, total_duration)
                                    
                                    print(f"❄️ {attacker.name} stuns {defender.name} for {total_duration:.1f}s (stacks: {current_stacks})")
                                    
                                    self.add_activation_event(ActivationEvent(
                                        player_sid=attacker.sid,
                                        player_name=attacker.name,
                                        ability_name=ab.name,
                                        ability_rarity_color=ab.get_rarity_color(),
                                        value=int(total_duration * 10),
                                        is_heal=False,
                                        is_crit=False,
                                        effect_type=ActivationType.STUN
                                    ))
                                
                                # Вампиризм для vampiric_bite
                                if ab.name == "vampiric_bite":
                                    lifesteal = ab.special_properties.get('lifesteal', 0.5)
                                    heal_amt = int(dmg * lifesteal)
                                    if heal_amt > 0:
                                        attacker.hp = min(attacker.max_hp, attacker.hp + heal_amt)
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=attacker.sid,
                                            player_name=attacker.name,
                                            ability_name="Укус вампира",
                                            ability_rarity_color="#77136f",
                                            value=heal_amt,
                                            is_heal=True,
                                            is_crit=False,
                                            effect_type=ActivationType.LIFESTEAL
                                        ))
                                
                                # Яд
                                if "venom" in attacker.abilities_dict:
                                    poison_chance = 0.3
                                    venom_stacks = attacker.abilities_dict.get("venom", 0)
                                    if venom_stacks > 1:
                                        poison_chance = 0.3 + (venom_stacks - 1) * 0.1
                                    
                                    if random.random() < poison_chance:
                                        defender.poison_stacks += venom_stacks
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=attacker.sid,
                                            player_name=attacker.name,
                                            ability_name="Яд",
                                            ability_rarity_color="#72c144",
                                            value=venom_stacks,
                                            is_heal=False,
                                            is_crit=False,
                                            effect_type=ActivationType.POISON_APPLY
                                        ))
                                
                                # Отражение
                                if "soulbind" in defender.abilities_dict:
                                    reflect = 0.2
                                    soulbind_stacks = defender.abilities_dict.get("soulbind", 0)
                                    if soulbind_stacks > 1:
                                        reflect = 0.2 + (soulbind_stacks - 1) * 0.05
                                    
                                    reflect_dmg = int(dmg * reflect)
                                    if reflect_dmg > 0:
                                        self.apply_damage(attacker, reflect_dmg)
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=defender.sid,
                                            player_name=attacker.name,
                                            ability_name="Связь душ",
                                            ability_rarity_color="#77136f",
                                            value=reflect_dmg,
                                            is_heal=False,
                                            is_crit=False,
                                            effect_type=ActivationType.REFLECT
                                        ))
            else:
                print(f"DEBUG: {attacker.name} is stunned, cannot act")
        
        # Затем обрабатываем P2 (с учетом флагов оглушения от P1)
        attacker, defender = self.p2, self.p1
        if attacker and defender:
            if not attacker.is_stunned() and not p2_stunned_this_tick:
                # Группируем способности по типу для применения стеков
                ability_groups = {}
                for ab in attacker.abilities:
                    if ab.name not in ability_groups:
                        ability_groups[ab.name] = []
                    ability_groups[ab.name].append(ab)
                
                # Применяем способности с учётом стеков
                for ability_name, ability_list in ability_groups.items():
                    stacks = len(ability_list)
                    
                    # Множитель от стеков
                    stack_multiplier = 1.0
                    if stacks > 1 and ability_list[0].stackable:
                        stack_multiplier = 1.0 + (stacks - 1) * 0.2
                    
                    speed_mod = 1.0
                    if "swiftness" in attacker.abilities_dict:
                        swiftness_stacks = attacker.abilities_dict.get("swiftness", 0)
                        speed_mod = 2.0 + (swiftness_stacks - 1) * 0.3
                    
                    # Проходим по каждой копии способности
                    for ab in ability_list:
                        if current_time >= ab.next_tick:
                            val, new_delay = ab.activate(speed_mod, stack_multiplier)
                            ab.next_tick = current_time + new_delay
                            
                            # ЛЕЧЕНИЕ
                            if ab.is_heal:
                                attacker.hp = min(attacker.max_hp, attacker.hp + val)
                                self.add_activation_event(ActivationEvent(
                                    player_sid=attacker.sid,
                                    player_name=attacker.name,
                                    ability_name=ab.name,
                                    ability_rarity_color=ab.get_rarity_color(),
                                    value=val,
                                    is_heal=True,
                                    is_crit=False
                                ))
                            
                            # УРОН
                            else:
                                dmg = val
                                was_crit = False
                                
                                # Проверяем на крит
                                crit_chance = 0.1
                                
                                if ab.name == "berserker_strike":
                                    crit_chance = ab.special_properties.get('crit_chance', 0.4)
                                
                                if "crit" in attacker.abilities_dict:
                                    crit_stacks = attacker.abilities_dict.get("crit", 0)
                                    crit_chance += (crit_stacks - 1) * 0.05
                                
                                if random.random() < crit_chance:
                                    dmg = int(dmg * 2)
                                    was_crit = True
                                
                                # Применяем урон с учетом щита
                                self.apply_damage(defender, dmg)
                                
                                # Отправляем ОДНО событие атаки
                                self.add_activation_event(ActivationEvent(
                                    player_sid=attacker.sid,
                                    player_name=attacker.name,
                                    ability_name=ab.name,
                                    ability_rarity_color=ab.get_rarity_color(),
                                    value=dmg,
                                    is_heal=False,
                                    is_crit=was_crit
                                ))
                                
                                # Оглушение для chain_lightning - ТОЛЬКО проверка на стан, без отправки урона
                                if ab.name == "chain_lightning" and not defender.is_stunned():
                                    stun_chance = ab.special_properties.get('stun_chance', 0.2)
                                    if random.random() < stun_chance:
                                        defender.stun_duration = 1.0
                                        print(f"DEBUG: {defender.name} is stunned immediately by {attacker.name}!")
                                        
                                        # Устанавливаем флаг, что защитник оглушен в этом тике
                                        if defender == self.p1:
                                            p1_stunned_this_tick = True
                                        else:
                                            p2_stunned_this_tick = True
                                        
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=defender.sid,
                                            player_name=defender.name,
                                            ability_name="Оглушение",
                                            ability_rarity_color="#d2b61e",
                                            value=0,
                                            is_heal=False,
                                            is_crit=False,
                                            effect_type=ActivationType.STUN
                                        ))

                                if ab.name == "ice_touch":
                                    # Получаем базовую длительность из свойств способности
                                    base_duration = ab.special_properties.get('stun_duration', 1.0)
                                    # Учитываем стаки
                                    current_stacks = getattr(ab, 'stack_count', 1)
                                    total_duration = base_duration + (current_stacks - 1) * 0.5
                                    
                                    defender.stun_duration = max(defender.stun_duration, total_duration)
                                    
                                    print(f"❄️ {attacker.name} stuns {defender.name} for {total_duration:.1f}s (stacks: {current_stacks})")
                                    
                                    self.add_activation_event(ActivationEvent(
                                        player_sid=attacker.sid,
                                        player_name=attacker.name,
                                        ability_name=ab.name,
                                        ability_rarity_color=ab.get_rarity_color(),
                                        value=int(total_duration * 10),
                                        is_heal=False,
                                        is_crit=False,
                                        effect_type=ActivationType.STUN
                                    ))
                                
                                # Вампиризм для vampiric_bite
                                if ab.name == "vampiric_bite":
                                    lifesteal = ab.special_properties.get('lifesteal', 0.5)
                                    heal_amt = int(dmg * lifesteal)
                                    if heal_amt > 0:
                                        attacker.hp = min(attacker.max_hp, attacker.hp + heal_amt)
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=attacker.sid,
                                            player_name=attacker.name,
                                            ability_name="Укус вампира",
                                            ability_rarity_color="#77136f",
                                            value=heal_amt,
                                            is_heal=True,
                                            is_crit=False,
                                            effect_type=ActivationType.LIFESTEAL
                                        ))
                                
                                # Яд
                                if "venom" in attacker.abilities_dict:
                                    poison_chance = 0.3
                                    venom_stacks = attacker.abilities_dict.get("venom", 0)
                                    if venom_stacks > 1:
                                        poison_chance = 0.3 + (venom_stacks - 1) * 0.1
                                    
                                    if random.random() < poison_chance:
                                        defender.poison_stacks += venom_stacks
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=attacker.sid,
                                            player_name=attacker.name,
                                            ability_name="Яд",
                                            ability_rarity_color="#72c144",
                                            value=venom_stacks,
                                            is_heal=False,
                                            is_crit=False,
                                            effect_type=ActivationType.POISON_APPLY
                                        ))
                                
                                # Отражение
                                if "soulbind" in defender.abilities_dict:
                                    reflect = 0.2
                                    soulbind_stacks = defender.abilities_dict.get("soulbind", 0)
                                    if soulbind_stacks > 1:
                                        reflect = 0.2 + (soulbind_stacks - 1) * 0.05
                                    
                                    reflect_dmg = int(dmg * reflect)
                                    if reflect_dmg > 0:
                                        self.apply_damage(attacker, reflect_dmg)
                                        self.add_activation_event(ActivationEvent(
                                            player_sid=defender.sid,
                                            player_name=attacker.name,
                                            ability_name="Связь душ",
                                            ability_rarity_color="#77136f",
                                            value=reflect_dmg,
                                            is_heal=False,
                                            is_crit=False,
                                            effect_type=ActivationType.REFLECT
                                        ))
            else:
                print(f"DEBUG: {attacker.name} is stunned, cannot act")
        
        # Яд - тики
        for player in [self.p1, self.p2]:
            if player.poison_stacks > 0:
                poison_dmg_per_stack = 0.15
                for attacker in [self.p1, self.p2]:
                    if attacker != player and "venom" in attacker.abilities_dict:
                        venom_stacks = attacker.abilities_dict.get("venom", 0)
                        poison_dmg_per_stack = 0.15 + (venom_stacks - 1) * 0.07
                        break
                
                poison_dmg = player.poison_stacks * poison_dmg_per_stack
                player.hp -= poison_dmg
                
                for p in [self.p1, self.p2]:
                    self.add_activation_event(ActivationEvent(
                        player_sid=p.sid,
                        player_name=attacker.name,
                        ability_name="Яд",
                        ability_rarity_color="#72c144",
                        value=int(poison_dmg),
                        is_heal=False,
                        is_crit=False,
                        effect_type=ActivationType.POISON_TICK
                    ))
                
                player.poison_stacks = max(0, player.poison_stacks - 0.5)

    def apply_damage(self, target, amount):
        if target.shield > 0:
            if target.shield >= amount:
                target.shield -= amount
                amount = 0
            else:
                amount -= target.shield
                target.shield = 0
        target.hp -= amount

    def get_state(self):
        return {
            "p1": self.p1.to_dict(),
            "p2": self.p2.to_dict(),
            "round": self.round_num,
            "logs": self.action_logs  # Добавляем логи в состояние
        }

    def resolve_round(self):
        winner_sid = None
        if self.p1.hp > 0 and self.p2.hp <= 0: 
            winner_sid = self.p1.sid
            print(f"Match {self.match_id}: Round {self.round_num} winner is {self.p1.name}")
        elif self.p2.hp > 0 and self.p1.hp <= 0: 
            winner_sid = self.p2.sid
            print(f"Match {self.match_id}: Round {self.round_num} winner is {self.p2.name}")
        else:
            # Ничья - никто не получает победу
            print(f"Match {self.match_id}: Round {self.round_num} is a draw")
        
        if winner_sid: 
            self.wins[winner_sid] += 1
            print(f"Match {self.match_id}: Wins now - {self.p1.name}: {self.wins.get(self.p1.sid, 0)}, "
                f"{self.p2.name}: {self.wins.get(self.p2.sid, 0)}")

        # ИСПРАВЛЕНИЕ: Используем elif вместо двух if
        game_winner = None
        if self.wins[self.p1.sid] >= 5:
            game_winner = self.p1.name
            print(f"Match {self.match_id}: GAME OVER - {self.p1.name} wins the match!")
        elif self.wins[self.p2.sid] >= 5:  # Используем elif
            game_winner = self.p2.name
            print(f"Match {self.match_id}: GAME OVER - {self.p2.name} wins the match!")

        wins_with_names = {
            self.p1.name: self.wins.get(self.p1.sid, 0),
            self.p2.name: self.wins.get(self.p2.sid, 0)
        }

        print(f"Match {self.match_id}: Round ended. Game over: {game_winner is not None}")

        self.socketio.emit('round_end', {
            'winner_sid': winner_sid, 
            'wins': wins_with_names,
            'game_over': game_winner is not None,
            'winner_name': game_winner
        }, room=self.room)

        if not game_winner:
            self.round_num += 1
            print(f"Match {self.match_id}: Starting round {self.round_num}")
            
            # Сбрасываем состояние игроков для нового раунда
            self.p1.round_choice = None
            if self.p2:
                self.p2.round_choice = None
            
            self.socketio.sleep(0.8)
            
            # Проверяем, что матч всё ещё существует и не завершен
            if self.state != "finished":
                print(f"Match {self.match_id}: Starting picking phase for round {self.round_num}")
                self.start_picking_phase()
            else:
                print(f"Match {self.match_id}: State changed to finished during sleep")
        else:
            self.state = "finished"
            print(f"Match {self.match_id}: Match finished, winner: {game_winner}")