import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/post.dart';
import '../../../providers/fullscreen.dart';
import '../../../providers/settings/blur_explicit_post.dart';
import '../../utils/extensions/buildcontext.dart';
import '../../utils/extensions/number.dart';
import 'post_explicit_warning.dart';
import 'post_placeholder_image.dart';

class PostImageDisplay extends HookConsumerWidget {
  const PostImageDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blurExplicitPost = ref.watch(blurExplicitPostProvider);
    final zoomController =
        useAnimationController(duration: const Duration(milliseconds: 150));
    final zoomAnimation = useState<Animation<double>?>(null);
    final zoomStateCallback = useState<VoidCallback?>(null);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        ref.read(fullscreenProvider.notifier).toggle();
      },
      child: PostImageBlurExplicitView(
        post: post,
        shouldBlur: blurExplicitPost,
        children: ExtendedImage.network(
          post.contentFile,
          fit: BoxFit.contain,
          mode: ExtendedImageMode.gesture,
          initGestureConfigHandler: (state) => GestureConfig(inPageView: true),
          handleLoadingProgress: true,
          loadStateChanged: (state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                return PostImageLoadingView(
                  post: post,
                  state: state,
                  shouldBlur: blurExplicitPost,
                );
              case LoadState.failed:
                return PostImageFailedView(
                  post: post,
                  state: state,
                  shouldBlur: blurExplicitPost,
                );
              default:
                return state.completedWidget;
            }
          },
          onDoubleTap: (state) {
            final downOffset = state.pointerDownPosition;
            final begin = state.gestureDetails?.totalScale ?? 1;
            zoomAnimation.value?.removeListener(zoomStateCallback.value!);

            zoomController.stop();
            zoomController.reset();

            zoomStateCallback.value = () {
              state.handleDoubleTap(
                  scale: zoomAnimation.value?.value,
                  doubleTapPosition: downOffset);
            };
            zoomAnimation.value = zoomController
                .drive(Tween<double>(begin: begin, end: begin == 1 ? 2 : 1));
            zoomAnimation.value?.addListener(zoomStateCallback.value!);
            zoomController.forward();
          },
        ),
      ),
    );
  }
}

class PostImageBlurExplicitView extends HookWidget {
  const PostImageBlurExplicitView({
    super.key,
    required this.post,
    required this.shouldBlur,
    required this.children,
  });

  final Post post;
  final bool shouldBlur;
  final Widget children;

  @override
  Widget build(BuildContext context) {
    final isBlur = useState(post.rating == PostRating.explicit && shouldBlur);
    return isBlur.value
        ? Stack(
            alignment: Alignment.center,
            fit: StackFit.passthrough,
            children: [
              AspectRatio(
                aspectRatio: post.aspectRatio,
                child: PostPlaceholderImage(
                  url: post.previewFile,
                  shouldBlur: true,
                ),
              ),
              Center(
                child: PostExplicitWarningCard(onConfirm: () {
                  isBlur.value = false;
                }),
              ),
            ],
          )
        : children;
  }
}

class PostImageFailedView extends StatelessWidget {
  const PostImageFailedView({
    super.key,
    required this.post,
    required this.state,
    required this.shouldBlur,
  });

  final Post post;
  final ExtendedImageState state;
  final bool shouldBlur;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      fit: StackFit.passthrough,
      children: [
        PostPlaceholderImage(
          url: post.previewFile,
          shouldBlur: shouldBlur && post.rating == PostRating.explicit,
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom,
          child: Transform.scale(
            scale: 0.9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                color: context.theme.cardColor,
              ),
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: Text('Failed to load image'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(elevation: 0),
                    onPressed: state.reLoadImage,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PostImageLoadingView extends StatelessWidget {
  const PostImageLoadingView({
    super.key,
    required this.post,
    required this.state,
    this.shouldBlur = false,
  });

  final Post post;
  final ExtendedImageState state;
  final bool shouldBlur;

  @override
  Widget build(BuildContext context) {
    final progressPercentage = state.loadingProgress?.progressPercentage ?? 0;
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.passthrough,
      children: [
        PostPlaceholderImage(
          url: post.previewFile,
          shouldBlur: shouldBlur && post.rating == PostRating.explicit,
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              color: context.theme.cardColor,
            ),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    color: context.theme.colorScheme.background,
                  ),
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(2),
                  child: SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation(
                        Colors.white54,
                      ),
                      value: state.loadingProgress?.progressRatio,
                    ),
                  ),
                ),
                if (progressPercentage > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 12),
                    child: Text(
                      '$progressPercentage%',
                      style: context.theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
