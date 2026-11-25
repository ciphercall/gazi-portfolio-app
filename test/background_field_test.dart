import 'package:flutter_test/flutter_test.dart';
import 'package:gazi_portfolio_app/widgets/background_field.dart';

void main() {
  test('every silhouette shares the same ring length', () {
    expect(kShapeRings, hasLength(8));
    for (final ring in kShapeRings) {
      expect(ring, hasLength(kRingPoints));
      for (final point in ring) {
        expect(point.dx.isFinite && point.dy.isFinite, isTrue);
      }
    }
  });

  test('the icon is visible in the hold and gone mid-morph', () {
    expect(iconAlpha(0, 0), 1);
    expect(iconAlpha(kHoldMs - 1, 0), 1);

    final fading = iconAlpha(kHoldMs + kMorphMs * 0.1, 0);
    expect(fading, greaterThan(0));
    expect(fading, lessThan(0.9));

    expect(iconAlpha(kHoldMs + kMorphMs * 0.5, 0), 0);
    expect(iconAlpha(kHoldMs + kMorphMs * 0.95, 0), greaterThan(0.8));
    expect(iconAlpha(kCycleMs - 0.001, 0), closeTo(1, 0.01));
    expect(iconAlpha(kCycleMs + 500, 0), 1);
  });

  test('the destination icon takes over in the second half of a morph', () {
    final early = morphState(kHoldMs + kMorphMs * 0.2, 0, 0);
    final late = morphState(kHoldMs + kMorphMs * 0.9, 0, 0);

    expect(iconShapeIndex(early), early.from);
    expect(iconShapeIndex(late), late.to);
  });

  test('detail artwork stays inside the silhouette box', () {
    expect(kShapeDetails, hasLength(kShapeRings.length));

    for (final marks in kShapeDetails) {
      for (final mark in marks) {
        final ellipse = mark.ellipse;
        if (ellipse != null) {
          for (final value in [ellipse.left, ellipse.right, ellipse.top, ellipse.bottom]) {
            expect(value.abs(), lessThan(0.6));
          }
        }
        for (final point in mark.points) {
          expect(point.dx.abs(), lessThan(0.6));
          expect(point.dy.abs(), lessThan(0.6));
        }
      }
    }
  });
}
