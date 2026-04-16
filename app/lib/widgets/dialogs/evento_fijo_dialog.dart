import 'package:flutter/material.dart';

import '../../models/evento_fijo.dart';

class EventoFijoData {
  const EventoFijoData({
    required this.titulo,
    required this.detalle,
    required this.fecha,
    required this.inicioMinutos,
    required this.finMinutos,
    required this.prioridad,
  });

  final String titulo;
  final String detalle;
  final String fecha;
  final int inicioMinutos;
  final int finMinutos;
  final int prioridad;
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
  String? _error;
  DateTime? _fecha;
  int _inicio = 10 * 60;
  int _fin = 12 * 60;
  int _prioridad = 4;

  @override
  void initState() {
    super.initState();
    final evento = widget.eventoInicial;
    if (evento != null) {
      _tituloController.text = evento.titulo;
      _detalleController.text = evento.detalle ?? '';
      _fecha = DateTime.tryParse(evento.fecha);
      _inicio = evento.inicioMinutos;
      _fin = evento.finMinutos;
      _prioridad = evento.prioridad;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  String _hora(int minutos) {
    final hora = (minutos ~/ 60).toString().padLeft(2, '0');
    final min = (minutos % 60).toString().padLeft(2, '0');
    return '$hora:$min';
  }

  List<int> _horasDisponibles() {
    return List<int>.generate(32, (index) => (6 * 60) + (index * 30));
  }

  List<int> _horasFinDisponibles() {
    return _horasDisponibles().where((item) => item > _inicio).toList();
  }

  void _guardar() {
    FocusScope.of(context).unfocus();

    final titulo = _tituloController.text.trim();
    if (titulo.length < 3) {
      setState(() {
        _error = 'El titulo debe tener al menos 3 caracteres';
      });
      return;
    }

    if (_fecha == null) {
      setState(() {
        _error = 'Elige una fecha para el evento';
      });
      return;
    }

    Navigator.of(context).pop(
      EventoFijoData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        fecha: _fecha!.toIso8601String().split('T').first,
        inicioMinutos: _inicio,
        finMinutos: _fin,
        prioridad: _prioridad,
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
        widget.eventoInicial == null
            ? 'Nuevo evento fijo'
            : 'Editar evento fijo',
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
                labelText: 'Titulo',
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
                hintText: 'Ej: Aula 2, reunion con el equipo...',
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
                    _error = null;
                  });
                }
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _fecha == null
                    ? 'Elegir fecha'
                    : 'Fecha: ${_fecha!.day}/${_fecha!.month}/${_fecha!.year}',
              ),
            ),
            const SizedBox(height: 12),
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
            ),
            const SizedBox(height: 12),
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
