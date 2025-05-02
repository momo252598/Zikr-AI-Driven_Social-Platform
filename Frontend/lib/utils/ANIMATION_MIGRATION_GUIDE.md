# Animation Controller Migration Guide

This guide will help you resolve the following error that occurs sporadically in the app:

```
Exception has occurred.
_AssertionError ('package:flutter/src/animation/animation_controller.dart': Failed assertion: line 904 pos 12: 'elapsedInSeconds >= 0.0': is not true.)
elapsedInSeconds=-0.008333
```

## The Problem

This error occurs when Flutter's `AnimationController` receives a negative elapsed time value, which violates an internal assertion. This typically happens:

- During rapid user interactions
- When there's heavy processing alongside animations
- When multiple animations are running simultaneously
- When making frequent backend requests (like your tracking progress feature)

## The Solution

We've created a `SafeAnimationController` that properly handles negative elapsed times, preventing the app from crashing. Here's how to use it throughout your app:

## Migration Options

### Option 1: Use the helper functions (Recommended)

This approach is the simplest:

```dart
// BEFORE:
final AnimationController controller = AnimationController(
  duration: Duration(milliseconds: 500),
  vsync: this,
);

// AFTER:
// Import
import 'package:your_app/utils/safe_animation_controller.dart';

// Keep the type as AnimationController, only change the initialization
final AnimationController controller = createSafeAnimationController(
  duration: Duration(milliseconds: 500),
  vsync: this,
);
```

### Option 2: Directly use SafeAnimationController

```dart
// BEFORE:
final AnimationController controller = AnimationController(
  duration: Duration(milliseconds: 500),
  vsync: this,
);

// AFTER:
// Import
import 'package:your_app/utils/safe_animation_controller.dart';

// Change both the type and initialization
final SafeAnimationController controller = SafeAnimationController(
  duration: Duration(milliseconds: 500),
  vsync: this,
);
```

## Where to Look for AnimationController Usage

1. **Search for AnimationController instantiations:**

   ```dart
   AnimationController(
   ```

2. **Common widgets that might use AnimationController:**

   - Any class that uses `with SingleTickerProviderStateMixin` or `with TickerProviderStateMixin`
   - Custom animations
   - Transition animations
   - Loading indicators
   - Page transitions
   - The track reading progress feature you mentioned

3. **For the unbounded variant, look for:**
   ```dart
   AnimationController.unbounded(
   ```
   And replace with:
   ```dart
   createUnboundedSafeAnimationController(
   ```

## Important Note

You don't need to change any other code that uses the controller - everything will work exactly the same, but without the crashes!

## Testing Your Changes

After making these changes, test the app thoroughly, especially in areas where you were experiencing crashes before. The fix should eliminate the crashes without changing any animation behavior.

## Need More Help?

If you find instances where the migration is challenging or if you have questions, refer to the example file at `lib/utils/safe_animation_example.dart` for more guidance.

Good luck with the migration! This fix should resolve the sporadic crashes you've been experiencing.
