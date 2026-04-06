#!/usr/bin/env bash
cd ~/dotfiles
git add .
git commit -m "Update dotfiles: $(date)"
git push
