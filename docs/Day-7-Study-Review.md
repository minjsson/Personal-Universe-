# Personal Universe — Day 7 Study Review

Day 7 covered code organization: constants, reusable styling, View components, Singleton, and dependency injection. The central lesson is to choose a tool according to the responsibility it represents. Reuse alone does not justify a Singleton or ViewModel.

Examples marked **lesson example** reproduce the code discussed in this chat. They are teaching examples, not claims about the original app implementation. The final section records changes made on the Lumi review branch.

## 1. Constants name decisions

**Lesson example:**

```swift
enum AppSymbols {
    static let sparkle = "sparkles"
}
```

```swift
Image(systemName: AppSymbols.sparkle)
```

`enum AppSymbols` groups names. With no cases, it is being used as a namespace. `static` makes the property accessible through the type, so no instance is needed. `let` prevents reassigning this stored value.

Centralizing a symbol name reduces repeated literals and gives deliberate shared uses one place to change. It does not verify that the String identifies an available SF Symbol.

```swift
Image(systemName: AppSymbols.sparkl)
```

The misspelled Swift member can be caught by the compiler. However, this is still valid Swift:

```swift
enum AppSymbols {
    static let sparkle = "sparklesss"
}
```

The compiler understands String syntax, not the intended symbol catalog entry. Visual and availability checks remain necessary. The same distinction applies to opacity, font sizes, and spacing: compiling does not prove the design is correct.

