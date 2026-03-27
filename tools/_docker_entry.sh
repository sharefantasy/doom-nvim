#!/usr/bin/env sh
# Automatically enter into nvim (by doing this in entrypoint rather than Dockerfile you can still quit and re-enter neovim)
# Add alias to watch config for changes and reload nvim, 
# this needs to be debounced otherwise it's quite hard to exit.

echo "alias gentlewindwatch=\"chokidar '/home/gentlewind/.config/nvim/**/*.lua' -t 100 -c 'debounce 1 | nvim'\"" >> ~/.bashrc
echo "echo 'Use '\$ gentlewindwatch' command to automatically restart nvim on changes to gentlewind-nvim-contrib.'" >> ~/.bashrc
echo "echo '    This command is still buggy and hard to exit, you may have to close your terminal if you use it.  :( '" >> ~/.bashrc

echo "nvim" >> ~/.bashrc
# Cd into workspace folder
cd ~/workspace
# Start bash and therefore neovim
bash

