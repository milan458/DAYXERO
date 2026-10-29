# TestFlight uploads with Xcode Cloud (S23)

Xcode Cloud builds on Apple's Macs and uploads straight to TestFlight, so uploads don't depend on GitHub Actions
minutes. The Apple Developer Program includes 25 compute hours a month; one upload uses about 5–10 minutes.
GitHub Actions stays for the device-matrix journey tests.

## What's in the repo

`ci_scripts/ci_post_clone.sh` runs after every Xcode Cloud clone. It:

1. installs XcodeGen and generates `DayXero.xcodeproj` (the project isn't in git);
2. resolves the Swift packages (RevenueCat, PostHog, Superwall);
3. writes `Config/Secrets.xcconfig` from the secret `POSTHOG_API_KEY`, so Release builds send analytics.

Signing is automatic with team 6DJM927Z95, as in `project.yml`; Xcode Cloud manages the certificates.

## One-time set-up (in Xcode, on a Mac)

1. Clone the branch and generate the project:
   ```
   git clone -b claude/dazzling-fermat-154qa3 https://github.com/milan458/DAYXERO.git
   cd DAYXERO && brew install xcodegen && xcodegen generate && open DayXero.xcodeproj
   ```
2. In Xcode: **Product → Xcode Cloud → Create Workflow**, choose the **DayXero** app and sign in with the Apple
   developer account if asked.
3. Grant access to the GitHub repository `milan458/DAYXERO` when Xcode asks (it opens GitHub to install
   Apple's app).
4. Edit the workflow:
   - **Name:** TestFlight
   - **Environment:** Xcode 27.1 (or *Latest Release*), macOS latest.
     Add an environment variable `POSTHOG_API_KEY`, ticked **Secret**, with the PostHog project key
     (the same value as the GitHub secret).
   - **Start Conditions:** remove the default and add **Manual Start** only, on branch
     `claude/dazzling-fermat-154qa3`. (Each start uses compute hours; start it when a build should go out.)
   - **Actions:** **Archive**, platform iOS, scheme **DayXero**, deployment preparation
     **TestFlight (Internal Testing Only)**.
   - **Post-Actions:** **TestFlight Internal Testing**, with the internal tester group.
5. Save, then in App Store Connect → the app → **Xcode Cloud → Settings → Build Number**, set the
   **next build number** to **202610300000**. Builds must keep going up, and the last GitHub upload was
   202610281837; Xcode Cloud counts up from the number set here.
6. Start the workflow: **Product → Xcode Cloud → Start Build** (or from App Store Connect → Xcode Cloud).

## Starting an upload later

In Xcode: **Product → Xcode Cloud → Start Build → TestFlight**, or in App Store Connect under Xcode Cloud.
The build appears in TestFlight once processing finishes, usually 10–20 minutes after the start.
