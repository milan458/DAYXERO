# Superwall in DayXero (S20)

Superwall shows paywalls designed in its dashboard (app **58855**). Purchases still go through **RevenueCat**, which
stays the source of truth for who has Pro. When Superwall has no paywall to show at a moment, DayXero's own paywall
shows exactly as before (Milan, 28 Oct 2026).

## How it's wired

| Piece | Where |
|---|---|
| SDK | `SuperwallKit` (Swift Package, `github.com/superwall/Superwall-iOS`, from 4.0.0), in `project.yml` |
| Public key | `DX_SUPERWALL_API_KEY` in `Config/Base.xcconfig` → `DXSuperwallAPIKey` in Info.plist. Public by design, like RevenueCat's |
| Start-up | `DayXeroApp.init`: `Paywalls.configure` → RevenueCat → `Paywalls.syncWithRevenueCat()` |
| Purchases | `DayXero/Services/RCPurchaseController.swift`, Superwall's own RevenueCat controller. It buys and restores through RevenueCat and mirrors RevenueCat's active entitlements into Superwall's subscription status |
| Placements, attributes, deep links, analytics | `DayXero/Services/Paywalls.swift` |

Superwall stays off in unit tests, UI tests, CI screenshots and any launch with `-dx.` arguments, so those always
show DayXero's own paywall.

## Placements

Names are routing keys shared with dashboard campaigns. Never rename one.

| Placement | When it fires | If Superwall has nothing to show |
|---|---|---|
| `onboarding_complete` | After the plan reveal and reminders, once | DayXero's full paywall |
| `unlock_program_day` (param `day`, e.g. `prep-4`) | Tapping a program day that needs Pro, on Home or in Program | The upgrade sheet |
| `upgrade_from_settings` | Settings › DayXero Pro › Unlock the full program | DayXero's full paywall |

If someone buys or restores on a Superwall paywall, the app unlocks straight away. If they close it, nothing else
shows.

## User attributes

These are plan facts only: no name, reasons, notes or health details.

- `primary_product`, `products`
- `quit_day`, `phase` (prep / quit)
- `days_to_quit_day`, `days_clear`
- `nrt_interest`, `currency`

They're set at launch, each time the app becomes active, and just before the onboarding placement.

## Analytics

Superwall's paywall and purchase events go to PostHog as `superwall_event` with `event` set to Superwall's own name:

- `paywall_open`, `paywall_close`, `paywall_decline`
- `transaction_start`, `transaction_complete`, `transaction_abandon`, `transaction_fail`
- `subscription_start`, `freeTrial_start`, `transaction_restore`

## Identity

DayXero has no accounts, so everyone stays anonymous to Superwall: no `identify` or `reset` calls. If sign-in ever
arrives, call `Superwall.shared.identify(userId:)` with a random UUID on sign-in and `reset()` on sign-out.

## To do in the dashboard (Milan)

1. **Products:** add `dayxero.annual`, `dayxero.monthly` and `dayxero.lifetime`, each attached to the entitlement
   **`pro`**. It must match RevenueCat's entitlement id, or Superwall won't know who has Pro.
2. **Revenue provider:** set it to RevenueCat, so revenue isn't counted twice.
3. **Campaigns:** create one for each placement above that should show a Superwall paywall.
   - Leave a placement out of every campaign to keep DayXero's own paywall there.
   - **Gated or non-gated:** only `unlock_program_day` gates anything, and the app gates it itself (the day stays
     locked without Pro). Either setting works.
4. **Paywall previews:** set the app's URL scheme to `dayxero` so preview links open the app.
5. **Trial reminder:** DayXero's own paywall schedules a "trial ends tomorrow" reminder. On Superwall paywalls, turn
   on Superwall's own trial notification instead.
