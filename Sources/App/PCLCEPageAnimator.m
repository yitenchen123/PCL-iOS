#import "PCLCEPageAnimator.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static CGFloat PCLClamp(CGFloat value) {
    return MIN(MAX(value, 0.0), 1.0);
}

static CGFloat PCLOutFluent(CGFloat t, CGFloat power) {
    t = PCLClamp(t);
    return 1.0 - pow(1.0 - t, power);
}

static CGFloat PCLInFluent(CGFloat t, CGFloat power) {
    t = PCLClamp(t);
    return pow(t, power);
}

static CGFloat PCLOutBack(CGFloat t, CGFloat power) {
    t = PCLClamp(t);

    CGFloat p =
        3.0 - power * 0.5;

    return 1.0
        - pow(1.0 - t, p)
        * cos(1.5 * M_PI * t);
}

static NSArray<NSNumber *> *PCLSamples(
    NSUInteger count,
    CGFloat (^function)(CGFloat)) {

    NSMutableArray *values =
        [NSMutableArray arrayWithCapacity:count];

    for (NSUInteger i = 0; i < count; i++) {
        CGFloat t =
            (CGFloat)i / (CGFloat)(count - 1);

        [values addObject:
            @(function(t))];
    }

    return values;
}

static void PCLAnimateLayer(
    CALayer *layer,
    NSString *keyPath,
    NSArray<NSNumber *> *values,
    NSTimeInterval duration,
    NSTimeInterval delay) {

    CAKeyframeAnimation *animation =
        [CAKeyframeAnimation
            animationWithKeyPath:keyPath];

    animation.values = values;
    animation.duration = duration;

    animation.beginTime =
        CACurrentMediaTime() + delay;

    animation.fillMode =
        kCAFillModeBackwards;

    animation.removedOnCompletion = YES;

    [layer addAnimation:animation
                 forKey:keyPath];
}

static CGFloat PCLLayerScale(CALayer *layer) {
    CATransform3D t=layer.transform;

    CGFloat scale=hypot(t.m11,t.m12);

    return scale>0.001 ? scale : 1.0;
}

@implementation PCLCEPageAnimator

+ (void)hideSimpleLeftPage:(UIView *)view {

    CALayer *layer=view.layer;

    CALayer *shown=

        (CALayer *)layer.presentationLayer;

    CGFloat fromScale=

        PCLLayerScale(shown ?: layer);

    fromScale=MIN(1.0,MAX(.95,fromScale));

    CGFloat fromOpacity=

        shown ? shown.opacity : layer.opacity;

    fromOpacity=

        MIN(1.0,MAX(0.0,fromOpacity));

    [layer removeAllAnimations];

    [CATransaction begin];

    [CATransaction setDisableActions:YES];

    layer.transform=

        CATransform3DMakeScale(.95,.95,1);

    layer.opacity=0;

    [CATransaction commit];
    NSMutableArray *values=

        NSMutableArray.array;

    for (NSInteger i=0;i<=60;i++) {

        CGFloat t=i/60.0;

        CGFloat eased=PCLInFluent(t,2.0);

        CGFloat scale=

            fromScale+

            (.95-fromScale)*eased;

        [values addObject:@(scale)];

    }

    PCLAnimateLayer(

        layer,

        @"transform.scale",

        values,

        .110,

        0);

    PCLAnimateLayer(

        layer,

        @"opacity",

        @[@(fromOpacity),@0],

        .080,

        .030);

}

+ (void)showSimpleLeftPage:(UIView *)view {

    [view.layer removeAllAnimations];

    [CATransaction begin];

    [CATransaction setDisableActions:YES];

    view.layer.transform=

        CATransform3DIdentity;

    view.layer.opacity=1.0;

    [CATransaction commit];

    NSMutableArray *values=

        NSMutableArray.array;

    for (NSInteger i=0;i<=120;i++) {

        CGFloat t=i/120.0;

        CGFloat scale=

            .96+

            .04*PCLOutBack(t,2.0);

        [values addObject:@(scale)];

    }
    PCLAnimateLayer(

        view.layer,

        @"transform.scale",

        values,

        .400,

        0);

    PCLAnimateLayer(

        view.layer,

        @"opacity",

        @[@0,@1],

        .100,

        0);

}

