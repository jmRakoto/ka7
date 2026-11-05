import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fades and slides [child] in once, the first time it is built; the
/// [index]-th of a list comes in a little after the one before it.
class Appear extends StatefulWidget {
  const Appear({super.key, this.index = 0, required this.child});

  final int index;
  final Widget child;

  @override
  State<Appear> createState() => _AppearState();
}

/// When the page holding them was first shown (frame time): items built
/// well after that (scrolled to) come at once, never blank.
class AppearClock extends InheritedWidget {
  const AppearClock({super.key, required this.since, required super.child});

  final Duration since;

  static Duration? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearClock>()?.since;

  @override
  bool updateShouldNotify(AppearClock old) => old.since != since;
}

/// After this, a page is settled: no more entrances.
const _settle = Duration(milliseconds: 600);

/// Past this rank, items come in together: a long list is not a slideshow.
const _maxStagger = 8;
const _step = Duration(milliseconds: 45);
const _length = Duration(milliseconds: 320);

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _in;
  late final Animation<double> _shown;

  @override
  void initState() {
    super.initState();
    final delay = _step * widget.index.clamp(0, _maxStagger);
    final total = delay + _length;
    _in = AnimationController(vsync: this, duration: total);
    _shown = CurvedAnimation(
      parent: _in,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_in.status != AnimationStatus.dismissed) return;
    final since = AppearClock.of(context);
    final settled =
        since != null &&
        SchedulerBinding.instance.currentFrameTimeStamp - since > _settle;
    if (settled || MediaQuery.disableAnimationsOf(context)) {
      _in.value = 1;
    } else {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _shown,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(_shown),
      child: widget.child,
    ),
  );
}
