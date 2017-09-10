# Sniffer

Sniffer is based on [NetworkExtension](https://developer.apple.com/documentation/networkextension) framework and provides system level's Network Session Sniffing.

## Running

Before running, use [Carthage](https://github.com/Carthage/Carthage) to integrate [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) & [ZPTCPIPStack](https://github.com/zapcannon87/ZPTCPIPStack).

If you installed carthage, just run this command.
```bash
carthage update
```

**Then, add the extension and framework's scheme.**

#### Warning

there is a problem with directly integrating ZPTCPIPStack into project using Carthage, so I must refer the files to the project's inner framework. if you just run this demo, well, no problem. but if you want to modify file or file's organisation, you must know what you are doing.

## Feature

Now, this demo just implement HTTP & HTTPS & TCP(Except HTTP & HTTPS) Proxy.