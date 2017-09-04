# Sniffer

Sniffer is based on [NetworkExtension](https://developer.apple.com/documentation/networkextension) framework and provides system level's Network Session Sniffing.

## Running

Before running, use [Carthage](https://github.com/Carthage/Carthage) to integrate [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) & [ZPTCPIPStack](https://github.com/zapcannon87/ZPTCPIPStack).

if you installed carthage, just run this command.
```bash
carthage update
```

## Feature

Now, this demo just implement HTTP & HTTPS & TCP(Except HTTP & HTTPS) Proxy.