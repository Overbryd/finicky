import AppKit
import Foundation

@main
struct PrivateURLTransportTests {
    static func main() throws {
        let url = URL(string: "https://samlsp.private.zscaler.com/?secret=synthetic")!
        let script = "local $/; my $input=<STDIN>; exit(($input eq 'https://samlsp.private.zscaler.com/?secret=synthetic' && @ARGV == 0) ? 0 : 7);"
        let browser = try BrowserOpts(name: "private", appType: .command, openInBackground: false,
            profile: nil, command: "/usr/bin/perl", args: ["-e", script], urlTransport: "stdin")
        precondition(!getBrowserCommand(browser, url: url).contains(url.absoluteString))
        precondition(urlForLogging(url, sourceBundleId: "unknown") == "[private Zscaler URL]")
        precondition(urlForLogging(URL(string: "https://id.example/?secret=synthetic")!, sourceBundleId: "com.zscaler.zscaler") == "[private Zscaler URL]")
        precondition(urlForLogging(URL(string: "zsa://token?secret=synthetic")!, sourceBundleId: "unknown") == "[private Zscaler URL]")
        func wait(_ launch: (@escaping (CommandResult) -> Void) -> Void, expected: CommandResult) {
            var received: CommandResult?
            launch { received = $0 }
            let deadline = Date().addingTimeInterval(3)
            while received == nil && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
            precondition(received == expected)
        }
        wait({ done in openUrlWithBrowser(url, browserOpts: browser, completion: done) }, expected: .exited(0))
        wait({ done in shell(["/usr/bin/true"], input: Data(repeating: 65, count: 16385), completion: done) }, expected: .launchFailed)
        wait({ done in shell(["/bin/sleep", "20"], input: Data(repeating: 65, count: 16384), timeout: 0.1, completion: done) }, expected: .timedOut)
        print("Private URL transport synthetic tests passed")
    }
}
