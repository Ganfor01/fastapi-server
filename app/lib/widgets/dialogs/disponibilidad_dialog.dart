import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DisponibilidadData {
  const DisponibilidadData({
    required this.diasSeleccionados,
    required this.inicioMinutos,
    required this.finMinutos,
  });

  final List<int> diasSeleccionados;
  final int inicioMinutos;
  final int finMinutos;
}

class DisponibilidadDialog extends StatefulWidget {
  const DisponibilidadDialog({super.key});

  @override
  State<DisponibilidadDialog> createState() => _DisponibilidadDialogState();
}

class _DisponibilidadDialogState extends State<DisponibilidadDialog> {
  final Set<int> _dias = {0, 1, 2, 3, 4};
  int _inicio = 18 * 60;
  int _fin = 21 * 60;
  String? _error;

  static const _diasTexto = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _diasLargos = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String _hora(int minutos) {
    final hora = (minutos ~/ 60).toString().padLeft(2, '0');
    final min = (minutos % 60).toString().padLeft(2, '0');
    return '$hora:$min';
  }

  List<int> _horasDisponibles() {
    return List<int>.generate(37, (index) => (6 * 60) + (index * 30));
  }

  List<int> _horasFinDisponibles() {
    return _horasDisponibles().where((item) => item > _inicio).toList();
  }

  String _resumenDias() {
    final dias = _dias.toList()..sort();
    if (_sameDays(dias, const [0, 1, 2, 3, 4])) {
      return 'Lunes a viernes';
    }
    if (_sameDays(dias, const [5, 6])) {
      return 'Fin de semana';
    }
    if (dias.isEmpty) {
      return 'Sin días seleccionados';
    }
    return dias.map((dia) => _diasLargos[dia]).join(', ');
  }

  bool _sameDays(List<int> actual, List<int> expected) {
    if (actual.length != expected.length) {
      return false;
    }
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horasInicio = _horasDisponibles();
    final horasFin = _horasFinDisponibles();
    final inicioActual = horasInicio.contains(_inicio)
        ? _inicio
        : horasInicio.first;
    final finActual = horasFin.contains(_fin) ? _fin : horasFin.first;

    return AlertDialog(
      title: const Text('Disponibilidad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marca los días y la franja en la que quieres que la app coloque hábitos.',
              style: TextStyle(height: 1.4, color: palette.subtitleColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171D27)
                    : const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A3341)
                      : const Color(0xFFE1E8F5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF9EBBFF)
                            : const Color(0xFF4461D8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Días disponibles',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca los días en los que quieres que la app te proponga bloques.',
                    style: TextStyle(color: palette.subtitleColor, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final selected = _dias.contains(index);
                      return FilterChip(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        label: SizedBox(
                          width: 42,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _diasTexto[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? (isDark
                                          ? const Color(0xFFB9CCFF)
                                          : const Color(0xFF1D4ED8))
                                      : palette.titleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _diasLargos[index].substring(0, 3),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? (isDark
                                          ? const Color(0xFFB9CCFF)
                                          : const Color(0xFF1D4ED8))
                                      : palette.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: isDark
                            ? const Color(0xFF24324A)
                            : const Color(0xFFEAF1FF),
                        backgroundColor: isDark
                            ? const Color(0xFF11161F)
                            : Colors.white,
                        side: BorderSide(
                          color: selected
                              ? (isDark
                                  ? const Color(0xFF536C97)
                                  : const Color(0xFF9BB5F4))
                              : (isDark
                                  ? const Color(0xFF2A3341)
                                  : const Color(0xFFE1E7F2)),
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _dias.add(index);
                            } else {
                              _dias.remove(index);
                            }
                            _error = null;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1A17)
                    : const Color(0xFFFFFCF7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3A3127)
                      : const Color(0xFFF0E6D3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFFE6BD74)
                            : const Color(0xFFB7791F),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Horario habitual',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige la franja en la que sueles tener hueco libre.',
                    style: TextStyle(color: palette.subtitleColor, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('inicio-$inicioActual'),
                          initialValue: inicioActual,
                          decoration: const InputDecoration(labelText: 'Desde'),
                          items: horasInicio
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(_hora(item)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _inicio = value;
                                if (_fin <= _inicio) {
                                  _fin = _horasFinDisponibles().first;
                                }
                                _error = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('fin-$inicioActual-$finActual'),
                          initialValue: finActual,
                          decoration: const InputDecoration(labelText: 'Hasta'),
                          items: horasFin
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(_hora(item)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _fin = value;
                                _error = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF11151D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Así quedará tu disponibilidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resumenDias(),
                    style: const TextStyle(
                      color: Color(0xFFDDE6F5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_hora(_inicio)} - ${_hora(_fin)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFD64545),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_dias.isEmpty) {
              setState(() {
                _error = 'Selecciona al menos un día';
              });
              return;
            }
            if (_fin <= _inicio) {
              setState(() {
                _error = 'La hora de fin debe ser posterior';
              });
              return;
            }
            Navigator.of(context).pop(
              DisponibilidadData(
                diasSeleccionados: _dias.toList()..sort(),
                inicioMinutos: _inicio,
                finMinutos: _fin,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
