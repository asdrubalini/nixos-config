#!/bin/bash

nix --experimental-features 'nix-command flakes' flake update
