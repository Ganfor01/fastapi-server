import 'package:flutter/material.dart';

class HabitoData {
  const HabitoData({
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
  });

  final String titulo;
  final String detalle;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
}

class HabitoDialog extends StatefulWidget {
  const HabitoDialog({super.key});

  @override
  State<HabitoDialog> createState() => _HabitoDialogState();
}

class _HabitoDialogState extends State<HabitoDialog> {
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  String? _error;
  int _prioridad = 3;
  int _duracion = 60;
  int _sesiones = 3;

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
        _error = 'El título debe tener al menos 3 caracteres';
      });
      return;
    }

    Navigator.of(context).pop(
      HabitoData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        prioridad: _prioridad,
        duracionMinutos: _duracion,
        sesionesPorSemana: _sesiones,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo hábito'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Entrenar',
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
                hintText: 'Ej: fuerza o correr',
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
                    decoration: const InputDecoration(labelText: 'Duración'),
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
              decoration: const InputDecoration(labelText: 'Días por semana'),
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
