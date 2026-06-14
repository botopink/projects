#!/usr/bin/env bash
# colors.sh — pass/fail/warn shell helpers for the tracked pre-commit hook.
# Sourced by lib/test-runner.sh and the per-project runners.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
pass() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
info() { echo -e "  $1"; }
