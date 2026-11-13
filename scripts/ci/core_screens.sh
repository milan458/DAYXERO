#!/bin/bash
# Sourced by the Screenshots step of .github/workflows/ios.yml with core_only on: the current screens only,
# one shot each in light and dark, numbered in app order (pushed to ci-screens-core). Uses that step's shoot().

# both <name> [launch args...]: the screen in light, then dark.
n=0
both() {
  n=$((n + 1))
  local name; name=$(printf "%03d" "$n")-$1; shift
  shoot light large "$name-light" "$@"
  shoot dark large "$name-dark" "$@"
}

# Onboarding
for step in breathe welcome products baseline_cigarettes baseline_summary triggers personal obstacles nrt quit_day building reveal trial; do
  both "onboarding-$step" -dx.onboardingStep "$step"
done
both "paywall" -dx.paywallPreview YES -dx.store mock
# Today
PR="-dx.homeScenario prep -dx.store pro"
D3="-dx.homeScenario day3 -dx.store pro"
D12="-dx.homeScenario day12 -dx.store pro"
both "today-prep" $PR -dx.todaySlot morning
both "today-quit" $D3 -dx.todaySlot morning
both "today-lower" $D3 -dx.todaySlot morning -dx.homeScroll lower
both "today-evening" $D12 -dx.todaySlot evening
# SOS
WAIT=9 both "sos" $D3 -dx.sos YES -dx.sosElapsed 52
WAIT=9 both "sos-passed" $D3 -dx.sos YES -dx.sosOutcome passed
WAIT=9 both "sos-slipped" $D3 -dx.sos YES -dx.sosOutcome slipped
# Program, and a prep session (a deck of cards): the hand, a card, played, each beat type, mission, recap
both "program" $PR -dx.tab program
for st in 0:hand 1:card 2:played 8:reflect 9:choice 12:slider 16:commit 19:note 24:mission 25:completion; do
  WAIT=8 both "session-${st#*:}" $PR -dx.openSession P1 -dx.sessionStep "${st%%:*}"
done
# A lesson after Quit Day
for step in intro cards audio; do
  WAIT=8 both "lesson-$step" $D3 -dx.openSession W1D2 -dx.sessionBeat "$step"
done
# Progress
both "progress" $D12 -dx.tab progress
both "health" $D12 -dx.tab progress -dx.openHealth YES
both "health-item" $D12 -dx.tab progress -dx.openHealth YES -dx.openHealthItem lips
both "milestone" $D12 -dx.milestone 7
both "milestone-share" $D12 -dx.tab progress -dx.shareCard YES
# Logging, slips, NRT and tapering
both "log-menu" $D12 -dx.logSheet menu
both "log-craving" $D12 -dx.logSheet craving
both "slip" $D12 -dx.logSheet slip
for stage in talk what done; do
  both "slip-$stage" $D12 -dx.logSheet slip -dx.slipStage "$stage"
done
both "nrt" $D12 -dx.logSheet nrt
for stage in products schedule plan reminders; do
  both "nrt-$stage" $D12 -dx.logSheet nrt -dx.nrtStage "$stage"
done
both "taper" $PR -dx.seedPouches YES -dx.logSheet taper
# Daily pledge and check-in
WAIT=9 both "pledge" $D12 -dx.openPledge YES
both "checkin" $D12 -dx.openCheckIn YES
both "checkin-done" $D12 -dx.openCheckIn YES -dx.checkInDone YES
# Calm tools
both "calm" $D12 -dx.openCalmList YES
both "calm-box" $D12 -dx.openCalm boxBreathing -dx.calmElapsed 6
both "calm-grounding" $D12 -dx.openCalm grounding -dx.calmStep 1 -dx.calmTicked 2
both "calm-notice" $D12 -dx.openCalm noticeAndName
both "calm-done" $D12 -dx.openCalm dropAnchor -dx.calmDone YES
# Settings
for page in settings reminders dayEnd quietHours products quitDay currency subscription privacy health; do
  both "settings-$page" $D12 -dx.openSettings "$page"
done
