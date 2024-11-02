import 'package:flutter/material.dart';
import 'package:virtualine/set_object.dart';

class LeftConstructor extends StatefulWidget {
  final ValueNotifier<List<ImageWidgetInfo>> imageWidgetsInfo;
  final Function(int index)? onDelete;

  const LeftConstructor({
    super.key,
    required this.imageWidgetsInfo,
    this.onDelete,
  });

  @override
  // ignore: library_private_types_in_public_api
  _LeftConstructorState createState() => _LeftConstructorState();
}

class _LeftConstructorState extends State<LeftConstructor> {
  final Map<int, bool> _expandedItems = {};
  final Map<int, TextEditingController> xControllers = {};
  final Map<int, TextEditingController> yControllers = {};
  final Map<int, TextEditingController> nameControllers = {};
  final Map<int, TextEditingController> hpControllers = {};
  final Map<int, TextEditingController> damageControllers = {};
  final Map<int, TextEditingController> movementSpeedControllers = {};
  final GameDataManager _dataManager = GameDataManager();

  @override
  void initState() {
    super.initState();
    _dataManager.initialize().then((_) {
      setState(() {
        widget.imageWidgetsInfo.value.clear();
        widget.imageWidgetsInfo.value.addAll(_dataManager.imagesState.value);
      });
    });
  }

  @override
  void dispose() {
    xControllers.forEach((_, controller) => controller.dispose());
    yControllers.forEach((_, controller) => controller.dispose());
    nameControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  bool isExpanded(int index) => _expandedItems[index] ?? false;

  TextEditingController _getController(
    Map<int, TextEditingController> controllers,
    int index,
    String initialValue,
  ) {
    return controllers.putIfAbsent(
      index,
      () => TextEditingController(text: initialValue),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.purple),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

Widget _buildItemCard(ImageWidgetInfo info, int index) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: Colors.grey[900],
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ExpansionTile(
        initiallyExpanded: isExpanded(index),
        backgroundColor: Colors.grey[900],
        collapsedBackgroundColor: Colors.grey[950],
        onExpansionChanged: (expanded) {
          setState(() => _expandedItems[index] = expanded);
        },
        title: Text(
          info.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete, 
                color: Colors.red, 
                size: 22,
              ),
              tooltip: 'Supprimer',
              onPressed: () => _handleDelete(index),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isExpanded(index) ? Icons.expand_less : Icons.expand_more,
                key: ValueKey(isExpanded(index)),
                color: Colors.white70,
              ),
            ),
          ],
        ),
        children: [
          _buildDetailContent(info, index),
        ],
      ),
    ),
  );
}

Widget _buildDetailContent(ImageWidgetInfo info, int index) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Nom',
          controller: _getController(nameControllers, index, info.name),
          onChanged: (value) => _updateName(info, value),
        ),
        const SizedBox(height: 12),
        _buildCoordinateFields(info, index),
        const SizedBox(height: 12),
        _buildSwitchRow(
          label: 'Collision',
          value: info.collision,
          onChanged: (value) => _updateCollision(info, value),
        ),
        _buildSwitchRow(
          label: 'Fin',
          value: info.finished,
          onChanged: (value) => _updateFinished(info, value),
        ),
        const SizedBox(height: 12),
        _buildEnemySection(info, index),
      ],
    ),
  );
}

Widget _buildCoordinateFields(ImageWidgetInfo info, int index) {
  return Row(
    children: [
      Expanded(
        child: _buildTextField(
          label: 'Position X',
          controller: _getController(
            xControllers, 
            index, 
            info.x.toStringAsFixed(2)
          ),
          onChanged: (value) => _updateXPosition(info, value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildTextField(
          label: 'Position Y',
          controller: _getController(
            yControllers, 
            index, 
            info.y.toStringAsFixed(2)
          ),
          onChanged: (value) => _updateYPosition(info, value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ),
    ],
  );
}

Widget _buildSwitchRow({
  required String label, 
  required bool value, 
  required ValueChanged<bool> onChanged,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 15),
      ),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.purple.shade300,
        activeTrackColor: Colors.purple.shade100,
      ),
    ],
  );
}

Widget _buildEnemySection(ImageWidgetInfo info, int index) {
  return Column(
    children: [
      DropdownButtonFormField<bool>(
        value: info.isEnemy,
        decoration: const InputDecoration(
          labelText: 'Type',
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
        ),
        dropdownColor: Colors.grey[900],
        items: const [
          DropdownMenuItem(
            value: true,
            child: Text(
              'Ennemi', 
              style: TextStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Text(
              'Objet', 
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        onChanged: (value) => _updateEnemyStatus(info, value),
      ),
      if (info.isEnemy) ...[
        const SizedBox(height: 12),
        _buildEnemyDetails(info, index),
      ],
    ],
  );
}

Widget _buildEnemyDetails(ImageWidgetInfo info, int index) {
  return Column(
    children: [
      _buildTextField(
        label: 'HP Max',
        controller: _getController(
          hpControllers,
          index,
          info.enemyHPManager?.maxHP.toString() ?? '100',
        ),
        onChanged: (value) => _updateMaxHP(info, value),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        label: 'Dommage',
        controller: _getController(
          damageControllers,
          index,
          info.damage.toStringAsFixed(1),
        ),
        onChanged: (value) => _updateDamage(info, value),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        label: 'Vitesse de déplacement',
        controller: _getController(
          movementSpeedControllers,
          index,
          info.movementSpeed.toStringAsFixed(1),
        ),
        onChanged: (value) => _updateMovementSpeed(info, value),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ],
  );
}

// Méthodes privées pour gérer les mises à jour
void _handleDelete(int index) {
  if (index < widget.imageWidgetsInfo.value.length) {
    final imageToDelete = widget.imageWidgetsInfo.value[index];
    _dataManager.removeImage(imageToDelete.name);
    widget.onDelete?.call(index);
  }
}

void _updateName(ImageWidgetInfo info, String value) {
  setState(() {
    info.name = value;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateXPosition(ImageWidgetInfo info, String value) {
  setState(() {
    info.x = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateYPosition(ImageWidgetInfo info, String value) {
  setState(() {
    info.y = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateCollision(ImageWidgetInfo info, bool value) {
  setState(() {
    info.collision = value;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateFinished(ImageWidgetInfo info, bool value) {
  setState(() {
    info.finished = value;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateEnemyStatus(ImageWidgetInfo info, bool? value) {
  setState(() {
    info.isEnemy = value ?? false;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateMaxHP(ImageWidgetInfo info, String value) {
  setState(() {
    info.enemyHPManager?.maxHP = int.tryParse(value) ?? 100;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateDamage(ImageWidgetInfo info, String value) {
  setState(() {
    info.damage = double.tryParse(value) ?? 0.0;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}

void _updateMovementSpeed(ImageWidgetInfo info, String value) {
  setState(() {
    info.movementSpeed = double.tryParse(value) ?? 1.0;
    _dataManager.saveImages(widget.imageWidgetsInfo.value);
  });
}


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[850],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
            ),
            child: const Row(
              children: [
                Icon(Icons.list, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Liste des objets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.imageWidgetsInfo.value.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) => _buildItemCard(
                widget.imageWidgetsInfo.value[index],
                index,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
