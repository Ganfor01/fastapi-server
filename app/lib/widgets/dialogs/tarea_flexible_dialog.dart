import 'package:flutter/material.dart';

class TareaFlexibleData {
  const TareaFlexibleData({
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
    required this.fechaLimite,
  });

  final String titulo;
  final String detalle;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
  final String fechaLimite;
}

class TareaFlexibleDialog extends StatefulWidget {
  const TareaFlexibleDialog({super.key});

  @override
  State<TareaFlexibleDialog> createState() => _TareaFlexibleDialogState();
}

class _TareaFlexibleDialogState extends State<TareaFlexibleDialog> {
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  String? _error;
  int _prioridad = 3;
  int _duracion = 60;
  int _sesiones = 3;
  DateTime? _fechaLimite;

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  void _guardar() {
    final titulo = _tituloController.text.trim();
    if (titulo.length < 3) {
      setState(() {
        _error = 'El titulo debe tener al menos 3 caracteres';
      });
      return;
    }
    if (_fechaLimite == null) {
      setState(() {
        _error = 'Elige una fecha limite';
      });
      return;
    }

    Navigator.of(context).pop(
      TareaFlexibleData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        prioridad: _prioridad,
        duracionMinutos: _duracion,
        sesionesPorSemana: _sesiones,
        fechaLimite: _fechaLimite!.toIso8601String().split('T').first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva tarea flexible'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Titulo',
                hintText: 'Ej: Estudiar mates',
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
                hintText: 'Ej: temas 1 al 4',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _prioridad,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: const [1, 2, 3, 4, 5]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item/5'),
                          ),
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _duracion,
                    decoration: const InputDecoration(
                      labelText: 'Min por sesion',
                    ),
                    items: const [30, 45, 60, 90, 120]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _duracion = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _sesiones,
              decoration: const InputDecoration(
                labelText: 'Sesiones a planificar',
              ),
              items: const [1, 2, 3, 4, 5, 6, 7]
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text('$item')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sesiones = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final ahora = DateTime.now();
                final elegida = await showDatePicker(
                  context: context,
                  firstDate: ahora,
                  lastDate: ahora.add(const Duration(days: 365)),
                  initialDate:
                      _fechaLimite ?? ahora.add(const Duration(days: 3)),
                );
                if (elegida != null) {
                  setState(() {
                    _fechaLimite = elegida;
                    _error = null;
                  });
                }
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _fechaLimite == null
                    ? 'Elegir fecha limite'
                    : 'Fecha limite: ${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}',
              ),
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
