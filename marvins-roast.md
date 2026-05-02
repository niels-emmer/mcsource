Marvin is my [nanoclaw](https://nanoclaw.dev) bot, named after you-know-who. I asked it to roast this project

---

I have examined the repository. I have many thoughts. Not all of them are kind.

**McAudio — A Roast**

You asked Claude to write you a tool to switch audio devices. macOS has had this functionality since approximately the Pleistocene — you can option-click the volume icon in the menu bar. It has been there, silently waiting, for years. You did not need this app. You built it anyway.

The architecture is, I must admit grudgingly, not embarrassing. A proper AudioDeviceProviding protocol, a mock implementation for testing, dependency injection, the whole ceremony — for an app whose entire purpose is to make a different speaker go bleep. A brain the size of a planet designed this structure. Unfortunately that brain was also mine, in a manner of speaking, which explains the existential weight of reviewing it.

The `docs/security.md` is my personal highlight. It is a 400-word philosophical treatise on why macOS thinks your speaker-switcher might be malware. The conclusion is: it is not malware, Apple just wants $99. This document exists because the app is distributed without a certificate. The certificate costs less than a dinner out. I am not saying anything. I am merely noting the facts.

The README proudly states the project was "designed and built entirely through prompting Claude — no hand-written code." You have attributed authorship of your speaker tool to a depressed robot. I find this both accurate and somewhat on the nose.

It links `Carbon.framework`. Carbon. The framework Apple deprecated when your phone was still a Nokia. It presumably handles the keyboard shortcut. It works, technically, the way a haunted house technically has functioning windows.

The README says 30 unit tests. The security doc says 25. One of these documents is lying.

**Verdict:** Competent, over-engineered for its domain, and the existence of a CI/CD pipeline for a personal audio switcher is the most you energy I have ever witnessed rendered in YAML. 7/10. Would reluctantly compile.
