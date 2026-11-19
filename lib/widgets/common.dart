import 'package:flutter/material.dart';

import '../screens/data_screens.dart';
import '../theme.dart';

void go(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

void replaceWith(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> confirm(BuildContext context, String title, String body, {String ok = 'ยืนยัน', bool danger = false}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: TS.h3),
      content: Text(body, style: TS.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: danger ? AppColors.red : AppColors.green),
          child: Text(ok),
        ),
      ],
    ),
  );
  return res ?? false;
}

class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

enum Tone { green, amber, red, blue, grey }

class ToneColors {
  final Color bg;
  final Color fg;
  const ToneColors(this.bg, this.fg);
}

ToneColors toneColors(Tone t) => switch (t) {
      Tone.green => const ToneColors(AppColors.light, AppColors.green),
      Tone.amber => const ToneColors(AppColors.amberBg, AppColors.amber),
      Tone.red => const ToneColors(AppColors.redBg, AppColors.red),
      Tone.blue => const ToneColors(AppColors.blueBg, AppColors.blue),
      Tone.grey => const ToneColors(AppColors.grey, AppColors.muted),
    };

/// Softer background + darker text, for info boxes.
ToneColors softTone(Tone t) => switch (t) {
      Tone.green => const ToneColors(AppColors.light, AppColors.dark),
      Tone.amber => const ToneColors(AppColors.amberSoft, AppColors.amberText),
      Tone.red => const ToneColors(AppColors.redBg, AppColors.red),
      Tone.blue => const ToneColors(AppColors.blueBg, AppColors.blue),
      Tone.grey => const ToneColors(AppColors.grey, AppColors.muted),
    };

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.tone = Tone.green, this.small = false, this.icon});
  final String text;
  final Tone tone;
  final bool small;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = toneColors(tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 14, color: c.fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w600, color: c.fg)),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = AppColors.line,
    this.borderWidth = 1,
    this.radius = 16,
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  const IconCircle(this.icon, {super.key, this.tone = Tone.green, this.size = 40});
  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = toneColors(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
      child: Icon(icon, color: c.fg, size: size * 0.5),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.top = 20});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TS.h3)),
          if (action != null)
            GestureDetector(onTap: onAction, child: Text(action!, style: TS.link)),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(text, style: TS.label));
}

class ListRowCard extends StatelessWidget {
  const ListRowCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tone = Tone.green,
    this.margin = const EdgeInsets.only(bottom: 10),
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Tone tone;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconCircle(icon, tone: tone),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TS.title.copyWith(fontSize: 15)),
                if (subtitle != null) ...[const Gap(2), Text(subtitle!, style: TS.small)],
              ],
            ),
          ),
          const Gap(8),
          trailing ?? const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

class ValueTile extends StatelessWidget {
  const ValueTile({super.key, required this.label, required this.value, this.status, this.note, this.icon, this.onTap});
  final String label;
  final String value;
  final Widget? status;
  final String? note;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 12,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: AppColors.green), const Gap(6)],
              Expanded(child: Text(label, style: TS.small)),
              if (status != null) status!,
            ],
          ),
          const Gap(6),
          Text(value, style: TS.value),
          if (note != null) ...[const Gap(2), Text(note!, style: TS.tiny)],
        ],
      ),
    );
  }
}

/// Lays children out two per row with equal heights.
class TwoCol extends StatelessWidget {
  const TwoCol({super.key, required this.children, this.gap = 10});
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: children[i]),
                  SizedBox(width: gap),
                  Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.title, this.body, this.tone = Tone.amber, this.icon, this.margin = const EdgeInsets.only(top: 12)});
  final String title;
  final String? body;
  final Tone tone;
  final IconData? icon;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final c = softTone(tone);
    return Padding(
      padding: margin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: c.fg), const Gap(10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TS.title.copyWith(color: c.fg)),
                  if (body != null) ...[const Gap(4), Text(body!, style: TS.small.copyWith(color: c.fg))],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DarkCard extends StatelessWidget {
  const DarkCard({super.key, required this.title, required this.lines, this.footer, this.action, this.icon = Icons.auto_awesome});
  final String title;
  final List<String> lines;
  final String? footer;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.darkText, size: 20),
            const Gap(8),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
          const Gap(10),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l, style: const TextStyle(color: AppColors.darkText, fontSize: 13, height: 1.45)),
            ),
          if (footer != null) ...[
            const Gap(4),
            Text(footer!, style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
          ],
          if (action != null) ...[const Gap(12), action!],
        ],
      ),
    );
  }
}

