# Finicky local fork

- Owner fork: `git@github.com:Overbryd/finicky.git` (`Overbryd` remote). `origin` is upstream `johnste/finicky`.
- Custom command support already exists on `feat/command`; `master` does not contain it. Reliability work is based on that fork, not upstream master.
- Installed app on ms1 runs from `Finicky/build/Release/Finicky.app`. Config `~/.finicky.js` resolves to `~/Projects/dotfiles/.finicky.js`.
- Default SafeBrowser launcher is `~/.bin/safebrowser`: remote Finder AppleScript via an ignored private EPPC configuration. Never print that connection string or invoke remote browsing without approval for the target URL.
- Custom launchers run asynchronously, with a 15-second deadline, closed stdin, discarded stdout/stderr, and completion delivered on the main queue. Timeout signals only the directly owned process; no pattern kills or automatic browser fallback.
- The owner explicitly authorizes full incoming and routed URL logging in Finicky's local console, including OAuth query strings. Do not copy live authorization URLs into agent transcripts or external logs. Child stdout/stderr remains discarded; launcher errors report status only.
- Build config API before Swift: `cd config-api && ./node_modules/.bin/esbuild --global-name=finickyConfigApi --bundle src/index.ts --outfile=dist/finickyConfigAPI.js --target=es2016 --format=iife && cp dist/finickyConfigAPI.js ../Finicky/Finicky/finickyConfigAPI.js`.
- JS verification: `cd config-api && ./node_modules/.bin/jest --runInBand && ./node_modules/.bin/tsc --noEmit`.
- Swift verification: `xcodebuild test -project Finicky/Finicky.xcodeproj -scheme Finicky -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`.
- Existing `test_notifications` depends on macOS test-host notification delivery and failed in the local noninteractive run. Report it separately; do not claim the complete suite passed when skipping it.
- Release build phase updates tracked `Finicky/Finicky/Info.plist` with commit count. Do not retain unrelated generated version edits.
- Root `node_modules/`, `package.json`, and `package-lock.json` were untracked before this work; preserve them.