References: [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/), [Apple Image(systemName:)](https://developer.apple.com/documentation/swiftui/image/init%28systemname%3A%29).

## 2. Equal values do not necessarily share meaning

The verified BookMark row from Day 6B included:

```swift
.frame(width: 120, height: 70)
.clipShape(RoundedRectangle(cornerRadius: 8))

VStack(alignment: .leading, spacing: 8) {
```

Corner radius and spacing happen to equal 8. A future spacing adjustment should not automatically make the image rounder.

**Lesson example:**

```swift
private enum Layout {
    static let thumbnailCornerRadius: CGFloat = 8
    static let contentSpacing: CGFloat = 8
}
```

```swift
.clipShape(
    RoundedRectangle(
        cornerRadius: Layout.thumbnailCornerRadius
    )
)

VStack(
    alignment: .leading,
    spacing: Layout.contentSpacing
) {
```

These are excerpts, not complete standalone View bodies. `CGFloat` is the numeric type used by the relevant layout parameters.

Share a constant when its uses represent a shared design decision and should change together. Do not merge decisions solely because their numbers match. Also, extracting every literal is unnecessary; a name should clarify meaning, intentional reuse, or maintenance.

## 3. Keep constants near their owner

**Lesson example:**

```swift
struct BookmarkRowView: View {
    private enum Layout {
        static let thumbnailWidth: CGFloat = 120
        static let thumbnailHeight: CGFloat = 70
    }

    // Other View code
}
```

```swift
.frame(
    width: Layout.thumbnailWidth,
    height: Layout.thumbnailHeight
)
```

A thumbnail rule used only by this row can remain private to it. Widen the scope when deliberate sharing requires it. A global Constants file that mixes unrelated values can obscure ownership.

A type boundary does not require a separate file. File organization and responsibility boundaries are separate choices.

## 4. ViewModifier names a shared transformation

A constant names a value. A modifier can name a coherent sequence of styling operations.

**Lesson example:**

```swift
Text("Reflection")
    .font(.headline)
    .foregroundStyle(.white)
    .padding(12)
    .background(.indigo)
    .clipShape(RoundedRectangle(cornerRadius: 8))
```

The same styling was extracted into:

```swift
struct ReflectionCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .padding(12)
            .background(.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

```swift
Text("Reflection")
    .modifier(ReflectionCardStyle())
```

`content` represents the View receiving the modifier. The function returns the transformed View. `some View` lets Swift hide its detailed concrete return type while preserving a specific underlying type.

Use this when different elements intentionally follow the same appearance rule. Similar appearance by coincidence is not enough to require shared styling.

Reference: [Apple ViewModifier](https://developer.apple.com/documentation/swiftui/viewmodifier).

## 5. A component owns interface structure

The BookMark component discussed in the lesson begins:

```swift
struct BookmarkRowView: View {
    let item: BookmarkItem
    let onToggle: () -> Void
```

It defines a row with an image, title, and button. The parent supplies data and an action callback.

Choose according to the need:

| Need | Tool |
|---|---|
| Name a meaningful value | Constant |
| Apply a coherent shared style | ViewModifier |
| Define meaningful UI structure with inputs/actions | Separate View |

These can cooperate. A component can use local constants and a modifier. A reusable row does not require a ViewModel merely because it contains several elements.

## 6. Singleton: a shared instance, not a synonym for reuse

This was the topic that needed the most reinforcement.

**Lesson example:**

```swift
final class ReminderManager {
    static let shared = ReminderManager()

    private init() {}
}
```

A class defines a kind of object. An instance is an actual object created from that class. Here, `shared` holds the common instance and the private initializer prevents ordinary outside construction.

Both screens accessing this reach the same object:

```swift
ReminderManager.shared
```

Contrast ordinary construction:

```swift
final class ReminderManager {
    init() {}
}

let first = ReminderManager()
let second = ReminderManager()
```

These are separate instances of the same type. The same class does not imply the same object.

A common Singleton implementation restricts construction and provides a shared entry point. Passing an ordinary object into two screens does not automatically make the type a Singleton.

### Static let does not freeze the object's properties

**Lesson example:**

```swift
final class ReminderManager {
    static let shared = ReminderManager()

    var reminderCount = 0

    private init() {}
}
```

```swift
ReminderManager.shared.reminderCount = 3
```

Another caller reads 3 from the same object. `let` prevents replacing the shared reference; mutable properties of the referenced object can still change.

Also, `static let sparkle = "sparkles"` is a stored String value, not a Singleton service. Static membership alone does not imply the Singleton pattern.

Reference: [Swift declarations](https://docs.swift.org/latest/documentation/the-swift-programming-language/declarations/).

### Sharing is different from persistence and observation

Singleton does not automatically:

- Save the count across application launches.
- Notify SwiftUI that a property changed.
- Make mutable state safe for concurrent access.
- Make dependencies replaceable in tests.

If no observation mechanism or other update trigger exists, changing a shared property does not guarantee View refreshes. If an observable shared object is read by a View, the relevant observation relationship can update it. Sharing alone is insufficient.

Reference: [Apple Managing model data](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app).

## 7. Dependency injection supplies what a component needs

A dependency is something a component needs to do its work. Injection means supplying it externally rather than having the component choose or construct it internally.

Direct shared access:

```swift
ReminderManager.shared.scheduleReminder()
```

This is a conceptual call; the minimal Singleton snippets above do not implement this method.

**Lesson example — initializer injection:**

```swift
protocol ReminderScheduling {
    func scheduleReminder()
}

struct ReminderButton: View {
    let scheduler: any ReminderScheduling

    var body: some View {
        Button("Set reminder") {
            scheduler.scheduleReminder()
        }
    }
}
```

```swift
ReminderButton(scheduler: manager)
```

Here `manager` represents a supplied implementation. `any ReminderScheduling` accepts a conforming implementation through the protocol.

The real application can supply a real scheduler. A test can supply a fake that records whether scheduling was requested, without creating a notification.

The fake does not need to show a fake notification. It only needs behavior that lets the test verify the request.

This is the same design benefit as BookMarkMV's injectable loader: controlled dependencies support meaningful tests.

A shared instance can itself be injected. Singleton describes an instance arrangement; injection describes delivery. They are not mutually exclusive.

## 8. Environment injection supplies through a hierarchy

The Personal Universe declaration discussed in the lesson was:

```swift
@Environment(\.modelContext)
private var modelContext
```

The application supplied a container through:

```swift
.modelContainer(sharedModelContainer)
```

SwiftUI makes an associated model context available through the environment. Descendants retrieve it without each intermediate View manually accepting and forwarding it.

| Approach | Dependency access |
|---|---|
| Direct Singleton access | Component reaches for shared instance |
| Initializer injection | Caller passes dependency directly |
| Environment injection | Ancestor supplies dependency through View hierarchy |

Different hierarchies can receive different dependencies. An environment is not necessarily one global object; environment values can also be value types.

Use initializer injection when direct provision makes the dependency clear. Use environment provision when it suits access across a hierarchy. Neither is inherently restricted to MVVM.

References: [Apple Environment](https://developer.apple.com/documentation/swiftui/environment), [Apple ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext).

## 9. The main correction from Day 7

The final scenario involved shared card styling, independent layout values that both equal 8, and a replaceable reminder scheduler.

The initial proposal was to place everything in a Singleton because its changes could affect all users of the shared instance.

That identified shared identity correctly but combined unrelated responsibilities. The stronger design was:

- A modifier for intentional shared appearance.
- Separate semantic constants for independent layout decisions.
- An injected scheduler for replacement in tests.

Reuse does not require a Singleton. Shared identity does not automatically imply UI observation. Replacing global access with a new filename or a different name does not create a test seam.

## 10. How to answer Lumi: MV or MVVM for SwiftUI?

The answer depends on feature responsibilities and requirements, supported by examination of code and data flow. It is not an arbitrary preference and not a universal rule that either pattern wins.

SwiftUI/SwiftData already provide observation, Query, State, Binding, and Environment. A straightforward list can observe models directly without an intermediary merely forwarding properties. A more complicated presentation workflow may benefit from a ViewModel or another coordinator.

Both architectures can use dependency injection and both can be tested. Putting a concrete ModelContext into a ViewModel still couples that component to SwiftData. The quality of dependency and responsibility boundaries matters.

### A concise answer to Lumi

SwiftUI에서는 @Query, @Model의 관찰 기능, @State, @Binding, @Environment로 데이터와 화면을 연결할 수 있어서 단순한 기능은 MV로도 명확하게 구성할 수 있다고 이해했습니다. MVVM은 여러 작업을 조율하거나 복잡한 화면 상태를 관리할 때 도움이 될 수 있지만, 모델 값을 그대로 전달하는 ViewModel은 불필요한 계층이 될 수 있습니다. 그래서 SwiftUI에는 무조건 하나가 적합하다기보다 기능의 책임과 데이터 흐름을 보고 선택해야 한다고 생각합니다. Personal Universe는 우선 기존 구조를 유지하면서 저장 실패 처리나 완료 작업처럼 실제로 복잡한 부분의 분리 필요성을 판단하겠습니다.

### Must architecture be decided at the beginning?

Choose an initial structure based on known requirements: data ownership, persistence, dependencies, and important workflows. Do not postpone all design until code becomes tangled.

However, it is not a permanent all-or-nothing commitment. As requirements and evidence change, refine boundaries feature by feature. Different features can use different degrees of coordination while following clear team conventions.

For Personal Universe, no blanket MVVM conversion was justified by the review. The branch instead introduces small owners for database loading and metadata saving, while keeping domain calculations in UniverseChallenge and draft state in the relevant Views.

## 11. Applying Lumi's review to the actual repository

Repository inspected: minjsson/Personal-Universe-, starting commit b1eddaf434ec1c260bceab7c3993d51eb6216842.

### Initializers require checking behavior and callers

The original GalaxyPoint initializer assigned stored values and supplied a default revealAt. Every current generator call explicitly supplies revealAt, including nonzero values. The branch removes the redundant initializer but retains `let revealAt: Double`, so memberwise initialization preserves those values.

Changing it to `let revealAt: Double = 0` is not equivalent: it fixes that constant at zero and does not preserve the existing adjustable reveal thresholds.

GalaxyBodyView's initializer remains because it initializes `_orbitAngle` from `galaxyBody.startingAngle`. State's initial value seeds a View identity; it does not continuously synchronize with changed inputs.

Reference: [Swift Initialization](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/initialization/).

### Constants, unused code, and haptics

The branch centralizes actual app/widget sparkle symbol uses in UniverseSymbols and removes the unused GalaxyOrbitModifier after checking references. It does not broadly merge unrelated font sizes, opacities, or spacing.

The existing HapticManager is a shared UIKit utility. Environment injection is an option when useful for scoping or replacement; SwiftUI does not universally require replacing all shared utilities with environment objects. That conversion was not performed merely to demonstrate a pattern.

### Reliability and requested product changes

- Database opening no longer calls fatalError. A failure keeps the original store untouched and offers retry; it does not silently substitute temporary storage.
- Main saving paths report failure and stop success-only navigation, completion events, widget updates, and reminder changes. Context rollback is used on failed shared-context saves; UI editing drafts remain separate.
- Reflection text is local until completion. Failed saving preserves the draft; unfinished text can be explicitly discarded.
- Settings allow title and galaxy-style editing for the current challenge and challenges opened from My Universe. Dates, duration, progress, and reflections remain unchanged. Successful active-challenge edits refresh the widget/reminder data.
- Growth/completion lighting is brighter. Backgrounds gain occasional decorative meteors, satellites, and stations, separate from challenge events. They pass touches through and stop ambient animation with Reduce Motion or inactive scenes.

These are changes on a separate review branch, not merged or released behavior. Notification permission/scheduling failures and widget snapshot failures still have diagnostic-only paths; this branch is not a complete recovery audit of every subsystem. A permanently damaged database may still need support or a deliberate future recovery feature; retry does not claim to repair it.

## 12. Practical checklist

- Name constants according to meaning; share only deliberate common decisions.
- Keep declarations close to their owner until broader reuse is justified.
- Use modifiers for coherent styling and Views for meaningful structure.
- Distinguish shared values, shared objects, observation, and persistence.
- Give tests a clear dependency-replacement point.
- Choose initializer or environment injection according to access needs.
- Check initializer behavior and callers before removing it.
- Show recoverable errors and avoid success effects after failure.
- Decide architecture early enough to guide work, then refine it with evidence.
- Keep domain rules authoritative and editing drafts intentional.
