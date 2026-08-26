import 'dart:async';

/// Cubit-shaped state holder without flutter_bloc.
abstract class StateHolder<T> {
  StateHolder(this._state);

  T _state;
  bool _closed = false;
  final _controller = StreamController<T>.broadcast();

  T get state => _state;
  bool get isClosed => _closed;
  Stream<T> get stream => _controller.stream;

  void emit(T value) {
    if (_closed) return;
    _state = value;
    _controller.add(value);
  }

  Future<void> close() async {
    _closed = true;
    await _controller.close();
  }
}
