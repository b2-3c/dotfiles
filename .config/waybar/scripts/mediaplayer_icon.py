#!/usr/bin/env python3
import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
from gi.repository.Playerctl import Player
import argparse
import logging
import sys
import signal
import json
import os
from typing import List

logger = logging.getLogger(__name__)

def signal_handler(sig, frame):
    # Standard signal handler
    sys.stdout.write("\n")
    sys.stdout.flush()
    sys.exit(0)

class PlayerManager:
    def __init__(self, selected_player=None):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()
        self.manager.connect(
            "name-appeared", lambda *args: self.on_player_appeared(*args))
        self.manager.connect(
            "player-vanished", lambda *args: self.on_player_vanished(*args))

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
        self.selected_player = selected_player

        self.init_players()

    def init_players(self):
        for player in self.manager.props.player_names:
            if self.selected_player is not None and self.selected_player != player.name:
                continue
            self.init_player(player)

    def run(self):
        self.loop.run()

    def init_player(self, player_name):
        player = Playerctl.Player.new_from_name(player_name)
        player.connect("playback-status", self.on_playback_status_changed, None)
        # Note: We don't need metadata, so we skip connecting that event
        self.manager.manage_player(player)
        self.update_output(player) # Initial update

    def get_players(self) -> List[Player]:
        return self.manager.props.players

    def get_first_playing_player(self):
        players = self.get_players()
        if len(players) > 0:
            # Prefer the most recently added playing player
            for player in players[::-1]:
                if player.props.status == "Playing":
                    return player
            # Otherwise, return the first player found
            return players[0]
        else:
            return None

    def write_output(self, text, status_class, player):
        # This is the simplified write_output function
        output = {
            "text": text,
            "class": status_class, # ONLY the status class
            "alt": player.props.player_name
        }
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    def clear_output(self):
        # Output a simple Spotify icon, but clear the class
        output = {"text": " ", "class": "", "alt": ""} 
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    def on_playback_status_changed(self, player, status, _=None):
        self.update_output(player)

    def update_output(self, player):
        current_playing = self.get_first_playing_player()
        
        # Only update if this is the active player (or if no player is active)
        if current_playing is None or current_playing.props.player_name == player.props.player_name:
            
            player_name = player.props.player_name
            status = player.props.status
            
            status_class = ""
            if status == "Playing":
                status_class = "playing"
            elif status == "Paused":
                status_class = "paused"
            
            # Use the Spotify icon and separator from your configuration
            icon_text = " "
            
            self.write_output(icon_text, status_class, player)
        
    def on_player_appeared(self, _, player_name):
        if self.selected_player is None or player_name.name == self.selected_player:
            self.init_player(player_name)

    def on_player_vanished(self, _, player):
        self.show_most_important_player()

    def show_most_important_player(self):
        current_player = self.get_first_playing_player()
        if current_player is not None:
            self.update_output(current_player)
        else:    
            self.clear_output()

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--player")
    return parser.parse_args()


def main():
    arguments = parse_arguments()
    player = PlayerManager(arguments.player)
    player.run()


if __name__ == "__main__":
    main()