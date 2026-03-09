import 'package:flutter/material.dart';
import 'drama_manager.dart'; 
import '../models/player.dart';

// ─────────────────────────────────────────────
// DRAMA DIALOG — full-screen animated popup
// ─────────────────────────────────────────────

class DramaDialog extends StatefulWidget {
  final DramaEvent event;
  final Player player;
  final bool hasGirlfriend;
  final VoidCallback onDismiss;

  const DramaDialog({
    super.key,
    required this.event,
    required this.player,
    required this.hasGirlfriend,
    required this.onDismiss,
  });

  /// Show the drama dialog as a route overlay.
  static Future<void> show(
    BuildContext context, {
    required DramaEvent event,
    required Player player,
    required bool hasGirlfriend,
    required VoidCallback onDismiss,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => DramaDialog(
        event: event,
        player: player,
        hasGirlfriend: hasGirlfriend,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<DramaDialog> createState() => _DramaDialogState();
}

class _DramaDialogState extends State<DramaDialog>
    with SingleTickerProviderStateMixin {

  // ── State ──────────────────────────────────
  DramaChoice? _chosenChoice;
  bool _showOutcome = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Init ───────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Color helper ───────────────────────────
  Color _typeColor() {
    try {
      final hex = widget.event.dramaColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF5B4CDD);
    }
  }

  // ── Effect chip ────────────────────────────
  Widget _effectChip(String label, int value) {
    final positive = value > 0;
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: positive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: positive
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        '${positive ? '+' : ''}$value $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: positive ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
  }

  List<Widget> _buildEffectChips(DramaEffect e) {
    final chips = <Widget>[];
    void add(String label, int v) {
      if (v != 0) chips.add(_effectChip(label, v));
    }
    add('😊', e.happiness);
    add('🧠', e.smarts);
    add('✨', e.looks);
    add('💰', e.money);
    add('⭐', e.reputation);
    add('👨‍👩‍👦', e.relationshipParents);
    add('💕', e.relationshipGirlfriend);
    add('❤️', e.health);
    return chips;
  }

  // ── Choice card ────────────────────────────
  Widget _choiceCard(DramaChoice choice, int index) {
    final color = _typeColor();
    final isSelected = _chosenChoice == choice;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)]
            : [const BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onChoiceTap(choice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        choice.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Outcome view ───────────────────────────
  Widget _outcomeView() {
    final choice = _chosenChoice!;
    final color = _typeColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Outcome icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🎭', style: TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 12),
        Text(
          'Nəticə',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            choice.outcome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Effect chips
        if (_buildEffectChips(choice.effects).isNotEmpty) ...[
          const Text(
            'Təsir',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(children: _buildEffectChips(choice.effects)),
          const SizedBox(height: 16),
        ],

        // Continue button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Davam et',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ────────────────────────────────
  void _onChoiceTap(DramaChoice choice) {
    setState(() {
      _chosenChoice = choice;
      _showOutcome = true;
    });

    // Apply effects to player immediately
    DramaManager().applyChoice(
      choice: choice,
      player: widget.player,
    );
  }

  void _onContinue() {
    Navigator.of(context).pop();
    widget.onDismiss();
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final color = _typeColor();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ScaleTransition(
            scale: _pulseAnim,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Header band ────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(event.dramaEmoji,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.dramaLabel.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // NPC badge
                        Column(
                          children: [
                            Text(event.npcEmoji,
                                style: const TextStyle(fontSize: 22)),
                            Text(
                              event.npcName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Body ──────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showOutcome
                          ? _outcomeView()
                          : _scenarioView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scenarioView() {
    final event = widget.event;
    final color = _typeColor();

    return Column(
      key: const ValueKey('scenario'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            event.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Choices label
        Text(
          'Reaksiyanı seç',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Choice list
        ...event.choices.asMap().entries.map(
              (entry) => _choiceCard(entry.value, entry.key),
            ),
      ],
    );
  }
}
