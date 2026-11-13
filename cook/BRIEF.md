# Brief: DayXero v5 redesign (cook run 2)

Target: Redesign every onboarding screen (14), the trial paywall, Home and the Program tab, in dark and light. Today's screenshots sit beside the proposals in a design canvas, and the proposed screens play their motion.
References: the app's own CI screenshots S01–S19 (`ci-screens-v4`, `ci-screens`, `ci-screens-program`). No outside references; polish against the bar.
Bar: 9.2/10 per screen, as the median of fresh-context critics, in both modes. Critic scores are eyeballed and are logged as such.
Calibration offset: none yet.
Rules: Reskin allowed (any colour, component, layout, new badges); keep Xero and the fonts (Bricolage Grotesque, DM Sans). Direction "night to Day Xero": one ground per mode, a dawn glow that rises through onboarding, coral as the only action colour, green only for done. Default slop bans. No em dashes in UI copy.
Motion: playing prototypes in the canvas (CSS loops on a 6 s cycle), each mapped to DX.Move tokens and SwiftUI APIs in notes. Must include completion states on buttons and badges where they help.
Time: floor 1.5h, then continue until the bar is met. Started: 2026-11-13 09:37 UTC.
Deliverable: canvas https://claude.ai/artifact/Hd5NSYRYcVQbd5vheT56rd (new "v5" pages; run 1 pages kept). Private until shared.
Permissions: push to claude/beautiful-ptolemy-qy0jwa only. No deploy, no PR.
User's words: "onboarding itself has 13-16 screens"; "keep on changing till the score is about the specified threshold 9.2/10"; "you have the permission to even reskin any screen, change any color"; "add new badges if needed, any completed animations to any button"; "I dont like the current homescreen much, so you can even think about changing it"; "the program screen (you can change this also, if needed)".
