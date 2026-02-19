import random
import time
from threading import Event
from .abilities import get_ability_by_id, get_random_perks

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

        # Получаем случайные способности
        perks_with_objects = get_random_perks(5)
        offer = []
        for perk_name, perk_obj in perks_with_objects:
            offer.append({
                'id': perk_name,
                'name_ru': perk_obj.name_ru,
                'description': perk_obj.description,
                'rarity': perk_obj.rarity.value,
                'stats': perk_obj.get_stats_text(),
                'stackable': perk_obj.stackable,
                'current_stacks': self._get_player_stacks(perk_name)
            })

        wins_with_names = {
            self.p1.name: self.wins.get(self.p1.sid, 0),
            self.p2.name: self.wins.get(self.p2.sid, 0)
        }

        print(f"Match {self.match_id}: Emitting perk_offer with {len(offer)} perks for round {self.round_num}")

        self.socketio.emit('perk_offer', {
            'perks': offer,
            'round': self.round_num,
            'wins': wins_with_names
        }, room=self.room)

    def _get_player_stacks(self, perk_id):
        """Получить текущее количество стеков способности у игроков"""
        stacks = {}
        if self.p1 and perk_id in self.p1.abilities_dict:
            stacks[self.p1.sid] = self.p1.abilities_dict[perk_id]
        if self.p2 and perk_id in self.p2.abilities_dict:
            stacks[self.p2.sid] = self.p2.abilities_dict[perk_id]
        return stacks

    def apply_perk(self, sid, perk_id):
        if self.state != "picking": return
        
        player = None
        if sid == self.p1.sid: player = self.p1
        elif self.p2 and sid == self.p2.sid: player = self.p2
        
        if not player: return
                
        if player.round_choice is None:
            # Используем новый метод add_ability
            if player.add_ability(perk_id):
                player.round_choice = perk_id
        
        # Проверка готовности обоих
        p1_chose = self.p1.round_choice is not None
        p2_chose = self.p2 is not None and self.p2.round_choice is not None
        
        if p1_chose and p2_chose:
            self.start_combat_phase()

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
        print(f"Match {self.match_id}: Game loop started")
        last_tick = time.time()
        tick_interval = 0.02  # Уменьшили с 0.05 до 0.02 (20ms вместо 50ms)
        
        while not self.stop_event.is_set() and self.state == "fighting":
            current_time = time.time()
            
            # Проверяем, прошло ли достаточно времени для следующего тика
            if current_time - last_tick >= tick_interval:
                self.tick()
                last_tick = current_time
                
                # Отправляем обновление состояния
                state = self.get_state()
                self.socketio.emit('state_update', state, room=self.room)
                
                # Проверка на конец раунда
                if self.p1.hp <= 0 or self.p2.hp <= 0:
                    self.resolve_round()
                    break
            
            # Минимальная пауза для экономии CPU
            self.socketio.sleep(0.005)  # Уменьшили с 0.01 до 0.005

    def tick(self):
        current_time = time.time()
        
        for attacker, defender in [(self.p1, self.p2), (self.p2, self.p1)]:
            if not attacker or not defender: continue
            
            # Группируем способности по типу для применения стеков
            ability_groups = {}
            for ab in attacker.abilities:
                if ab.name not in ability_groups:
                    ability_groups[ab.name] = []
                ability_groups[ab.name].append(ab)
            
            # Применяем способности с учётом стеков
            for ability_name, ability_list in ability_groups.items():
                stacks = len(ability_list)  # Количество копий способности
                
                # Множитель от стеков применяем ОДИН раз на группу
                stack_multiplier = 1.0
                if stacks > 1 and ability_list[0].stackable:
                    # +20% за каждый дополнительный стек (не экспоненциально)
                    stack_multiplier = 1.0 + (stacks - 1) * 0.2
                
                speed_mod = 1.0
                if "swiftness" in attacker.abilities_dict:
                    swiftness_stacks = attacker.abilities_dict.get("swiftness", 0)
                    # Базовая скорость 2.0, +0.3 за каждый дополнительный стек
                    speed_mod = 2.0 + (swiftness_stacks - 1) * 0.3
                
                # Проходим по каждой копии способности
                for ab in ability_list:
                    if current_time >= ab.next_tick:
                        val, new_delay = ab.activate(speed_mod, stack_multiplier)
                        ab.next_tick = current_time + new_delay
                        
                        if ab.is_heal:
                            attacker.hp = min(attacker.max_hp, attacker.hp + val)
                        else:
                            dmg = val
                            
                            # Применяем специальные эффекты из свойств способности
                            if "crit" in attacker.abilities_dict:
                                crit_chance = 0.25
                                # Увеличиваем шанс крита с количеством стеков
                                crit_stacks = attacker.abilities_dict.get("crit", 0)
                                if crit_stacks > 1:
                                    crit_chance = 0.25 + (crit_stacks - 1) * 0.05
                                
                                if random.random() < crit_chance:
                                    dmg = int(dmg * 2)
                            
                            if "bloodlust" in attacker.abilities_dict:
                                lifesteal = 0.5
                                bloodlust_stacks = attacker.abilities_dict.get("bloodlust", 0)
                                if bloodlust_stacks > 1:
                                    lifesteal = 0.5 + (bloodlust_stacks - 1) * 0.1
                                
                                heal_amt = int(dmg * lifesteal)
                                attacker.hp = min(attacker.max_hp, attacker.hp + heal_amt)
                            
                            if "venom" in attacker.abilities_dict:
                                poison_chance = 0.3
                                venom_stacks = attacker.abilities_dict.get("venom", 0)
                                if venom_stacks > 1:
                                    poison_chance = 0.3 + (venom_stacks - 1) * 0.1
                                
                                if random.random() < poison_chance:
                                    defender.poison_stacks += venom_stacks
                            
                            self.apply_damage(defender, dmg)
                            
                            if "soulbind" in defender.abilities_dict:
                                reflect = 0.2
                                soulbind_stacks = defender.abilities_dict.get("soulbind", 0)
                                if soulbind_stacks > 1:
                                    reflect = 0.2 + (soulbind_stacks - 1) * 0.05
                                
                                reflect_dmg = int(dmg * reflect)
                                if reflect_dmg > 0:
                                    self.apply_damage(attacker, reflect_dmg)
        
        # Тик яда (увеличиваем урон со стеками)
        # Проверяем обоих игроков на наличие яда
        for player in [self.p1, self.p2]:
            if player.poison_stacks > 0:
                # Урон от яда зависит от количества стеков яда
                poison_dmg_per_stack = 0.15  # Увеличили с 0.1 до 0.15
                
                # Проверяем, есть ли у атакующего способность venom для усиления яда
                # (в реальном коде нужно определить, кто наложил яд)
                # Для простоты используем максимальное значение
                for attacker in [self.p1, self.p2]:
                    if attacker != player and "venom" in attacker.abilities_dict:
                        venom_stacks = attacker.abilities_dict.get("venom", 0)
                        poison_dmg_per_stack = 0.15 + (venom_stacks - 1) * 0.07
                        break
                
                poison_dmg = player.poison_stacks * poison_dmg_per_stack
                player.hp -= poison_dmg
                # Уменьшаем количество стеков яда (теперь яд длится меньше)
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
            "round": self.round_num
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