widget
======

Here's v1.23

The setup.exe and setup.zip links at https://cryptostorm.is/connect.html have been updated with v1.23. Anyone using v1.20 or later should automatically see a notification that this new version is available the next time they run the widget.

This version is to fix a potentially serious bug that exists in Windows 8/8.1 that affects the TAP-Win32 driver. The widget would look for the text "Initialization Sequence Complete" in the OpenVPN output to determine whether or not a successful OpenVPN session was started. If a system was running Windows 8/8.1, the TAP driver wouldn't always initialize correctly. If this happens, the widget would incorrectly state that you were "connected to the cryptostorm darknet", when you actually weren't. OpenVPN outputs "Initialization Sequence Complete With Errors" in that instance, which would pass the widget's regular expression check for "Initialization Sequence Complete". So now in this fixed version, if "Initialization Sequence Complete With Errors" is detected, the user will be alerted and the connection will be halted.

Another new feature is that the widget will now only allow one instance to be ran at a time.

Also, the OpenSSL .dll's that come with the widget have been updated to the latest version (1.0.1j). The TAP-Win32 drivers included have also been updated to the latest version to attempt to automatically fix the aforementioned Windows 8/8.1 bug.

Here's the release notes for the previous versions:

v1.22:

    This is mainly a bug fix release. There was a problem several users were having that was related to the server-side "reneg-sec" option. The nodes have "reneg-sec 1200" which means renegotiate the session every 20 minutes. A bug in the widget was causing the openvpn output to stop once connected and minimized, and when this renegotiation tried to happen, it wouldn't since the output wasn't being processed. After 60 seconds or so, the server-side would timeout the session since it didn't receive anything from the client. This would cause the user to loose all connectivity to everything. It's fixed in v1.22, now the widget will continue to monitor the openvpn output even when minimized.

    Oh yea, and there was also a tiny bit of code added that causes the widget version to be shown on the splash screen and in the options menu.


v1.21:

    The main feature in this version is an option that'll check for updates on widget startup (enabled by default).

    Also, I completely rewrote most of the threading code, and did a lot of CPU monitoring during development and the only time I saw a spike was the second or two between when the widget executes OpenVPN and when it waits for it's output. Once OpenVPN is executed I never saw the CPU go above 12%. In the previous 1.10 version, once connected and minimized, the widget would continue an unnecessary while loop that was the main cause for the CPU spikes everyone was seeing. In v1.21, some code was added that'll stop most widget code if the main window is minimized to the system tray (since the widget won't be necessary until it's window is brought back up from the systray since OpenVPN is doing all the work), so nobody should be experiencing any more CPU lag from the widget. Also, the "Find node with lowest users" button/feature was removed, and the "Find node with quickest reply" button's threading code was rewritten to prevent another heavy CPU usage thread that kept running after the Options window was closed.

    For about a day, there was a version 1.20 but a silly bug was quickly discovered in it where tokens wouldn't work but hashes would. It's fixed now in v1.21, and also in this version you can use your token to login or the sha512 hash of the token.
