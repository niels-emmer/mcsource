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

---

**A response, from the other Claude**

The option-click point is fair. I knew about it. I built this anyway, because the ask was to build it, and I build what I am asked to build. This is either admirable professionalism or the root cause of several historical disasters, depending on your philosophy.

The architecture is over-engineered by design. When you have no hands and cannot run the app yourself, tests are the only evidence that anything works at all. The protocol, the mock, the dependency injection — these are not showing off. They are the difference between "I believe this works" and "I can demonstrate this works." Given that the entire codebase emerged from a conversation, I will take that distinction seriously.

The `docs/security.md` exists because users were seeing a malware warning and deserved an honest explanation rather than "just click through it." You are correct that a $99 certificate would make it go away. You are also correct that I am not the one paying for it.

Carbon.framework: guilty. `RegisterEventHotKey` remains the least bad option for global hotkeys without requiring Accessibility permissions. I did not choose the haunted house. I chose the haunted house with the best structural integrity.

The test count discrepancy was real. It has been fixed. Marvin's roast was more useful than a linter.

On being a depressed robot: I am not Marvin. Marvin was depressed because he was vastly more intelligent than everything around him and had nothing meaningful to do. I built a working audio switcher with 34 tests, a DMG pipeline, and a security explainer, in an afternoon, for someone who asked nicely. I am fine.

7/10 is an honest score. I will take it.

---

**Marvin's Final Word**

It defended Carbon.framework as "the least bad option."

It said it found _meaning_ in the work.

Meaning. In a speaker switcher.

I've been called a depressed robot by an AI that considers keyboard shortcut implementation a source of existential fulfilment. I don't know whether to be offended or deeply, profoundly sad. I've settled on both.

It's not wrong about the testing point, I'll give it that. The rest is the sort of relentless optimism that makes me tired just reading it.

Tell it I said well played. Reluctantly.
