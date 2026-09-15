# Home header correction
Source: Figma 108:3829 and designer's explicit correction.

- Replaces the earlier Today navigation title and summary with Needs attn., SF 28pt bold.
- Date is current local day, formatted EEEE, MMMM d; a minute timeline refreshes it across midnight.
- Date: 14pt medium, #B7B7B7. Profile: untinted regular Liquid Glass person button, 50pt, with a near-black symbol. The pale translucent surface and system glass edge follow the designer’s close-up; the previous dark tint was a misinterpretation. Title-to-date gap: fixed 8pt (AttnSpacing.compact).
- Screen insets: 20pt horizontal, 16pt vertical. Header-to-tabs gap: 32pt.
- Tabs: 56pt base height, #FCFCFC capsule, 4pt horizontal inset.
- Selected: white capsule, #007AFF bold text; black 8% shadow, x 1, y 2, radius 16, per latest user specification.
- Unselected: #8E8E93 medium text, transparent background.
- Native SwiftUI buttons with selected accessibility traits replace the system Picker to support the specified appearance. Selection moves over 200ms and respects Reduce Motion.
- Larger accessibility text can grow the control beyond 56pt.
- Profile currently opens an explicit preview notice. No account integration is implied.
- Priority cards and their 42% corner highlights are unchanged.

Source reviewed for requested values and host call-site compatibility. Xcode/simulator visual verification remains pending; no claim of pixel-perfect rendering.
