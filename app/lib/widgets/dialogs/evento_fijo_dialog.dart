import 'package:flutter/material.dart';

import '../../models/evento_fijo.dart';

class EventoFijoData {
  const EventoFijoData({
    required this.titulo,
    required this.detalle,
    required this.fecha,
    required this.fechaFin,
    required this.inicioMinutos,
    required this.finMinutos,
    required this.prioridad,
    required this.notasPorDia,
  });

  final String titulo;
  final String detalle;
  final String fecha;
  final String fechaFin;
  final int inicioMinutos;
  final int finMinutos;
  final int prioridad;
  final Map<String, String> notasPorDia;
}

class EventoFijoDialog extends StatefulWidget {
  const EventoFijoDialog({super.key, this.eventoInicial});

  final EventoFijo? eventoInicial;

  @override
  State<EventoFijoDialog> createState() => _EventoFijoDialogState();
}

class _EventoFijoDialogState extends State<EventoFijoDialog> {
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  final Map<String, TextEditingController> _notasControllers = {};
  String? _error;
  DateTime? _fecha;
  DateTime? _fechaFin;
  int _inicio = 10 * 60;
  int _fin = 12 * 60;
  int _prioridad = 4;
  bool _todoElDia = false;

  @override
  void initState() {
    super.initState();
    final evento = widget.eventoInicial;
    if (evento != null) {
      _tituloController.text = evento.titulo;
      _detalleController.text = evento.detalle ?? '';
      _fecha = DateTime.tryParse(evento.fecha);
      _fechaFin = DateTime.tryParse(evento.fechaFin);
      _inicio = evento.inicioMinutos;
      _fin = evento.finMinutos;
      _prioridad = evento.prioridad;
      _todoElDia = evento.esTodoElDia;
      for (final entry in evento.notasPorDia.entries) {
        _notasControllers[entry.key] = TextEditingController(text: entry.value);
      }
    }
    _sincronizarNotasControllers();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    for (final controller in _notasControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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

  bool get _esVariosDias {
    if (_fecha == null || _fechaFin == null) {
      return false;
    }
    final inicio = DateTime(_fecha!.year, _fecha!.month, _fecha!.day);
    final fin = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
    return fin.isAfter(inicio);
  }

  List<DateTime> get _diasDelEvento {
    if (_fecha == null) {
      return const <DateTime>[];
    }
    final inicio = DateTime(_fecha!.year, _fecha!.month, _fecha!.day);
    final finBase = _fechaFin ?? _fecha!;
    final fin = DateTime(finBase.year, finBase.month, finBase.day);
    if (fin.isBefore(inicio)) {
      return <DateTime>[inicio];
    }
    final totalDias = fin.difference(inicio).inDays + 1;
    return List<DateTime>.generate(
      totalDias,
      (index) => inicio.add(Duration(days: index)),
    );
  }

  String _isoDate(DateTime fecha) => fecha.toIso8601String().split('T').first;

  String _fechaCorta(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  String _nombreDia(DateTime fecha) {
    const nombres = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return nombres[fecha.weekday - 1];
  }

  void _sincronizarNotasControllers() {
    final fechasActivas = _diasDelEvento.map(_isoDate).toSet();
    final actuales = _notasControllers.keys.toList();

    for (final fecha in actuales) {
      if (!fechasActivas.contains(fecha)) {
        _notasControllers.remove(fecha)?.dispose();
      }
    }

    for (final fecha in fechasActivas) {
      _notasControllers.putIfAbsent(fecha, () => TextEditingController());
    }
  }

  void _guardar() {
    FocusScope.of(context).unfocus();

    final titulo = _tituloController.text.trim();
    if (titulo.length < 3) {
      setState(() {
        _error = 'El título debe tener al menos 3 caracteres';
      });
      return;
    }

    if (_fecha == null) {
      setState(() {
        _error = 'Elige una fecha para el evento';
      });
      return;
    }

    final fechaFin = _fechaFin ?? _fecha;
    if (fechaFin == null) {
      setState(() {
        _error = 'Elige una fecha de fin para el evento';
      });
      return;
    }

    final inicioDia = DateTime(_fecha!.year, _fecha!.month, _fecha!.day);
    final finDia = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    if (finDia.isBefore(inicioDia)) {
      setState(() {
        _error = 'La fecha de fin no puede ser anterior';
      });
      return;
    }

    Navigator.of(context).pop(
      EventoFijoData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        fecha: _fecha!.toIso8601String().split('T').first,
        fechaFin: fechaFin.toIso8601String().split('T').first,
        inicioMinutos: _esVariosDias || _todoElDia ? 0 : _inicio,
        finMinutos: _esVariosDias || _todoElDia ? 1440 : _fin,
        prioridad: _prioridad,
        notasPorDia: {
          for (final entry in _notasControllers.entries)
            if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim(),
        },
      ),
    );
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
      title: Text(
        widget.eventoInicial == null ? 'Nuevo evento' : 'Editar evento',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Examen de mates',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Detalle',
                hintText: 'Ej: Aula 2, reunión con el equipo...',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final ahora = DateTime.now();
                final elegida = await showDatePicker(
                  context: context,
                  firstDate: ahora,
                  lastDate: ahora.add(const Duration(days: 365)),
                  initialDate: _fecha ?? ahora.add(const Duration(days: 1)),
                );
                if (elegida != null) {
                  setState(() {
                    _fecha = elegida;
                    _fechaFin ??= elegida;
                    if (_fechaFin!.isBefore(_fecha!)) {
                      _fechaFin = _fecha;
                    }
                    _sincronizarNotasControllers();
                    _error = null;
                  });
                }
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _fecha == null
                    ? 'Comienzo'
                    : 'Comienzo: ${_fecha!.day}/${_fecha!.month}/${_fecha!.year}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final base = _fecha ?? DateTime.now().add(const Duration(days: 1));
                final elegida = await showDatePicker(
                  context: context,
                  firstDate: base,
                  lastDate: base.add(const Duration(days: 365)),
                  initialDate: _fechaFin ?? base,
                );
                if (elegida != null) {
                  setState(() {
                    _fechaFin = elegida;
                    _sincronizarNotasControllers();
                    _error = null;
                  });
                }
              },
              icon: const Icon(Icons.flight_land_rounded),
              label: Text(
                _fechaFin == null
                    ? 'Fin'
                    : 'Fin: ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}',
              ),
            ),
            const SizedBox(height: 12),
            if (!_esVariosDias)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _todoElDia,
              title: const Text('Todo el día'),
              subtitle: const Text(
                'Reserva el día entero para bodas, viajes o planes cerrados.',
              ),
              onChanged: (value) {
                setState(() {
                  _todoElDia = value;
                });
              },
            ),
            if (_esVariosDias)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                'Los eventos de varios días reservan todo el rango completo.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF5F6778),
                  ),
                ),
              )
            else if (!_todoElDia)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('evento-inicio-$inicioActual'),
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
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('evento-fin-$inicioActual-$finActual'),
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
                          });
                        }
                      },
                    ),
                  ),
                ],
              )
            else
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ese día quedará bloqueado completo y no se pondrán hábitos ahí.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF5F6778),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_esVariosDias) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF161B24)
                      : const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas por día',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Puedes dejarte un recordatorio distinto para cada día del evento.',
                      style: TextStyle(height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    ..._diasDelEvento.map((dia) {
                      final fechaIso = _isoDate(dia);
                      final controller = _notasControllers.putIfAbsent(
                        fechaIso,
                        () => TextEditingController(),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: '${_nombreDia(dia)} ${_fechaCorta(dia)}',
                            hintText: 'Ej: reunión con dirección, demo, llamada...',
                          ),
                          maxLength: 160,
                          minLines: 1,
                          maxLines: 2,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<int>(
              initialValue: _prioridad,
              decoration: const InputDecoration(labelText: 'Prioridad'),
              items: const [1, 2, 3, 4, 5]
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text('$item/5')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _prioridad = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}


