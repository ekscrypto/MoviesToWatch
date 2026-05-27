Decision: To the maximum extent possible, UI is in SwiftUI.

Reasoning: Modern and well-suited for data-driven updates. Fewer chances of creating retention cycles. The app does not require advanced performance optimisations that would justify dropping to AppKit.

## Review Scope

**Strengthens** findings about new UI written in AppKit (`NSViewController`, `NSView`, AppKit-only bindings) when SwiftUI would suffice, or AppKit glue that reintroduces retention-cycle and delegate-management risk the SwiftUI move was meant to remove. **Drops** complaints that SwiftUI is "slower" or "less expressive" for surfaces this app does not exercise at scale — the project has explicitly accepted SwiftUI's performance envelope and does not need AppKit-grade optimisation for the views it ships.