+ (void)showLeftItems:(NSArray<UIView *> *)items {
    NSTimeInterval delay = 0.0;
    NSInteger index = 0;

    for (UIView *view in items) {
        [view.layer removeAllAnimations];

        CGFloat targetOpacity =
            view.alpha;

        NSMutableArray *xValues =
            [NSMutableArray array];

        for (NSInteger i = 0; i <= 120; i++) {
            CGFloat seconds =
                0.300 * i / 120.0;

            CGFloat first =
                5.0 * PCLOutFluent(
                    seconds / 0.200,
                    3.0);

            CGFloat second =
                20.0 * PCLOutBack(
                    seconds / 0.300,
                    2.0);

            [xValues addObject:
                @(-25.0 + first + second)];
        }

        NSMutableArray *opacityValues =
            [NSMutableArray array];

        for (NSInteger i = 0; i <= 40; i++) {
            CGFloat t = i / 40.0;

            [opacityValues addObject:
                @(targetOpacity
                  * PCLOutFluent(t, 2.0))];
        }

        [view.layer setValue:@0
                 forKeyPath:@"transform.translation.x"];

        view.layer.opacity =
            targetOpacity;

        PCLAnimateLayer(
            view.layer,
            @"transform.translation.x",
            xValues,
            0.300,
            delay);

        PCLAnimateLayer(
            view.layer,
            @"opacity",
            opacityValues,
            0.100,
            delay);

        NSInteger delta =
            MAX(15 - index, 7) * 2;

        delay += delta / 1000.0;
        index++;
    }
}

+ (void)hideLeftItems:(NSArray<UIView *> *)items {
    if (!items.count)
        return;

    for (NSUInteger i = 0;
         i < items.count;
         i++) {

        UIView *view = items[i];

        NSTimeInterval delay =
            (0.070 / items.count) * i;

        CGFloat startOpacity =
            view.layer.opacity;

        view.layer.opacity = 0.0;

        [view.layer setValue:@(-6.0)
                 forKeyPath:@"transform.translation.x"];

        PCLAnimateLayer(
            view.layer,
            @"opacity",
            @[@(startOpacity), @0.0],
            0.050,
            delay);

        PCLAnimateLayer(
            view.layer,
            @"transform.translation.x",
            @[@0.0, @(-6.0)],
            0.050,
            delay);
    }
}

+ (void)showRightItems:(NSArray<UIView *> *)items
            scrollView:(UIScrollView *)scrollView {

    NSTimeInterval delay = 0.0;

    for (UIView *view in items) {
        [view.layer removeAllAnimations];

        CGFloat targetOpacity =
            view.alpha;

        NSMutableArray *yValues =
            [NSMutableArray array];

        for (NSInteger i = 0; i <= 140; i++) {
            CGFloat seconds =
                0.350 * i / 140.0;

            CGFloat first =
                5.0 * PCLOutFluent(
                    seconds / 0.250,
                    3.0);

            CGFloat second =
                11.0 * PCLOutBack(
                    seconds / 0.350,
                    3.0);

            [yValues addObject:
                @(-16.0 + first + second)];
        }

        NSMutableArray *opacityValues =
            [NSMutableArray array];

        for (NSInteger i = 0; i <= 40; i++) {
            CGFloat t = i / 40.0;

            [opacityValues addObject:
                @(targetOpacity
                  * PCLOutFluent(t, 2.0))];
        }

        [view.layer setValue:@0
                 forKeyPath:@"transform.translation.y"];

        view.layer.opacity =
            targetOpacity;

        PCLAnimateLayer(
            view.layer,
            @"transform.translation.y",
            yValues,
            0.350,
            delay);

        PCLAnimateLayer(
            view.layer,
            @"opacity",
            opacityValues,
            0.100,
            delay);

        delay += 0.025;
    }

    if (scrollView) {
        NSMutableArray *xValues =
            [NSMutableArray array];

        for (NSInteger i = 0; i <= 120; i++) {
            CGFloat t = i / 120.0;

            CGFloat x =
                10.0
                * (1.0
                   - PCLOutFluent(t, 3.0));

            [xValues addObject:@(x)];
        }

        [scrollView.layer setValue:@0
                       forKeyPath:@"transform.translation.x"];

        PCLAnimateLayer(
            scrollView.layer,
            @"transform.translation.x",
            xValues,
            0.350,
            0.0);
    }
}

+ (void)hideRightItems:(NSArray<UIView *> *)items
            scrollView:(UIScrollView *)scrollView {

    NSTimeInterval delay = 0.0;

    for (UIView *view in items) {
        CGFloat opacity =
            view.layer.opacity;

        view.layer.opacity = 0.0;

        [view.layer setValue:@(-6.0)
                 forKeyPath:@"transform.translation.y"];

        PCLAnimateLayer(
            view.layer,
            @"opacity",
            @[@(opacity), @0.0],
            0.070,
            delay);

        PCLAnimateLayer(
            view.layer,
            @"transform.translation.y",
            @[@0.0, @(-6.0)],
            0.070,
            delay);

        delay += 0.015;
    }

    if (scrollView) {
        NSMutableArray *xValues =
            [NSMutableArray array];

        for (NSInteger i = 0; i <= 40; i++) {
            CGFloat t = i / 40.0;

            [xValues addObject:
                @(10.0
                  * PCLInFluent(t, 3.0))];
        }

        [scrollView.layer setValue:@10.0
                       forKeyPath:@"transform.translation.x"];

        PCLAnimateLayer(
            scrollView.layer,
            @"transform.translation.x",
            xValues,
            0.090,
            0.0);
    }
}

@end