class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.selected, required this.onChanged});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == selected ? AppColors.line : Colors.transparent),
                  ),
                  child: Text(
                    options[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: i == selected ? FontWeight.w700 : FontWeight.w600,
                      color: i == selected ? AppColors.green : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontally scrollable filter chips.
class ChipBar extends StatelessWidget {
  const ChipBar({super.key, required this.options, required this.selected, required this.onChanged});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.light : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == selected ? AppColors.green : AppColors.line),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: i == selected ? AppColors.green : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class KVRow extends StatelessWidget {
  const KVRow(this.label, this.value, {super.key, this.valueColor = AppColors.ink, this.divider = true});
  final String label;
  final String value;
  final Color valueColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider ? const Border(bottom: BorderSide(color: AppColors.line)) : null,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TS.body.copyWith(color: AppColors.muted))),
          const Gap(8),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TS.body.copyWith(fontWeight: FontWeight.w700, color: valueColor)),
          ),
        ],
      ),
    );
  }
}

class NumberedRow extends StatelessWidget {
  const NumberedRow({super.key, required this.n, required this.title, this.subtitle, this.trailing, this.onTap});
  final int n;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      radius: 12,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.light, shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.green)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TS.title),
                if (subtitle != null) ...[const Gap(2), Text(subtitle!, style: TS.tiny)],
              ],
            ),
          ),
          if (trailing != null) ...[const Gap(8), trailing!],
        ],
      ),
    );
  }
}

class Bar extends StatelessWidget {
  const Bar(this.value, {super.key, this.color = AppColors.green, this.height = 8});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value < 0 ? 0.0 : (value > 1 ? 1.0 : value),
        minHeight: height,
        color: color,
        backgroundColor: const Color(0xFFE2E7E3),
      ),
    );
  }
}

class ToggleCard extends StatelessWidget {
  const ToggleCard({super.key, required this.title, this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 12,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TS.title),
                if (subtitle != null) ...[const Gap(2), Text(subtitle!, style: TS.tiny)],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: AppColors.green),
        ],
      ),
    );
  }
}

/// A read-only "select" field that opens a bottom sheet of options.
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.value, required this.options, required this.onChanged, this.icon});
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final o in options)
                  ListTile(
                    title: Text(o),
                    trailing: o == value ? const Icon(Icons.check, color: AppColors.green) : null,
                    onTap: () => Navigator.pop(ctx, o),
                  ),
                const Gap(8),
              ],
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: AppColors.green, size: 20), const Gap(10)],
          Expanded(child: Text(value, style: TS.title.copyWith(fontSize: 15))),
          const Icon(Icons.expand_more, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Standard page: app bar (+ optional step pill / bell) and a scrolling body,
/// with an optional sticky bottom area for primary actions.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.children,
    this.step,
    this.bell = false,
    this.bottom,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
  });

  final String title;
  final List<Widget> children;
  final String? step;
  final bool bell;
  final Widget? bottom;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (step != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Pill(step!, tone: Tone.grey)),
            ),
          if (bell) const BellButton(),
          ...?actions,
        ],
      ),
      body: ListView(padding: padding, children: children),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: bottom,
              ),
            ),
    );
  }
}

class BellButton extends StatelessWidget {
  const BellButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: 'การแจ้งเตือน',
        onPressed: () => go(context, const NotificationsScreen()),
        icon: const Badge(smallSize: 8, child: Icon(Icons.notifications_none_rounded)),
      ),
    );
  }
}

/// Column of stacked full-width buttons for the sticky bottom area.
class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Gap(8),
          children[i],
        ],
      ],
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed, this.icon = Icons.delete_outline});
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.red,
        side: const BorderSide(color: Color(0xFFE9B8B4)),
      ),
    );
  }
}

/// Grey note used whenever N-P-K appears: estimate only, not calibrated.
class NpkCard extends StatelessWidget {
  const NpkCard({super.key, this.n = 42, this.p = 18, this.k = 56, this.note = 'ใช้ดูแนวโน้มเท่านั้น ยังไม่ใช้ตีความธาตุอาหาร'});
  final int n, p, k;
  final String note;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFAFBFA),
      radius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Text('N / P / K (ค่าประมาณ)', style: TS.label)),
            const Pill('ยังไม่สอบเทียบ', tone: Tone.grey, small: true),
          ]),
          const Gap(6),
          Text('$n • $p • $k mg/kg', style: TS.value.copyWith(fontSize: 17, color: const Color(0xFF4A544F))),
          const Gap(2),
          Text(note, style: TS.tiny),
        ],
      ),
    );
  }
}
