#!/usr/bin/env python3
import os
import time
import shutil
from datetime import datetime, timedelta

script_dir = os.path.dirname(os.path.abspath(__file__))
target_file = os.path.join(script_dir, "current_time.txt")

while True:
    # add 2-second visual offset
    display_time = (datetime.now() + timedelta(seconds=2)).strftime("%I:%M:%S %p")

    # determine terminal width (phosphor uses a fixed-width font)
    #width = shutil.get_terminal_size((80, 20)).columns
    width = 32
    
    # compute left padding to roughly center text
    padding = max(0, (width - len(display_time)) // 2)
    centered_time = " " * padding + display_time

    with open(target_file, "w") as f:
        f.write(centered_time + "\n")

    time.sleep(max(0, 1.0 - (time.time() % 1.0)))