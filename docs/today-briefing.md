# Today briefing header

Implements sections 12–13 of the ATTN brief with San Francisco, a native large navigation title, a wrapping semantic-body summary and a native segmented Picker.

TodayBriefingHeader accepts host-provided summary text and a binding to TodaySection. It does not generate summaries or access Gmail.

The app's existing sample showcase now presents Today. Immediate displays payment, flight check-in and the uncertain appointment. Upcoming displays the interview. The daily summary stays stable across selections; review state survives segment changes and does not imply external resolution. Switching uses the same scroll container and navigation screen without adding custom animation.

Header previews cover the normal briefing, zero priorities, one priority and accessibility text. Sample cards retain their brand tones and 42% white highlights. The sample-data disclosure remains visible below the cards.

Validation: reviewed the source changes for native control use, enum selection, text wrapping, preserved callbacks and sample grouping. Xcode and simulator are unavailable here. On Mac, verify title collapse, Immediate/Upcoming switching, review state across switches, dark mode, VoiceOver and accessibility text sizes. No live Gmail or AI analysis is implemented in this phase.
