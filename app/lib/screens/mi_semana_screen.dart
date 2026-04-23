import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/organizador_controller.dart';
import '../models/bloque_plan.dart';
import '../models/plan_semanal.dart';
import '../widgets/cards/bloque_card.dart';
import '../widgets/day_chip.dart';
import '../widgets/empty_card.dart';
import '../widgets/mini_month_calendar.dart';
import '../widgets/section_title.dart';
import '../widgets/week_profile_header.dart';

enum _AgendaFilter { todo, habitos, eventos }

class MiSemanaScreen extends StatefulWidget {
  const MiSemanaScreen({
    super.key,
    required this.plan,
    required this.controller,
    required this.themeMode,
    required this.onThemeModeSelected,
    required this.onRescheduleBloque,
    required this.onSaveDayNote,
    required this.scrollController,
  });

  final PlanSemanal plan;
  final OrganizadorController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;
  final ValueChanged<BloquePlan> onRescheduleBloque;
  final Future<void> Function(String fecha, String nota) onSaveDayNote;
  final ScrollController scrollController;

  @override
  State<MiSemanaScreen> createState() => _MiSemanaScreenState();
}

class _MiSemanaScreenState extends State<MiSemanaScreen> {
  _AgendaFilter _filtro = _AgendaFilter.todo;

