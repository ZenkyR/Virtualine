import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:virtualine/search_directory.dart';
import 'package:virtualine/set_stats.dart';

class SoundPage extends StatefulWidget {
  const SoundPage({super.key});

  @override
  State<SoundPage> createState() => _SoundPageState();
}

class _SoundPageState extends State<SoundPage> {
  late AudioPlayer player;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player.audioCache = AudioCache(prefix: '/');
    player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: PlayerWidget(player: player),
    );
  }
}

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;

  const PlayerWidget({
    required this.player,
    super.key,
  });

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  TextEditingController pathController = TextEditingController();
  TextEditingController projectNameController = TextEditingController();

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;
  String get _durationText => _duration?.toString().split('.').first ?? '';
  String get _positionText => _position?.toString().split('.').first ?? '';
  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _playerState = player.state;
    player.getDuration().then((value) => setState(() => _duration = value));
    player.getCurrentPosition().then((value) => setState(() => _position = value));
    _initStreams();
    loadPathProject(pathController, __listDirectories);
    loadProjectName(projectNameController);
    projectPathSound.addListener(_handleProjectPathSoundChange);
  }

  void _handleProjectPathSoundChange() async {
    await _stop();
    await _play();
  }

  void __listDirectories(String pathString) {}

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Card(
          color: Colors.grey[850],
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSoundInfo(),
                const SizedBox(height: 24),
                _buildControls(),
                const SizedBox(height: 24),
                _buildProgressBar(),
                const SizedBox(height: 16),
                _buildTimeDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: Colors.purple.shade300,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              projectPathSound.value.isEmpty ? 'Aucun son sélectionné' : projectPathSound.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.play_arrow,
          onPressed: _isPlaying ? null : _play,
          tooltip: 'Lecture',
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          icon: Icons.pause,
          onPressed: _isPlaying ? _pause : null,
          tooltip: 'Pause',
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          icon: Icons.stop,
          onPressed: _isPlaying || _isPaused ? _stop : null,
          tooltip: 'Stop',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(onPressed == null ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        iconSize: 48.0,
        color: onPressed == null ? Colors.grey : Colors.purple.shade300,
        tooltip: tooltip,
        splashColor: Colors.purple.withOpacity(0.3),
        hoverColor: Colors.purple.withOpacity(0.1),
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: Colors.purple.shade300,
        inactiveTrackColor: Colors.grey[700],
        thumbColor: Colors.purple.shade300,
        overlayColor: Colors.purple.withOpacity(0.2),
      ),
      child: Slider(
        onChanged: _duration == null
            ? null
            : (value) {
                final position = value * _duration!.inMilliseconds;
                player.seek(Duration(milliseconds: position.round()));
              },
        value: (_position != null &&
                _duration != null &&
                _position!.inMilliseconds > 0 &&
                _position!.inMilliseconds < _duration!.inMilliseconds)
            ? _position!.inMilliseconds / _duration!.inMilliseconds
            : 0.0,
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return Text(
      _position != null
          ? '$_positionText / $_durationText'
          : _duration != null
              ? _durationText
              : '',
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen(
      (duration) => setState(() => _duration = duration),
    );

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen(
      (event) => setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      }),
    );

    _playerStateChangeSubscription = player.onPlayerStateChanged.listen(
      (state) => setState(() => _playerState = state),
    );
  }

  Future<void> _play() async {
    if (projectPathSound.value.isNotEmpty) {
      final path = '${pathController.text}/${projectNameController.text}${projectPathSound.value}';
      await player.play(AssetSource(path));
      setState(() => _playerState = PlayerState.playing);
    }
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future<void> _stop() async {
    await player.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
    });
  }
}