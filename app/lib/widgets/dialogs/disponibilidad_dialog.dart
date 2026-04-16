import 'package:flutter/material.dart';

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

  String _hora(int minutos) {
    final hora = (minutos ~/ 60).toString().padLeft(2, '0');
    final min = (minutos % 60).toString().padLeft(2, '0');
    return '$hora:$min';
  }

  List<int> _horasDisponibles() {
    return List<int>.generate(28, (index) => (6 * 60) + (index * 30));
  }

  List<int> _horasFinDisponibles() {
    return _horasDisponibles().where((item) => item > _inicio).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text('Selecciona los dias que quieres usar para planificar.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                7,
                (index) => FilterChip(
                  label: Text(_diasTexto[index]),
                  selected: _dias.contains(index),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _dias.add(index);
                      } else {
                        _dias.remove(index);
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
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
                _error = 'Selecciona al menos un dia';
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