  @override
  Widget build(BuildContext context) {
    final dias = widget.plan.dias;
    final controller = widget.controller;
    final diaActivo = dias[controller.diaSeleccionado];
    final bloquesFiltrados = diaActivo.bloques.where(_coincideFiltro).toList();

    return ListView(
      key: const PageStorageKey('agenda-scroll'),
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 120),
      children: [
        WeekProfileHeader(
          themeMode: widget.themeMode,
          onThemeModeSelected: widget.onThemeModeSelected,
          tituloSemana: controller.weekOffset == 0
              ? 'Mi semana'
              : 'Semana de ${controller.mesSemanaBonito(widget.plan)}',
          rangoLabel: controller.rangoSemanaBonito(widget.plan),
          diaLabel: diaActivo.nombreDia,
          fechaLabel: controller.fechaBonita(diaActivo.fecha),
          isCurrentWeek: controller.weekOffset == 0,
          onPreviousWeek: () => controller.cambiarSemana(-1),
          onNextWeek: () => controller.cambiarSemana(1),
          onToday: controller.irASemanaActual,
        ),
        const SizedBox(height: 24),
        SectionTitle(
          title: controller.weekOffset == 0
              ? 'Agenda de la semana'
              : 'Agenda de esa semana',
          subtitle: controller.weekOffset == 0
              ? 'Tu plan diario en una vista limpia y directa.'
              : 'Ideal para revisar viajes, eventos y lo que se acerca.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dias
                .map(
                  (dia) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: DayChip(
                      dia: dia,
                      selected: dia.diaSemana == controller.diaSeleccionado,
                      onTap: () => controller.seleccionarDia(dia.diaSemana),
                      fechaBonita: controller.fechaBonita(dia.fecha),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AgendaFilters(
                filtro: _filtro,
                onChanged: (filtro) {
                  setState(() {
                    _filtro = filtro;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            _CalendarButton(
              onTap: () => _abrirCalendario(context, diaActivo),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (bloquesFiltrados.isEmpty)
          EmptyCard(
            title: _emptyTitle(controller),
            subtitle: _emptySubtitle(controller),
          )
        else
          ...bloquesFiltrados.map(
            (bloque) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BloqueCard(
                bloque: bloque,
                tipoLabel: controller.tipoLabel(bloque.tipoObjetivo),
                onDone: bloque.estado == 'pendiente' && !bloque.esFijo
                    ? () => controller.marcarBloqueHecho(bloque)
                    : null,
                onReschedule: bloque.estado == 'pendiente' && !bloque.esFijo
                    ? () => widget.onRescheduleBloque(bloque)
                    : null,
              ),
            ),
          ),
        const SizedBox(height: 10),
        _DayNoteCard(
          fecha: diaActivo.fecha,
          notaInicial: diaActivo.notaLibre ?? '',
          isSaving: controller.notasGuardando.contains(diaActivo.fecha),
          onSave: (nota) => widget.onSaveDayNote(diaActivo.fecha, nota),
        ),
      ],
    );
  }

  bool _coincideFiltro(BloquePlan bloque) {
    switch (_filtro) {
      case _AgendaFilter.todo:
        return true;
      case _AgendaFilter.habitos:
        return bloque.tipoObjetivo == 'habito';
      case _AgendaFilter.eventos:
        return bloque.tipoObjetivo == 'evento_fijo' || bloque.esFijo;
    }
  }

  String _emptyTitle(OrganizadorController controller) {
    switch (_filtro) {
      case _AgendaFilter.habitos:
        return 'No hay hábitos ese día';
      case _AgendaFilter.eventos:
        return 'No hay eventos ese día';
      case _AgendaFilter.todo:
        return controller.weekOffset == 0
            ? 'Este día está libre'
            : 'No hay nada en este día';
    }
  }

  String _emptySubtitle(OrganizadorController controller) {
    switch (_filtro) {
      case _AgendaFilter.habitos:
        return '';
      case _AgendaFilter.eventos:
        return '';
      case _AgendaFilter.todo:
        return controller.weekOffset == 0
            ? 'Cuando planifiques la semana, aquí aparecerán tus bloques.'
            : 'Puedes seguir avanzando semanas para ver eventos futuros.';
    }
  }

  Future<void> _abrirCalendario(BuildContext context, DiaPlan diaActivo) async {
    final fechaSeleccionada = DateTime.tryParse(diaActivo.fecha) ?? DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return MiniMonthCalendar(
          initialDate: fechaSeleccionada,
          selectedDate: fechaSeleccionada,
          eventos: widget.plan.eventosFijos,
          onSelectDate: (fecha) {
            Navigator.of(context).pop();
            widget.controller.irAFecha(fecha);
          },
        );
      },
    );
  }
}

class _AgendaFilters extends StatelessWidget {
  const _AgendaFilters({
    required this.filtro,
    required this.onChanged,
  });

  final _AgendaFilter filtro;
  final ValueChanged<_AgendaFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: 'Todo',
          selected: filtro == _AgendaFilter.todo,
          isDark: isDark,
          tint: palette.primary,
          onTap: () => onChanged(_AgendaFilter.todo),
        ),
        _FilterChipButton(
          label: 'Hábitos',
          selected: filtro == _AgendaFilter.habitos,
          isDark: isDark,
          tint: const Color(0xFF2FB36B),
          onTap: () => onChanged(_AgendaFilter.habitos),
        ),
        _FilterChipButton(
          label: 'Eventos',
          selected: filtro == _AgendaFilter.eventos,
          isDark: isDark,
          tint: const Color(0xFF4E7CF4),
          onTap: () => onChanged(_AgendaFilter.eventos),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? tint.withValues(alpha: isDark ? 0.24 : 0.12)
        : (isDark ? const Color(0xFF171D27) : const Color(0xFFF5F1E8));
    final border = selected
        ? tint.withValues(alpha: isDark ? 0.42 : 0.28)
        : (isDark ? const Color(0xFF2A3140) : const Color(0xFFE7DECF));
    final textColor = selected
        ? tint
        : (isDark ? const Color(0xFFD9E0EA) : const Color(0xFF5B6472));

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171D27) : const Color(0xFFF5F1E8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3140) : const Color(0xFFE7DECF),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, size: 18),
            SizedBox(width: 8),
            Text(
              'Calendario',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayNoteCard extends StatefulWidget {
  const _DayNoteCard({
    required this.fecha,
    required this.notaInicial,
    required this.isSaving,
    required this.onSave,
  });

  final String fecha;
  final String notaInicial;
  final bool isSaving;
  final Future<void> Function(String nota) onSave;

  @override
  State<_DayNoteCard> createState() => _DayNoteCardState();
}

class _DayNoteCardState extends State<_DayNoteCard> {
  late final TextEditingController _controller;
  Timer? _autosaveTimer;
  String _ultimaNotaGuardada = '';
  bool _guardandoInterno = false;
  late bool _expandida;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notaInicial);
    _ultimaNotaGuardada = widget.notaInicial.trim();
    _expandida = false;
    _controller.addListener(_programarAutosave);
  }

  @override
  void didUpdateWidget(covariant _DayNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fecha != widget.fecha ||
        oldWidget.notaInicial != widget.notaInicial) {
      _autosaveTimer?.cancel();
      _controller.text = widget.notaInicial;
      _ultimaNotaGuardada = widget.notaInicial.trim();
      _expandida = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _controller.removeListener(_programarAutosave);
    _controller.dispose();
    super.dispose();
  }

  void _programarAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(
      const Duration(milliseconds: 850),
      _guardarSiHaceFalta,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _guardarSiHaceFalta() async {
    _autosaveTimer?.cancel();
    final notaActual = _controller.text.trim();
    if (notaActual == _ultimaNotaGuardada ||
        _guardandoInterno ||
        widget.isSaving) {
      return;
    }

    setState(() {
      _guardandoInterno = true;
    });

    try {
      await widget.onSave(notaActual);
      _ultimaNotaGuardada = notaActual;
    } finally {
      if (mounted) {
        setState(() {
          _guardandoInterno = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = Theme.of(context).colorScheme;
    final hayCambios = _controller.text.trim() != _ultimaNotaGuardada;
    final estaGuardando = widget.isSaving || _guardandoInterno;
    final notaActual = _controller.text.trim();
    final resumen = notaActual.isEmpty
        ? 'Añadir recordatorio'
        : notaActual;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF141922), Color(0xFF10141B)]
                : const [Color(0xFFFFFBF5), Color(0xFFF5EFE4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _expandida = !_expandida;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF212836)
                            : const Color(0xFFFFF1D2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: isDark
                            ? const Color(0xFFE1E8F5)
                            : const Color(0xFF8B6B2F),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nota rápida',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            estaGuardando
                                ? 'Guardando...'
                                : hayCambios
                                    ? 'Pendiente de guardar'
                                    : resumen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF98A2B3)
                                  : const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (estaGuardando)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2.2,
                        ),
                      )
                    else if (!hayCambios && notaActual.isNotEmpty)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF96E2B4)
                            : const Color(0xFF2FB36B),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      _expandida
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? const Color(0xFF98A2B3)
                          : const Color(0xFF667085),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _expandida
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 2,
                        minLines: 2,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _guardarSiHaceFalta(),
                        decoration: InputDecoration(
                          hintText:
                              'Ej: comprar regalo, llamar a X, llevar documentos...',
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1C2230)
                              : const Color(0xFFFFFEFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2D3644)
                                  : const Color(0xFFE6DDCC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2D3644)
                                  : const Color(0xFFE6DDCC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: palette.primary,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: (!hayCambios || estaGuardando)
                                ? null
                                : () async {
                                    FocusScope.of(context).unfocus();
                                    await _guardarSiHaceFalta();
                                  },
                            icon: estaGuardando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(hayCambios ? 'Guardar' : 'Guardado'),
                          ),
                          OutlinedButton.icon(
                            onPressed: estaGuardando
                                ? null
                                : () async {
                                    _controller.clear();
                                    await _guardarSiHaceFalta();
                                  },
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Limpiar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
