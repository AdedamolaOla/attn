# Priority Card implementation

Source: Figma node 74:1326, PriorityCard/Default.
User decisions: San Francisco throughout; placeholder logos allowed; the outer card tone follows the logo/brand, not urgency.

## Implemented
- Reusable generic logo slot and explicit brand palette.
- 12pt outer padding, 28pt outer radius, 24pt inner radius, 16pt inner padding, 14pt logo/text gap, 64pt logo.
- Exact inner-panel, timing and tertiary text colours from the reference, exposed through existing AttnColors.
- Actions live below the dark panel on the coloured outer surface.
- Native buttons, context menu and overflow Menu; host-owned callbacks and review state.
- Dynamic Type, text wrapping and vertical fallback for accessibility sizes/action overflow.
- Sample gallery replaces the foundations screen. It does not claim Gmail is connected.

## Deliberate differences and remaining visual QA
- SF replaces Inter and Inter Tight by user request.
- Buttons are at least 44pt tall instead of the approximately 36pt reference. This increases card height.
- Placeholder initials replace the RBC image. The supplied palette demonstrates logo-driven colour; automatic colour extraction is not implemented.
- Native ellipsis replaces the equivalent three-dot glyph.
- Native inner shadows reproduce the outer edge treatment. The exported decorative glow ellipses are not included in this pass; the outer surface is a solid brand tone.
- Immediate is source-based. Upcoming, needs-review and undo-review treatments are provisional extensions for review.
- No fixed card height or title truncation; content can grow.

## Verification on a Mac
1. Pull phase-3-component-library and run the attn scheme.
2. Compare the first card with Figma at a 362pt card width.
3. Check light/dark appearance, 320pt width, landscape and largest accessibility text.
4. Test VoiceOver reading order: meaning, timing, sender, review, Gmail, more actions.
5. Confirm review/undo changes the label without implying a payment was made.
6. Confirm Gmail, snooze and feedback explain they are preview-only.
7. Check brand tones remain unchanged when review status changes.

No Swift compiler or Xcode is available in the authoring environment. Compilation and simulator visual verification remain pending.
